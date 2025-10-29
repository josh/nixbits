import subprocess
import re
from datetime import timedelta, datetime

import click

SYSTEMD_ANALYZE = "@systemd-analyze@"


class TimespanParamType(click.ParamType):
    name = "timespan"

    def convert(self, value, param, ctx) -> timedelta:
        process = subprocess.run(
            [SYSTEMD_ANALYZE, "timespan", str(value)],
            capture_output=True,
        )
        if process.returncode != 0:
            self.fail(f"{value!r} is not a valid timespan", param, ctx)
        out = process.stdout.decode("utf-8")
        m = re.search(r"μs: (\d+)", out)
        if not m:
            self.fail(f"{value!r} is not a valid timespan", param, ctx)
        return timedelta(microseconds=int(m.group(1)))


TIMESPAN = TimespanParamType()


class CalendarParamType(click.ParamType):
    name = "calendar"

    def convert(self, value, param, ctx) -> timedelta:
        process = subprocess.run(
            [SYSTEMD_ANALYZE, "calendar", "--iterations=12", value],
            capture_output=True,
        )
        if process.returncode != 0:
            self.fail(f"{value!r} is not a valid calendar spec", param, ctx)
        events = []
        for line in process.stdout.decode("utf-8").splitlines():
            if m := re.search(r": \w+ (.+) UTC", line):
                events.append(datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S"))
        return max(b - a for a, b in zip(events[:-1], events[1:]))


CALENDAR = CalendarParamType()


@click.command()
@click.option(
    "--timespan",
    type=TIMESPAN,
    help="The timespan to calculate the maximum interval for",
)
@click.option(
    "--calendar",
    type=CALENDAR,
    help="The calendar spec to calculate the maximum interval for",
)
@click.option(
    "--randomized-delay",
    type=TIMESPAN,
    help="The randomized delay to add to the maximum interval",
)
def main(
    timespan: timedelta | None,
    calendar: timedelta | None,
    randomized_delay: timedelta | None,
):
    if timespan:
        if randomized_delay:
            timespan = timespan + randomized_delay
        click.echo(int(timespan.total_seconds()))
    elif calendar:
        if randomized_delay:
            calendar += randomized_delay
        click.echo(int(calendar.total_seconds()))
    else:
        raise click.UsageError("No timespan or calendar specified")


if __name__ == "__main__":
    main(prog_name="systemd-timer-max-interval")
