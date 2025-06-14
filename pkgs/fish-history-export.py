import io
import re
import sys
from pathlib import Path
from typing import Iterator


def _iter_fish_history_entries(f: io.BufferedReader) -> Iterator[bytes]:
    buf = b""
    for line in f:
        if line.startswith(b"- cmd:"):
            if buf:
                yield buf
            buf = line
        elif buf:
            buf += line
    if buf:
        yield buf


def _parse_fish_history_entry(entry_data: bytes) -> tuple[str, int] | None:
    try:
        entry_text = entry_data.decode("utf-8")
    except UnicodeDecodeError:
        sys.stderr.write("warn: could not decode history entry\n")
        sys.stderr.buffer.write(entry_data)
        sys.stderr.write("\n")
        return None

    match = re.match(
        r"^- cmd: (?P<cmd>[^\n]+)\n  when: (?P<when>\d+)",
        entry_text,
        re.DOTALL,
    )
    if not match:
        sys.stderr.write("warn: invalid history entry\n")
        sys.stderr.buffer.write(entry_data)
        sys.stderr.write("\n")
        return None

    cmd = match.group("cmd")
    when = int(match.group("when"))
    return cmd, when


def _export_fish_history(path: Path) -> Iterator[str]:
    with path.open("rb") as f:
        for entry in _iter_fish_history_entries(f):
            if parsed_entry := _parse_fish_history_entry(entry):
                cmd, when = parsed_entry
                cmd = cmd.replace("\\\\", "\\").replace("\\n", "\\\n")
                yield f": {when}:0;{cmd}\n"


if __name__ == "__main__":
    if len(sys.argv) == 2:
        path = Path(sys.argv[1])
    elif len(sys.argv) == 1:
        path = Path.home() / ".local" / "share" / "fish" / "fish_history"
    else:
        sys.exit("usage: fish-history-export [fish_history]")

    for line in _export_fish_history(path):
        sys.stdout.write(line)
