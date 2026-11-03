# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See LLVM-LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Ported and adapted for Fil-C from LLVM 21.1.8 TokenizeGNUCommandLine:
# https://github.com/llvm/llvm-project/blob/llvmorg-21.1.8/llvm/lib/Support/CommandLine.cpp
# Whitespace, single/double quotes, escapes; empty tokens are discarded.
# Flatten nested response files so the exact CRT RUNPATH rewrite also applies
# when Clang spills a large linker invocation. Never evaluate shell syntax.
function emit(arg, i, c) {
    if (pending) {
        print (arg == ENVIRON["FILC_TARGET_RUNTIME"] ? "-rpath-link" : "-rpath")
        pending = 0
    } else if (arg == "-rpath") {
        pending = 1
        return
    }
    printf "\""
    for (i = 1; i <= length(arg); ++i) {
        c = substr(arg, i, 1)
        if (c == "\\" || c == "\"")
            printf "\\"
        printf "%s", c
    }
    print "\""

}
function argument(arg, depth) {
    if (substr(arg, 1, 1) == "@") {
        response(substr(arg, 2), depth + 1)
    } else {
        emit(arg)
    }
}
function shell_quote(value, result, i, c) {
    result = "'"
    for (i = 1; i <= length(value); ++i) {
        c = substr(value, i, 1)
        result = result (c == "'" ? "'\\''" : c)
    }
    return result "'"
}
function response(path, depth, command, line, count, bytes, i, c, quote, token, escape, status, first) {
    if (depth > 32) {
        print "Fil-C linker: response-file nesting exceeds 32" > "/dev/stderr"
        exit 1
    }
    # od preserves bytes, including a final backslash without a newline. getline
    # alone cannot distinguish terminated and unterminated final records.
    command = "od -An -v -tu1 < " shell_quote(path)
    quote = token = ""
    escape = 0
    first = 1
    while ((command | getline line) > 0) {
        count = split(line, bytes, " ")
        i = first && count >= 3 && bytes[1] == 239 && bytes[2] == 187 && bytes[3] == 191 ? 4 : 1
        first = 0
        for (; i <= count; ++i) {
            if (bytes[i] == 0) {
                print "Fil-C linker: NUL/UTF-16 response files are unsupported" > "/dev/stderr"
                exit 1
            }
            c = sprintf("%c", bytes[i])
            if (escape) {
                token = token c
                escape = 0
            } else if (c == "\\") {
                escape = 1
            } else if (quote != "") {
                if (c == quote)
                    quote = ""
                else
                    token = token c
            } else if (c == "\"" || c == "'") {
                quote = c
            } else if (c ~ /[ \t\r\n]/) {
                if (token != "")
                    argument(token, depth)
                token = ""
            } else {
                token = token c
            }
        }
    }
    status = close(command)
    if (status != 0) {
        print "Fil-C linker: cannot read response file " path > "/dev/stderr"
        exit 1
    }
    if (escape)
        token = token "\\"
    if (token != "")
        argument(token, depth)
}

BEGIN {
    for (n = 1; n < ARGC; ++n)
        argument(ARGV[n], 0)
    if (pending)
        print "-rpath"
    exit
}
