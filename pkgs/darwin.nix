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
  codesign = mkDarwinImpureDrv {
    command = "/usr/bin/codesign";
    hash = "sha256-NhYIAniF1Bm8x2Pwl1fuRy6hljh5wAun7uJcMhWxfYc=";
    manpage = "codesign.1";
  };
  defaults = mkDarwinImpureDrv {
    command = "/usr/bin/defaults";
    hash = "sha256-LWwmoCoOee7rSItyNAwq7qcDyHnw1kRSG2kFrtf4nNU=";
    manpage = "defaults.1";
  };
  dscl = mkDarwinImpureDrv {
    command = "/usr/bin/dscl";
    hash = "sha256-/sGeGnSk7qysjP/D3zu6s3CYP9k+JvuG5aRnBqMo2lQ=";
    manpage = "dscl.1";
  };
  fdesetup = mkDarwinImpureDrv {
    command = "/usr/bin/fdesetup";
    hash = "sha256-J2dTbqOlCeVFHnVV9Zl8n8w7uC8dn3fDa0yPc4KEXrQ=";
    manpage = "fdesetup.8";
  };
  ifconfig = mkDarwinImpureDrv {
    command = "/sbin/ifconfig";
    hash = "sha256-6NdoRhHic/qf3oQcw9jBkbZpT8wDobOYvU/vGo/mZLA=";
    manpage = "ifconfig.8";
  };
  killall = mkDarwinImpureDrv {
    command = "/usr/bin/killall";
    hash = "sha256-Yq8vC4MYgxTsIBX2sTboQvB8ysu8X+7gOD8A2gwwKng=";
    manpage = "killall.1";
  };
  launchctl = mkDarwinImpureDrv {
    command = "/bin/launchctl";
    hash = "sha256-mS4CMi/fjOBtHPi3KDVSslJDuisiw8zWNRbswfMVpXw=";
    manpage = "launchctl.1";
  };
  lsof = mkDarwinImpureDrv {
    command = "/usr/sbin/lsof";
    hash = "sha256-rwRBYmFAHF0AWITQGx/GtJVITsCB6cNK3TsOFEzX6PY=";
    manpage = "lsof.8";
  };
  open = mkDarwinImpureDrv {
    command = "/usr/bin/open";
    hash = "sha256-v+s2BjGCTz1Kx6yY464NlpdYqGO0YuATIAJdd9WT3bs=";
    manpage = "open.1";
  };
  osacompile = mkDarwinImpureDrv {
    command = "/usr/bin/osacompile";
    hash = "sha256-YbrCroTRaJHuTq8loLRGiLrPwshvGInKbLaF/HJnHx0=";
    manpage = "osacompile.1";
  };
  osascript = mkDarwinImpureDrv {
    command = "/usr/bin/osascript";
    hash = "sha256-Fsoik9dbcymYGpsjVYdtwuitzMgptIKRJVQQYl+Mb+4=";
    manpage = "osascript.1";
  };
  route = mkDarwinImpureDrv {
    command = "/sbin/route";
    hash = "sha256-6o+n0SQWJ0TsOG477BEn9vAPa22JLF+Gmp3CT64EJlQ=";
    manpage = "route.8";
  };
  scutil = mkDarwinImpureDrv {
    command = "/usr/sbin/scutil";
    hash = "sha256-9APm3GmGIJWiYmjz8MdpZrFOQ7Z8YRkEo+nvIJdCZFc=";
    manpage = "scutil.1";
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
  shortcuts = mkDarwinImpureDrv {
    command = "/usr/bin/shortcuts";
    hash = "sha256-HZfyqd/bCCYCfFhpRwHGV7oZxKqU+E+SzBIosiHm6Xc=";
    manpage = "shortcuts.1";
  };
  tmutil = mkDarwinImpureDrv {
    command = "/usr/bin/tmutil";
    hash = "sha256-GWuWMKALte+3aqMMgI60E9nLr7NYRL5YMvIoQg9XPb4=";
    manpage = "tmutil.1";
  };
  wait4path = mkDarwinImpureDrv {
    command = "/bin/wait4path";
    hash = "sha256-UumV34CAR80Vy99ugn9zF3HsVUl8mc5cSMqqPaGcC+E=";
    manpage = "wait4path.1";
  };
  xcrun = mkDarwinImpureDrv {
    command = "/usr/bin/xcrun";
    hash = "sha256-jBG5VvrqmKSt/3qCGD/8W2fsF1OtCltfOZzsBUCipeQ=";
    manpage = "xcrun.1";
  };
}
