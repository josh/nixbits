#include <stdio.h>
#include <unistd.h>

#define BUFFER_SIZE 4096

int main() {
  char buffer[BUFFER_SIZE];
  ssize_t bytes_read;
  char last_byte = '\0';

  while ((bytes_read = read(STDIN_FILENO, buffer, BUFFER_SIZE)) > 0) {
    if (write(STDOUT_FILENO, buffer, bytes_read) < 0) {
      return 1;
    }
    if (bytes_read > 0) {
      last_byte = buffer[bytes_read - 1];
    }
  }

  if (last_byte != '\n') {
    if (write(STDOUT_FILENO, "\n", 1) < 0) {
      return 1;
    }
  }

  return 0;
}