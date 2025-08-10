if begin
  status --is-interactive
  and status --is-login
  and test -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
end
  function on_exit --on-event fish_exit
    echo "...syncing history" 1>&2
    @fish-history-sync@/bin/fish-history-sync
  end
end
