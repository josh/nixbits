import json
import subprocess
from collections.abc import Iterable

import click


def _run_nix(args: list[str]) -> str:
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise click.ClickException(f"{' '.join(args)} failed:\n{result.stderr.strip()}")
    return result.stdout


@click.command()
@click.argument("root_flake_uris", nargs=-1, required=True)
def main(root_flake_uris: list[str]) -> None:
    flake_uris: set[str] = set()
    with click.progressbar(root_flake_uris) as uris:
        for uri in uris:
            flake_uris.update(flake_inputs(uri))

    flake_uris = {uri for uri in flake_uris if uri.lower().startswith("github:josh/")}

    drv_path_to_pkg_uri: dict[str, str] = {}
    with click.progressbar(flake_uris) as items:
        for flake_uri in items:
            drv_path_to_pkg_uri.update(flake_package_drv_map(flake_uri))

    all_input_drv_paths = input_derivation_paths(drv_path_to_pkg_uri.keys())

    input_pkgs: dict[str, set[str]] = {}
    for drv_path, input_drv_paths in all_input_drv_paths.items():
        if drv_path not in drv_path_to_pkg_uri:
            continue
        pkg_uri = drv_path_to_pkg_uri[drv_path]
        if pkg_uri not in input_pkgs:
            input_pkgs[pkg_uri] = set()
        for input_drv_path in input_drv_paths:
            if input_drv_path in drv_path_to_pkg_uri:
                input_pkgs[pkg_uri].add(drv_path_to_pkg_uri[input_drv_path])

    dependent_counts: dict[str, int] = {}
    all_packages = set(drv_path_to_pkg_uri.values())

    for pkg in all_packages:
        dependent_counts[pkg] = 0

    for pkg_uri, deps in input_pkgs.items():
        for dep in deps:
            dependent_counts[dep] += 1

    sorted_packages = sorted(dependent_counts.items(), key=lambda x: x[1], reverse=True)
    for pkg, count in sorted_packages:
        print(f"{pkg}: {count}")


def flake_inputs(flake_uri: str) -> set[str]:
    args = ["nix", "flake", "metadata", flake_uri, "--json"]
    metadata = json.loads(_run_nix(args))

    uris = set()

    root = metadata["locked"]
    if root.get("type") != "github":
        raise click.ClickException(
            f"{flake_uri} is a {root.get('type', 'unknown')} flake; "
            "only github flakes are supported"
        )
    uris.add(f"github:{root['owner']}/{root['repo']}/{root['rev']}")

    for node_name, node in metadata["locks"]["nodes"].items():
        if node_name == "root":
            continue
        if node.get("flake") is False:
            continue
        locked = node["locked"]
        if locked.get("type") != "github":
            continue
        owner = locked["owner"]
        repo = locked["repo"]
        rev = locked["rev"]
        uri = f"github:{owner}/{repo}/{rev}"
        uris.add(uri)

    return uris


def flake_package_drv_map(flake_uri: str) -> dict[str, str]:
    unpin_flake_uri: str = "/".join(flake_uri.split("/")[:-1])

    drv_map: dict[str, str] = {}

    nix_expr = f'''
    let
      flake = builtins.getFlake "{flake_uri}";
      hasPackages = builtins.hasAttr "packages" flake;
    in
    if !hasPackages then {{}} else
    builtins.mapAttrs (system: packages:
        builtins.mapAttrs (name: pkg: pkg.drvPath) packages
    ) flake.packages
    '''
    args = ["nix", "eval", "--json", "--expr", nix_expr]

    pkgs_by_system = json.loads(_run_nix(args))
    for pkgs in pkgs_by_system.values():
        for name, drv in pkgs.items():
            drv_map[drv] = f"{unpin_flake_uri}#{name}"

    return drv_map


def input_derivation_paths(drv_paths: Iterable[str]) -> dict[str, set[str]]:
    paths = list(drv_paths)
    input_drvs: dict[str, set[str]] = {}
    chunk_size = 100
    for i in range(0, len(paths), chunk_size):
        chunk = paths[i : i + chunk_size]
        args = ["nix", "derivation", "show", *chunk]
        data = json.loads(_run_nix(args))
        input_drvs.update(
            {
                drv_path: set(drv_data["inputDrvs"])
                for drv_path, drv_data in data.items()
            }
        )
    return input_drvs


if __name__ == "__main__":
    main()
