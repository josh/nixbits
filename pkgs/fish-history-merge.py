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


def _parse_zsh_history_entry(entry_data: bytes) -> tuple[bytes, int] | None:
    match = re.match(
        rb"^: (?P<when>\d+):\d+;(?P<cmd>.*)\n$",
        entry_data,
        re.DOTALL,
    )
    if not match:
        sys.stderr.write("warn: could not decode history entry\n")
        sys.stderr.buffer.write(entry_data)
        sys.stderr.write("\n")
        return None
    when = int(match.group("when"))
    cmd = match.group("cmd").replace(b"\\\n", b"\\n")
    return (cmd, when)


def _read_zsh_history_entries(histfile: Path) -> Iterator[bytes]:
    for line in _read_zsh_history_lines(histfile):
        entry = _parse_zsh_history_entry(line)
        if entry:
            cmd, when = entry
            yield b"- cmd: " + cmd + b"\n  when: " + str(when).encode("utf-8") + b"\n"


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


def _read_fish_history_entries(histfile: Path) -> Iterator[bytes]:
    with histfile.open("rb") as f:
        yield from _iter_fish_history_entries(f)


def _parse_entry_when(entry_text: bytes) -> int:
    match = re.search(rb"when: (?P<when>\d+)", entry_text, re.DOTALL)
    if not match:
        sys.stderr.write("warn: could not decode history entry\n")
        sys.stderr.buffer.write(entry_text)
        sys.stderr.write("\n")
        return -1
    return int(match.group("when"))


def _merge_history_files(histfiles: Iterable[Path]) -> list[bytes]:
    entries: set[bytes] = set()
    for histfile in histfiles:
        if (
            histfile.name == "zsh_history"
            or histfile.name == ".zsh_history"
            or histfile.suffix == ".history"
            or histfile.suffix == ".zsh-history"
            or histfile.suffix == ".zsh_history"
        ):
            entries.update(_read_zsh_history_entries(histfile))
        elif (
            histfile.name == "fish_history"
            or histfile.suffix == ".fish-history"
            or histfile.suffix == ".fish_history"
        ):
            entries.update(_read_fish_history_entries(histfile))
        else:
            print(f"WARN: unknown history file format: {histfile}", file=sys.stderr)
    return sorted(entries, key=_parse_entry_when)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: fish-history-merge <file1> <file2> ...")
    for line in _merge_history_files(Path(fn) for fn in sys.argv[1:]):
        sys.stdout.buffer.write(line)
