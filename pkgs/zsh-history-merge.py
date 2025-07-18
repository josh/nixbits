import sys
from pathlib import Path
from typing import Iterable, Iterator


def read_history_lines(histfile: Path) -> Iterator[bytes]:
    with open(histfile, "rb") as f:
        buf: bytes | None = None

        for line in f:
            if line.startswith(b": "):
                assert buf is None
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


def merge_history_files(histfiles: Iterable[Path]) -> list[bytes]:
    lines: set[bytes] = set()
    for histfile in histfiles:
        lines.update(read_history_lines(histfile))
    return sorted(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: zsh-history-merge <file1> <file2> ...")
    for line in merge_history_files(Path(fn) for fn in sys.argv[1:]):
        sys.stdout.buffer.write(line)
