#include <stdio.h>
#include <string.h>
#include <unistd.h>

static const char *version = "@version@";

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s <program>\n", argv[0]);
    return 1;
  }

  if (strcmp(argv[1], "-V") == 0 || strcmp(argv[1], "--version") == 0) {
    printf("%s\n", version);
    return 0;
  }

  if (getppid() != 1) {
    fprintf(stderr, "error: must be a child of launchd\n");
    return 1;
  }

  execv(argv[1], &argv[1]);
  perror("execv failed");
  return 1;
}
