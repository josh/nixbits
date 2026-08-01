{
  lib,
  symlinkJoin,
  # keep-sorted start
  cargo,
  clippy,
  rust-analyzer,
  rustc,
  rustfmt,
  # keep-sorted end
}:
symlinkJoin {
  name = "rust-dev-path";
  paths = [
    # keep-sorted start
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt
    # keep-sorted end
  ];
  meta = {
    description = "Bundle of Rust development tools";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
