#!/bin/sh
# The pinned Fil-C driver injects -rpath <CRT directory> for dynamic links.
# Keep that directory a link-time search path, never an application RUNPATH.
set -eu
response=$(mktemp "${TMPDIR:-/tmp}/filc-link.XXXXXX")
trap 'rm -f "$response"' 0
trap 'exit 1' 1 2 3 15
LC_ALL=C awk -f "$FILC_LINKER_REWRITE" -- "$@" > "$response"
"$FILC_LINKER" "@$response"
