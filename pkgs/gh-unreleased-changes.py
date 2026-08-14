import json
import subprocess
import sys
from datetime import UTC, datetime
from typing import Any

import click
import tomllib
from github import Auth, Github
from github.GithubException import GithubException
from github.Repository import Repository

GH = "@gh@"

REPOS_QUERY = """
query ($cursor: String) {
  viewer {
    repositories(
      first: 100
      after: $cursor
      isFork: false
      isArchived: false
      privacy: PUBLIC
      ownerAffiliations: [OWNER]
    ) {
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        nameWithOwner
        primaryLanguage {
          name
        }
        defaultBranchRef {
          name
        }
        tags: refs(
          refPrefix: "refs/tags/"
          first: 1
          orderBy: { field: TAG_COMMIT_DATE, direction: DESC }
        ) {
          nodes {
            name
            target {
              ... on Commit {
                committedDate
              }
              ... on Tag {
                target {
                  ... on Commit {
                    committedDate
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
"""

SKIP = "skip"
DEPS = "deps"
SOURCE = "source"
MANIFEST = "manifest"

TIER_RANK = {SKIP: 0, DEPS: 1, SOURCE: 2}

SKIP_PREFIXES = (".devcontainer/", ".github/", ".vscode/", "test/", "tests/")
SKIP_BASENAMES = frozenset(
    {
        ".editorconfig",
        ".gitattributes",
        ".gitignore",
        ".golangci.yml",
        ".pre-commit-config.yaml",
        "Gemfile.lock",
        "package-lock.json",
        "pnpm-lock.yaml",
        "poetry.lock",
        "ruff.toml",
        "treefmt.toml",
        "uv.lock",
        "yarn.lock",
    }
)
SKIP_SUFFIXES = (".md", "Tests.swift", ".test.ts", "_test.go", "_test.py")
DEPS_BASENAMES = frozenset(
    {
        "Cargo.lock",
        "Cargo.toml",
        "Package.resolved",
        "Package.swift",
        "go.mod",
        "go.sum",
    }
)
MANIFEST_BASENAMES = frozenset({"package.json", "pyproject.toml"})


def classify(path: str) -> str:
    """Bucket one changed path by whether it reaches users or only CI."""
    base = path.rsplit("/", 1)[-1]
    if path.startswith(SKIP_PREFIXES):
        return SKIP
    if base in SKIP_BASENAMES or base.endswith(SKIP_SUFFIXES):
        return SKIP
    if base.startswith(("LICENSE", "test_")):
        return SKIP
    if base.startswith("requirements") and base.endswith(".txt"):
        return SKIP
    # Only the root lock reaches consumers; internal/flake.lock is dev-only.
    if base == "flake.lock":
        return DEPS if path == "flake.lock" else SKIP
    if base in MANIFEST_BASENAMES:
        return MANIFEST
    if base in DEPS_BASENAMES:
        return DEPS
    return SOURCE


def _load_manifest(repo: Repository, path: str, ref: str) -> dict[str, Any]:
    contents = repo.get_contents(path, ref=ref)
    raw = contents.decoded_content  # type: ignore[union-attr]
    if path.endswith(".toml"):
        return tomllib.loads(raw.decode())
    return json.loads(raw)


def manifest_tier(repo: Repository, path: str, base: str, head: str) -> str:
    """Manifests mix runtime and build-tool deps, so compare only shipped fields."""
    try:
        old = _load_manifest(repo, path, base)
        new = _load_manifest(repo, path, head)
    except (GithubException, ValueError):
        return DEPS
    if path.endswith(".toml"):
        old, new = old.get("project", {}), new.get("project", {})
        keys = ("version", "dependencies", "optional-dependencies")
    else:
        keys = ("version", "dependencies")
    changed = any(old.get(key) != new.get(key) for key in keys)
    return DEPS if changed else SKIP


def _token() -> str:
    result = subprocess.run(
        [GH, "auth", "token"], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        raise click.ClickException(f"gh auth token failed:\n{result.stderr.strip()}")
    return result.stdout.strip()


def repositories(gh: Github) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    cursor: str | None = None
    while True:
        _, response = gh.requester.graphql_query(REPOS_QUERY, {"cursor": cursor})
        page = response["data"]["viewer"]["repositories"]
        nodes.extend(page["nodes"])
        if not page["pageInfo"]["hasNextPage"]:
            return nodes
        cursor = page["pageInfo"]["endCursor"]


def _tag(node: dict[str, Any]) -> tuple[str, datetime] | None:
    tags = node["tags"]["nodes"]
    if not tags:
        return None
    target = tags[0]["target"]
    # Annotated tags nest the commit one level deeper than lightweight ones.
    committed = target.get("committedDate") or target["target"]["committedDate"]
    return tags[0]["name"], datetime.fromisoformat(committed)


def examine(gh: Github, node: dict[str, Any], tag: str) -> dict[str, Any] | None:
    name = node["nameWithOwner"]
    branch = node["defaultBranchRef"]["name"]
    repo = gh.get_repo(name)
    comparison = repo.compare(tag, branch)
    if comparison.ahead_by == 0:
        return None

    paths = [f.filename for f in comparison.files]
    # The compare API caps files at 300; a truncated list is worth a look anyway.
    if len(paths) >= 300:
        return {"tier": SOURCE, "ahead": comparison.ahead_by, "changes": paths[:3]}

    tiers: dict[str, str] = {}
    for path in paths:
        tier = classify(path)
        if tier == MANIFEST:
            tier = manifest_tier(repo, path, tag, branch)
        tiers[path] = tier

    changes = [path for path, tier in tiers.items() if tier != SKIP]
    if not changes:
        return None
    tier = max((tiers[path] for path in changes), key=lambda t: TIER_RANK[t])
    return {"tier": tier, "ahead": comparison.ahead_by, "changes": changes}


def _describe(changes: list[str]) -> str:
    if len(changes) <= 3:
        return ", ".join(changes)
    return ", ".join(changes[:3]) + f", +{len(changes) - 3} more"


def _table(rows: list[dict[str, Any]]) -> None:
    headers = ("REPO", "LANG", "TAG", "AHEAD", "AGE", "TIER", "CHANGES")
    cells = [
        (
            row["repo"].split("/", 1)[1],
            row["lang"],
            row["tag"],
            str(row["ahead"]),
            f"{row['age']}d",
            row["tier"],
            _describe(row["changes"]),
        )
        for row in rows
    ]
    widths = [max(len(c[i]) for c in [headers, *cells]) for i in range(len(headers))]
    for cell in [headers, *cells]:
        line = "  ".join(
            value.ljust(width) for value, width in zip(cell, widths, strict=True)
        )
        click.echo(line.rstrip())


@click.command()
@click.option("--untagged", is_flag=True, help="Also list repositories with no tags.")
def main(untagged: bool) -> None:
    """List repositories with unreleased changes worth tagging."""
    gh = Github(auth=Auth.Token(_token()))
    nodes = repositories(gh)
    now = datetime.now(UTC)

    rows: list[dict[str, Any]] = []
    never_tagged: list[str] = []
    for node in sorted(nodes, key=lambda n: n["nameWithOwner"]):
        tagged = _tag(node)
        if not tagged:
            never_tagged.append(node["nameWithOwner"])
            continue
        tag, tagged_at = tagged
        try:
            result = examine(gh, node, tag)
        except GithubException as error:
            message = str(error.data.get("message", error) if error.data else error)
            # Disjoint tag and branch histories mean releases are not cut from
            # this branch at all, so there is nothing to report.
            if "No common ancestor" not in message:
                click.echo(f"warning: {node['nameWithOwner']}: {message}", err=True)
            continue
        if not result:
            continue
        language = node["primaryLanguage"]
        rows.append(
            {
                "repo": node["nameWithOwner"],
                "lang": language["name"] if language else "-",
                "tag": tag,
                "age": (now - tagged_at).days,
                "branch": node["defaultBranchRef"]["name"],
                **result,
            }
        )

    rows.sort(key=lambda r: (-TIER_RANK[r["tier"]], -r["ahead"]))

    if sys.stdout.isatty():
        _table(rows)
    else:
        for row in rows:
            base, head = row["tag"], row["branch"]
            click.echo(f"https://github.com/{row['repo']}/compare/{base}...{head}")

    if untagged and never_tagged:
        if sys.stdout.isatty():
            click.echo("\nnever tagged")
        for name in sorted(never_tagged):
            click.echo(name)


if __name__ == "__main__":
    main()
