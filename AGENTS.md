# Agents Guide

## Setup

If `nix` is not installed, use the Determinate Systems installer:

```sh
$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
$ . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Ensure flake inputs are downloaded before running in an offline sandbox:

```sh
$ nix flake archive
$ nix flake archive ./internal/
```

## Testing

```sh
$ nix flake check --accept-flake-config --show-trace --print-build-logs --keep-going
```

These flags will give you the most verbose output for debugging. When running in an offline sandox, you should append `--offline`.

This full check can take quite a while. If your change doesn't impact the entire repository, try building only the specific package you're working on instead, using verbose flags:

```sh
$ nix build --accept-flake-config --show-trace --print-build-logs .#yourPackageName
```

## Formatting

`nix flake check` will also check if source files are formatted correctly. If there is a formatting issue, run `nix fmt` to fix it.

## Packages

Packages defined under `pkgs/` are automatically exposed in the flake's package set.
