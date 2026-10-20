if ! { true </dev/tty; } 2>/dev/null; then
  exit 1
fi

saved_stty="$(stty -g </dev/tty)"
stty -icanon -echo </dev/tty
printf '\e[?996n' >/dev/tty
reply=""
read -r -s -d n -t 0.5 reply </dev/tty || true
stty "$saved_stty" </dev/tty

case "$reply" in
*'?997;1')
  echo dark
  ;;
*'?997;2')
  echo light
  ;;
*)
  exit 1
  ;;
esac
