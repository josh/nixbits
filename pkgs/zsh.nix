{ zsh }:
zsh.overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests = { };
  };
})
