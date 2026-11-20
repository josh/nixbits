{
  git,
  jujutsu,
  runCommand,
  starship,
}:
runCommand "test-starship-jj"
  {
    nativeBuildInputs = [
      git
      jujutsu
      starship
    ];
  }
  ''
    export HOME="$PWD" TERM=xterm-256color
    git init -b plain repo
    cd repo
    [[ "$(starship module vcs)" == *plain* ]]
    jj git init --colocate
    jj describe --message nixbits-starship-test
    change=$(jj log -r @ --no-graph -T 'change_id.short(7)')
    actual=$(starship prompt | sed -E 's/\x1b\[[0-9;]*m//g')
    [[ $actual == *"$change"* ]]
    [[ $actual ${
      if starship.configuration.showJujutsuDescription then "==" else "!="
    } *nixbits-starship-test* ]]
    touch "$out"
  ''
