#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef __FILC__
#error This test requires Fil-C.
#endif

int filc_test_arrayoob(void);
int filc_test_uaf(void);

static int valid_access(void) {
    int *value = malloc(sizeof(*value));
    if (!value) return 1;
    *value = 42;
    int result = *value;
    free(value);
    return result != 42;
}

static int check(const char *name, int (*scenario)(void), const char *diagnostic) {
    int descriptors[2];
    if (pipe(descriptors)) return 1;
    fflush(NULL);
    pid_t child = fork();
    if (child < 0) return 1;
    if (!child) {
        close(descriptors[0]);
        if (dup2(descriptors[1], STDOUT_FILENO) < 0 ||
            dup2(descriptors[1], STDERR_FILENO) < 0) _exit(127);
        close(descriptors[1]);
        int result = scenario();
        fflush(NULL);
        _exit(result);
    }
    close(descriptors[1]);
    char output[65536];
    size_t length = 0;
    for (;;) {
        char buffer[4096];
        ssize_t count = read(descriptors[0], buffer, sizeof(buffer));
        if (count < 0 && errno == EINTR) continue;
        if (count < 0) return 1;
        if (!count) break;
        size_t keep = (size_t)count;
        if (keep > sizeof(output) - length - 1) keep = sizeof(output) - length - 1;
        memcpy(output + length, buffer, keep);
        length += keep;
    }
    output[length] = 0;
    close(descriptors[0]);
    int status;
    while (waitpid(child, &status, 0) < 0) {
        if (errno != EINTR) return 1;
    }
    fprintf(stderr, "%s:\n%s", name, output);
    int succeeded = WIFEXITED(status) && WEXITSTATUS(status) == 0;
    if (!diagnostic) return !succeeded || strstr(output, "filc safety error") != NULL;
    return succeeded || !strstr(output, "filc safety error") ||
           !strstr(output, diagnostic) || !strstr(output, "filc panic:") ||
           (scenario == filc_test_uaf &&
            (!strstr(output, ",free") || strstr(output, "hello")));
}

int main(void) {
    const struct rlimit no_core = {0, 0};
    if (setrlimit(RLIMIT_CORE, &no_core)) return 1;
    if (check("valid access", valid_access, NULL)) return 2;
    if (check("upstream arrayoob", filc_test_arrayoob, "filc safety error")) return 3;
    if (check("upstream uaf", filc_test_uaf, "pointer to free object")) return 4;
    puts("Valid access succeeds; upstream out-of-bounds and use-after-free cases are rejected.");
    return 0;
}
