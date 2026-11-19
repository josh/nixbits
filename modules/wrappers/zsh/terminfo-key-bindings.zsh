() {
  local n binding name capability
  typeset -g -A key
  for n in {1..20}; do
    [[ -n "${terminfo[kf$n]}" ]] && key[F$n]="${terminfo[kf$n]}"
  done
  for binding in Backspace:kbs Insert:kich1 Delete:kdch1 Home:khome End:kend PageUp:kpp PageDown:knp Up:kcuu1 Left:kcub1 Down:kcud1 Right:kcuf1; do
    name=${binding%%:*}
    capability=${binding#*:}
    [[ -n "${terminfo[$capability]}" ]] && key[$name]="${terminfo[$capability]}"
  done

  [[ -n "${key[Delete]}" ]] && bindkey "${key[Delete]}" delete-char
  [[ -n "${key[Home]}" ]] && bindkey "${key[Home]}" beginning-of-line
  [[ -n "${key[End]}" ]] && bindkey "${key[End]}" end-of-line
  [[ -n "${key[Up]}" ]] && bindkey "${key[Up]}" up-line-or-search
  [[ -n "${key[Down]}" ]] && bindkey "${key[Down]}" down-line-or-search
  return 0
}
