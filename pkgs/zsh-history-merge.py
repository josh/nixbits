import io
import re
import sys
from pathlib import Path
from typing import Iterable, Iterator


def _read_zsh_history_lines(histfile: Path) -> Iterator[bytes]:
    with histfile.open("rb") as f:
        buf: bytes | None = None
        lineno: int = 0

        for line in f:
            lineno += 1
            if line.startswith(b": "):
                if buf is not None:
                    sys.stderr.write(f"warn: skip bad entry {histfile}:{lineno - 1}")
                    sys.stderr.buffer.write(buf)
                    sys.stderr.write("\n")
                buf = line
            else:
                assert buf
                assert buf.startswith(b": ")
                assert buf.endswith(b"\\\n")
                buf += line

            if line.endswith(b"\\\n"):
                continue

            assert buf.startswith(b": ")
            assert not buf.endswith(b"\\\n")
            yield buf
            buf = None

        assert buf is None


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


def _read_fish_history_lines(histfile: Path) -> Iterator[bytes]:
    with histfile.open("rb") as f:
        for entry in _iter_fish_history_entries(f):
            if parsed_entry := _parse_fish_history_entry(entry):
                cmd, when = parsed_entry
                cmd = cmd.replace("\\\\", "\\").replace("\\n", "\\\n")
                yield f": {when}:0;{cmd}\n".encode("utf-8")


def _merge_history_files(histfiles: Iterable[Path]) -> list[bytes]:
    lines: set[bytes] = set()
    for histfile in histfiles:
        if (
            histfile.name == ".zsh_history"
            or histfile.suffix == ".history"
            or histfile.suffix == ".zsh-history"
            or histfile.suffix == ".zsh_history"
        ):
            lines.update(_read_zsh_history_lines(histfile))
        elif (
            histfile.name == "fish_history"
            or histfile.suffix == ".fish-history"
            or histfile.suffix == ".fish_history"
        ):
            lines.update(_read_fish_history_lines(histfile))
        else:
            print(f"WARN: unknown history file format: {histfile}", file=sys.stderr)
    return sorted(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: zsh-history-merge <file1> <file2> ...")
    for line in _merge_history_files(Path(fn) for fn in sys.argv[1:]):
        sys.stdout.buffer.write(line)
