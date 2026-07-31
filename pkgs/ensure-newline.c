#include <errno.h>
#include <unistd.h>

#define BUFFER_SIZE 4096

static int write_all(const char *buf, size_t count) {
  while (count > 0) {
    ssize_t written = write(STDOUT_FILENO, buf, count);
    if (written < 0) {
      if (errno == EINTR) {
        continue;
      }
      return -1;
    }
    buf += written;
    count -= (size_t)written;
  }
  return 0;
}

int main(void) {
  char buffer[BUFFER_SIZE];
  ssize_t bytes_read;
  char last_byte = '\n';

  for (;;) {
    bytes_read = read(STDIN_FILENO, buffer, BUFFER_SIZE);
    if (bytes_read < 0) {
      if (errno == EINTR) {
        continue;
      }
      return 1;
    }
    if (bytes_read == 0) {
      break;
    }
    if (write_all(buffer, (size_t)bytes_read) < 0) {
      return 1;
    }
    last_byte = buffer[bytes_read - 1];
  }

  if (last_byte != '\n') {
    if (write_all("\n", 1) < 0) {
      return 1;
    }
  }

  return 0;
}
