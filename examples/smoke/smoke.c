#include "answer.h"
#include <linux/openat2.h>
#include <stdio.h>
#include <string.h>
#include <sys/utsname.h>

#ifndef __FILC__
#error This application requires Fil-C.
#endif

int main(void) {
    struct utsname host;
    if (uname(&host)) return 1;
#if defined(__aarch64__)
    if (strcmp(host.machine, "aarch64")) return 2;
#elif defined(__x86_64__)
    if (strcmp(host.machine, "x86_64")) return 2;
#else
#error Unsupported Fil-C target.
#endif
    struct open_how how = {0};
    if (how.flags != 0 || answer() != 42) return 3;
    puts("Fil-C C library and Linux headers: OK");
    return 0;
}
