{
  lib,
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  grok-build,
  opencode,
  pi-coding-agent,
  # keep-sorted end
}:
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    codex
    grok-build
    opencode
    pi-coding-agent
    # keep-sorted end
  ];
  postBuild = ''
    rm $out/bin/agent
    ln -s ${lib.getExe grok-build} $out/bin/grok-agent
  '';
  meta = {
    description = "Bundle of AI command-line utilities";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
