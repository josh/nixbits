set -e
check_environment() {
  [[ ${JJ_CONFIG-unset} == "$expected_jj" ]]
  [[ ${GIT_CONFIG_GLOBAL-unset} == "$expected_git" ]]
}
check_prompt() {
  source ./init.zsh
  check_environment
  : > "$PROBE_LOG"
  print -P -- "$PROMPT" > prompt
  grep -Fq "Review the prompt" prompt
  test -s "$PROBE_LOG"
  check_environment
}
unset JJ_CONFIG GIT_CONFIG_GLOBAL
expected_jj=unset expected_git=unset
check_prompt
export JJ_CONFIG=/caller/jj GIT_CONFIG_GLOBAL=/caller/git
expected_jj=$JJ_CONFIG expected_git=$GIT_CONFIG_GLOBAL
check_prompt
