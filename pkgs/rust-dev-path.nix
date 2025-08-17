{
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
}
