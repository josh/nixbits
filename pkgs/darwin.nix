{
  lib,
  runCommandLocal,
}:
let
  # Fork of <https://github.com/NixOS/nixpkgs/blob/5f1d105/pkgs/os-specific/darwin/impure-cmds/default.nix>
  mkDarwinImpureDrv =
    {
      command,
      hash,
      manpage,
    }:
    let
      binpath = command;
      manpath = "/usr/share/man/man${mansection}/${manpage}";
      name = builtins.baseNameOf command;
      mansection = builtins.head (builtins.match ".+([0-9])$" manpage);
    in
    runCommandLocal "${name}-impure-darwin"
      {
        __impureHostDeps = [
          binpath
          manpath
        ];
        allowedReferences = [ ];
        allowedRequisites = [ ];

        outputHash = hash;
        outputHashAlgo = "sha256";
        outputHashMode = "nar";

        meta = {
          description = "macOS system '${name}'";
          mainProgram = name;
          platforms = lib.platforms.darwin;
        };
      }
      ''
        if ! [ -x ${binpath} ]; then
          echo Cannot find command ${binpath}
          exit 1
        fi

        mkdir -p $out/bin $out/share/man/man${mansection}
        ln -s "${binpath}" "$out/bin/${name}"
        ln -s "${manpath}" "$out/share/man/man${mansection}/${manpage}"
      '';
in
{
  recurseForDerivations = true;

  brctl = mkDarwinImpureDrv {
    command = "/usr/bin/brctl";
    hash = "sha256-d5wtaZ570M7nUABLLxt390Y8ID6+n08TZBHVDqVUUkM=";
    manpage = "brctl.1";
  };
  fdesetup = mkDarwinImpureDrv {
    command = "/usr/bin/fdesetup";
    hash = "sha256-J2dTbqOlCeVFHnVV9Zl8n8w7uC8dn3fDa0yPc4KEXrQ=";
    manpage = "fdesetup.8";
  };
  launchctl = mkDarwinImpureDrv {
    command = "/bin/launchctl";
    hash = "sha256-mS4CMi/fjOBtHPi3KDVSslJDuisiw8zWNRbswfMVpXw=";
    manpage = "launchctl.1";
  };
  open = mkDarwinImpureDrv {
    command = "/usr/bin/open";
    hash = "sha256-v+s2BjGCTz1Kx6yY464NlpdYqGO0YuATIAJdd9WT3bs=";
    manpage = "open.1";
  };
  osascript = mkDarwinImpureDrv {
    command = "/usr/bin/osascript";
    hash = "sha256-Fsoik9dbcymYGpsjVYdtwuitzMgptIKRJVQQYl+Mb+4=";
    manpage = "osascript.1";
  };
  osacompile = mkDarwinImpureDrv {
    command = "/usr/bin/osacompile";
    hash = "sha256-YbrCroTRaJHuTq8loLRGiLrPwshvGInKbLaF/HJnHx0=";
    manpage = "osacompile.1";
  };
  security = mkDarwinImpureDrv {
    command = "/usr/bin/security";
    hash = "sha256-HEad7NFCDbj37e13hi1WEAlpMvYE1c4gtTm1fJa8H90=";
    manpage = "security.1";
  };
  sh = mkDarwinImpureDrv {
    command = "/bin/sh";
    hash = "sha256-F/UrD7LSusULVjWqq2WCaAP2JdPf+A8Jp/FPIWWlY3I=";
    manpage = "sh.1";
  };
  tccutil = mkDarwinImpureDrv {
    command = "/usr/bin/tccutil";
    hash = "sha256-N0v0YyAxl2jfZwi8uTnpMTURMluLL5/WHaDv8d7Wnik=";
    manpage = "tccutil.1";
  };
  wait4path = mkDarwinImpureDrv {
    command = "/bin/wait4path";
    hash = "sha256-UumV34CAR80Vy99ugn9zF3HsVUl8mc5cSMqqPaGcC+E=";
    manpage = "wait4path.1";
  };
}
