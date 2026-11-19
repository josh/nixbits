if [ -d "$HOME/.local/state/nix/profiles/profile/share/zsh/site-functions" ]; then
  FPATH="$HOME/.local/state/nix/profiles/profile/share/zsh/site-functions:$FPATH"
elif [ -d "$HOME/.local/state/nix/profile/share/zsh/site-functions" ]; then
  FPATH="$HOME/.local/state/nix/profile/share/zsh/site-functions:$FPATH"
elif [ -d "$HOME/.nix-profile/share/zsh/site-functions" ]; then
  FPATH="$HOME/.nix-profile/share/zsh/site-functions:$FPATH"
else
  echo "WARN: $HOME/.local/state/nix/profiles/profile/share/zsh/site-functions not found" >&2
fi

zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zcompdump="$zcompdump_dir/zcompdump-$ZSH_VERSION-${${fpath[1]:A}:h:h:h:t}"
mkdir -p "$zcompdump_dir"
if [[ ! -f "$zcompdump" ]]; then
  rm -f "$zcompdump_dir"/zcompdump-*(N)
fi
autoload -Uz compinit
compinit -d "$zcompdump"
