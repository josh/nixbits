{ runCommand, wlibEvalPackage }:
let
  neovim = wlibEvalPackage [
    ../../neovim.nix
    { nixLsp.enable = true; }
  ];
in
runCommand "test-neovim-nix-lsp" { nativeBuildInputs = [ neovim ]; } ''
  export HOME="$PWD" TERM=xterm-256color
  mkdir -p project/.git
  cd project
  echo '{answer=42;}' > example.nix
  nvim --headless -i NONE example.nix \
    -c 'lua assert(vim.wait(15000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "nil_ls" }) > 0 end), "nil_ls did not attach")' \
    -c 'lua vim.lsp.buf.format({ name = "nil_ls", timeout_ms = 15000 })' \
    -c 'wq'
  echo '{ answer = 42; }' > expected
  cmp expected example.nix
  touch "$out"
''
