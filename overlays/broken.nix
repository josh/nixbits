_final: prev:
let
  inherit (prev) lib;
  inherit (prev.stdenv.hostPlatform) system;

  isRelease2511 = lib.trivial.release == "25.11";
  isUnstable = lib.trivial.release == "26.05";

  markBroken =
    drv:
    drv.overrideAttrs (
      {
        meta ? { },
        ...
      }:
      {
        meta = meta // {
          broken = true;
        };
      }
    );
in
if isRelease2511 && system == "x86_64-linux" then
  {
    # nix run nixpkgs#hydra-check -- swift --channel nixos/release-25.11 --arch x86_64-linux
    swift = markBroken prev.swift;
    # nix run nixpkgs#hydra-check -- age-plugin-se --channel nixos/release-25.11 --arch x86_64-linux
    age-plugin-se = markBroken prev.age-plugin-se;
  }
else if isRelease2511 && system == "aarch64-linux" then
  {
    # nix run nixpkgs#hydra-check -- swift --channel nixos/release-25.11 --arch aarch64-linux
    swift = markBroken prev.swift;
    # nix run nixpkgs#hydra-check -- age-plugin-se --channel nixos/release-25.11 --arch aarch64-linux
    age-plugin-se = markBroken prev.age-plugin-se;
  }
else if isRelease2511 && system == "aarch64-darwin" then
  {
  }
else if isUnstable && system == "x86_64-linux" then
  {
  }
else if isUnstable && system == "aarch64-linux" then
  {
    # nix run nixpkgs#hydra-check -- swift --channel nixpkgs/unstable --arch aarch64-linux
    swift = markBroken prev.swift;
    # nix run nixpkgs#hydra-check -- age-plugin-se --channel nixpkgs/unstable --arch aarch64-linux
    age-plugin-se = markBroken prev.age-plugin-se;
  }
else if isUnstable && system == "aarch64-darwin" then
  {
  }
else
  {
  }
