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
        file_okay=False,
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
def main(
    checks_path: Path,
    hc_api_url: str,
    hc_api_key: str,
    delete: bool,
) -> None:
    logging.basicConfig(level=logging.INFO)

    code = 0

    if hc_api_key.startswith("file:"):
        hc_api_key = Path(hc_api_key[5:]).read_text()
    elif hc_api_key.startswith("command:"):
        hc_api_key = subprocess.check_output(
            hc_api_key[7:].split(),
            shell=True,
            encoding="utf-8",
        ).strip()

    local_checks: dict[str, Check] = {}
    for path in checks_path.glob("*.json"):
        check = json.load(open(path, mode="r"))
        assert check["slug"]
        assert check["slug"] not in local_checks
        local_checks[check["slug"]] = check

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
                )
                if not ok:
                    code = 1
            else:
                logger.warning(f"{slug} does not exist in local config")

    exit(code)


def _hc_list_check(
    api_url: str,
    api_key: str,
) -> list[Check]:
    url = urljoin(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    logger.debug(f"GET {url}")
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()["checks"]


def _hc_create_check(
    api_url: str,
    api_key: str,
    check: Check,
) -> bool:
    url = urljoin(api_url, "api/v3/checks/")
    headers = {"X-Api-Key": api_key}
    slug = check["slug"]
    logger.info(f"POST {url}")
    try:
        response = requests.post(url, headers=headers, json=check)
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
) -> bool:
    url = urljoin(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    slug = check["slug"]
    logger.info(f"POST {url}")
    try:
        response = requests.post(url, headers=headers, json=check)
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
) -> bool:
    url = urljoin(api_url, f"api/v3/checks/{uuid}")
    headers = {"X-Api-Key": api_key}
    logger.info(f"DELETE {url}")
    try:
        response = requests.delete(url, headers=headers)
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Error deleting '{slug}' check: {str(e)}")
        return False


if __name__ == "__main__":
    main(prog_name="healthchecks-apply")
