#!/bin/sh
# SaRCAsm's --as protocol is one executable followed by input.s and -o output.o.
# Only its already-transformed assembly reaches this conventional assembler.
set -eu
exec "$FILC_ASSEMBLER" -cc1as -triple "$FILC_ASSEMBLER_TARGET" -filetype obj "$@"
