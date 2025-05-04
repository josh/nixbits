# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "click",
#     "requests",
# ]
# ///

import json
import logging
import subprocess
from pathlib import Path
from typing import TypedDict
from urllib.parse import urljoin

import click
import requests

logger = logging.getLogger("healthchecks")


class Check(TypedDict, total=False):
    uuid: str
    name: str
    slug: str
    tags: list[str]
    desc: str
    timeout: int
    grace: int
    schedule: str
    tz: str


UPDATABLE_FIELDS = [
    "name",
    "tags",
    "desc",
    "timeout",
    "grace",
    "schedule",
    "tz",
]


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
        hc_api_key = Path(hc_api_key[5:]).read_text()
    elif hc_api_key.startswith("command:"):
        hc_api_key = subprocess.check_output(
            hc_api_key[8:].split(),
            shell=True,
            encoding="utf-8",
        ).strip()

    local_checks = _load_checks_config(checks_path)
    remote_checks = {
        check["slug"]: check
        for check in _hc_list_check(api_url=hc_api_url, api_key=hc_api_key)
    }

    for slug, local_check in local_checks.items():
        remote_check = remote_checks.get(slug)
        if not remote_check:
            _hc_create_check(
                api_url=hc_api_url,
                api_key=hc_api_key,
                check=local_check,
                dry_run=dry_run,
            )
            continue

        uuid = remote_check["uuid"]
        assert local_check["slug"] == remote_check["slug"]

        needs_update = False
        for field in UPDATABLE_FIELDS:
            value = local_check.get(field)
            if value and value != remote_check.get(field):
                needs_update = True

        if needs_update:
            _hc_update_check(
                api_url=hc_api_url,
                api_key=hc_api_key,
                uuid=uuid,
                check=local_check,
                dry_run=dry_run,
            )

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

    exit(code)


def _load_checks_config(path: Path) -> dict[str, Check]:
    all_checks: dict[str, Check] = {}

    if path.is_file():
        check_paths = [path]
    else:
        check_paths = [f for f in path.rglob("*") if f.is_file()]

    for file_path in check_paths:
        checks = json.load(file_path.open(mode="r"))
        if not isinstance(checks, list):
            checks = [checks]

        for check in checks:
            assert check["slug"] and check["slug"] not in all_checks
            all_checks[check["slug"]] = check

    return all_checks


def _hc_online(hc_api_url: str) -> bool:
    url = urljoin(hc_api_url, "api/v3/checks/")
    logger.debug(f"GET {url}")
    try:
        requests.get(url, timeout=(5, 10))
        return True
    except Exception as e:
        logger.error(f"Healthchecks instance is offline: {str(e)}")
        return False


def _hc_list_check(
    api_url: str,
    api_key: str,
) -> list[Check]:
    url = urljoin(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    logger.debug(f"GET {url}")
    response = requests.get(url, headers=headers, timeout=(5, 30))
    response.raise_for_status()
    return response.json()["checks"]


def _hc_create_check(
    api_url: str,
    api_key: str,
    check: Check,
    dry_run: bool,
) -> bool:
    slug = check["slug"]
    if not check["name"]:
        check["name"] = check["slug"]
    url = urljoin(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would POST {url}")
        return True

    try:
        logger.info(f"POST {url}")
        response = requests.post(url, headers=headers, json=check, timeout=(5, 30))
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Error creating '{slug}' check: {str(e)}")
        return False


def _hc_update_check(
    api_url: str,
    api_key: str,
    uuid: str,
    check: Check,
    dry_run: bool,
) -> bool:
    slug = check["slug"]
    url = urljoin(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would POST {url}")
        return True

    try:
        logger.info(f"POST {url}")
        response = requests.post(url, headers=headers, json=check, timeout=(5, 30))
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Error updating '{slug}' check: {str(e)}")
        return False


def _hc_delete_check(
    api_url: str,
    api_key: str,
    slug: str,
    uuid: str,
    dry_run: bool,
) -> bool:
    url = urljoin(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    if dry_run:
        logger.info(f"Would DELETE {url}")
        return True

    try:
        logger.info(f"DELETE {url}")
        response = requests.delete(url, headers=headers, timeout=(5, 30))
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Error deleting '{slug}' check: {str(e)}")
        return False


if __name__ == "__main__":
    main(prog_name="healthchecks-apply")
