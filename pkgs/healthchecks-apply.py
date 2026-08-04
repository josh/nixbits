# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "click",
#     "requests",
# ]
# ///

import json
import logging
import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import TypedDict

import click
import requests
from requests.adapters import HTTPAdapter, Retry

logger = logging.getLogger("healthchecks")

SESSION = requests.Session()
_ADAPTER = HTTPAdapter(
    max_retries=Retry(total=None, connect=5, read=0, status=0, backoff_factor=2)
)
SESSION.mount("https://", _ADAPTER)
SESSION.mount("http://", _ADAPTER)


class Check(TypedDict, total=False):
    uuid: str
    name: str
    slug: str
    tags: str
    desc: str
    timeout: int
    grace: int
    schedule: str
    tz: str


# Fields the check list API returns verbatim as posted; subject, subject_fail,
# unique and channels do not round-trip (see Check.to_dict upstream).
COMPARABLE_FIELDS = [
    "name",
    "slug",
    "tags",
    "desc",
    "timeout",
    "grace",
    "schedule",
    "tz",
    "manual_resume",
    "methods",
    "start_kw",
    "success_kw",
    "failure_kw",
    "filter_subject",
    "filter_body",
    "filter_http_body",
    "filter_default_fail",
]

UUID_RE = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z")


def _channels_need_update(local: str, remote: str) -> bool:
    # The API returns channel UUIDs; "*" and channel names cannot be compared.
    local_items = {item for item in local.split(",") if item}
    if local == "*" or not all(UUID_RE.match(item) for item in local_items):
        return False
    return local_items != {item for item in remote.split(",") if item}


def _needs_update(local_check: Check, remote_check: Check) -> bool:
    for field in COMPARABLE_FIELDS:
        if field in local_check and local_check[field] != remote_check.get(field):
            return True
    if "channels" in local_check:
        return _channels_need_update(
            local_check["channels"], remote_check.get("channels", "")
        )
    return False


@click.command()
@click.argument(
    "checks_path",
    envvar="HC_CHECKS_PATH",
    type=click.Path(
        exists=True,
        file_okay=True,
        dir_okay=True,
        resolve_path=True,
        path_type=Path,
    ),
)
@click.option(
    "--hc-api-url",
    envvar="HC_API_URL",
    required=True,
)
@click.option(
    "--hc-api-key",
    envvar="HC_API_KEY",
    required=True,
)
@click.option(
    "--delete",
    is_flag=True,
    default=False,
)
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Show what would be done without making any actual changes",
)
@click.option(
    "--allow-hc-offline",
    is_flag=True,
    default=False,
    help="Skip if healthchecks instance is offline",
)
def main(
    checks_path: Path,
    hc_api_url: str,
    hc_api_key: str,
    delete: bool,
    dry_run: bool,
    allow_hc_offline: bool,
) -> None:
    logging.basicConfig(level=logging.INFO)

    if allow_hc_offline is True and _hc_online(hc_api_url=hc_api_url) is False:
        return

    code = 0

    if hc_api_key.startswith("file:"):
        hc_api_key = Path(hc_api_key[5:]).read_text().strip()
    elif hc_api_key.startswith("command:"):
        hc_api_key = subprocess.check_output(
            shlex.split(hc_api_key[8:]),
            encoding="utf-8",
        ).strip()

    local_checks = _load_checks_config(checks_path)
    remote_checks: dict[str, Check] = {}
    for check in _hc_list_check(api_url=hc_api_url, api_key=hc_api_key):
        if "uuid" not in check:
            # Read-only API keys return unique_key instead of uuid.
            raise click.ClickException(
                "API key is read-only; a read-write key is required"
            )
        if check["slug"] in remote_checks:
            logger.warning(f"duplicate remote slug {check['slug']}; using first match")
            continue
        remote_checks[check["slug"]] = check

    for slug, local_check in local_checks.items():
        remote_check = remote_checks.get(slug)
        if not remote_check:
            ok = _hc_create_check(
                api_url=hc_api_url,
                api_key=hc_api_key,
                check=local_check,
                dry_run=dry_run,
            )
            if not ok:
                code = 1
            continue

        uuid = remote_check["uuid"]

        if _needs_update(local_check, remote_check):
            ok = _hc_update_check(
                api_url=hc_api_url,
                api_key=hc_api_key,
                uuid=uuid,
                check=local_check,
                dry_run=dry_run,
            )
            if not ok:
                code = 1

    for slug, remote_check in remote_checks.items():
        uuid = remote_check["uuid"]
        if slug not in local_checks:
            if delete:
                ok = _hc_delete_check(
                    api_url=hc_api_url,
                    api_key=hc_api_key,
                    slug=slug,
                    uuid=uuid,
                    dry_run=dry_run,
                )
                if not ok:
                    code = 1
            else:
                logger.warning(f"{slug} does not exist in local config")

    sys.exit(code)


def _load_checks_config(path: Path) -> dict[str, Check]:
    all_checks: dict[str, Check] = {}

    if path.is_file():
        check_paths = [path]
    else:
        check_paths = sorted(f for f in path.rglob("*.json") if f.is_file())

    for file_path in check_paths:
        with file_path.open() as file:
            checks = json.load(file)
        if not isinstance(checks, list):
            checks = [checks]

        for check in checks:
            slug = check.get("slug")
            if not slug:
                raise click.ClickException(f"{file_path}: check is missing a slug")
            if slug in all_checks:
                raise click.ClickException(f"{file_path}: duplicate slug '{slug}'")
            if isinstance(check.get("tags"), list):
                check["tags"] = " ".join(check["tags"])
            all_checks[slug] = check

    return all_checks


def _api_url(api_url: str, path: str) -> str:
    return api_url.rstrip("/") + "/" + path


def _hc_online(hc_api_url: str) -> bool:
    url = _api_url(hc_api_url, "api/v3/checks/")
    logger.debug(f"GET {url}")
    try:
        response = SESSION.get(url, timeout=(5, 10))
    except requests.RequestException as e:
        logger.error(f"Healthchecks instance is offline: {e!s}")
        return False
    # Unauthenticated requests are expected to get a 4xx from a healthy server.
    if response.status_code >= 500:
        logger.error(f"Healthchecks instance is offline: HTTP {response.status_code}")
        return False
    return True


def _hc_list_check(
    api_url: str,
    api_key: str,
) -> list[Check]:
    url = _api_url(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    logger.debug(f"GET {url}")
    try:
        response = SESSION.get(url, headers=headers, timeout=(5, 30))
        response.raise_for_status()
    except requests.RequestException as e:
        raise click.ClickException(f"Error listing checks: {e!s}") from e
    return response.json()["checks"]


def _hc_create_check(
    api_url: str,
    api_key: str,
    check: Check,
    dry_run: bool,
) -> bool:
    slug = check["slug"]
    if not check.get("name"):
        check = {**check, "name": slug}
    url = _api_url(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would POST {url}")
        return True

    try:
        logger.info(f"POST {url}")
        response = SESSION.post(url, headers=headers, json=check, timeout=(5, 30))
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        logger.error(f"Error creating '{slug}' check: {e!s}")
        return False


def _hc_update_check(
    api_url: str,
    api_key: str,
    uuid: str,
    check: Check,
    dry_run: bool,
) -> bool:
    slug = check["slug"]
    url = _api_url(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would POST {url}")
        return True

    try:
        logger.info(f"POST {url}")
        response = SESSION.post(url, headers=headers, json=check, timeout=(5, 30))
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        logger.error(f"Error updating '{slug}' check: {e!s}")
        return False


def _hc_delete_check(
    api_url: str,
    api_key: str,
    slug: str,
    uuid: str,
    dry_run: bool,
) -> bool:
    url = _api_url(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would DELETE {url}")
        return True

    try:
        logger.info(f"DELETE {url}")
        response = SESSION.delete(url, headers=headers, timeout=(5, 30))
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        logger.error(f"Error deleting '{slug}' check: {e!s}")
        return False


if __name__ == "__main__":
    main(prog_name="healthchecks-apply")
