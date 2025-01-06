#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s /nix/store/<hash>-<program>\n", argv[0]);
    return 1;
  }

  execv(argv[1], &argv[1]);
  perror("execv failed");
  return 1;
}
