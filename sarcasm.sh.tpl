#!/bin/sh
# The upstream script and minilute interpreter paths are installation-relative.
set -eu
root="${0%/*}/.."
# Required aliases from this release's recursive ELF closure on both CPUs.
# Fail on an incomplete bundle before the loader can consult its RUNPATH.
for library in ld-fil1-{arch}.so libc++.so.1 libc++abi.so.1 libc.so libpizlo.so libyoloc.so; do
    if ! test -r "$root/lib/$library"; then
        echo "Fil-C helper: missing bundled library $library" >&2
        exit 1
    fi
done
exec "$root/lib/ld-fil1-{arch}.so" --library-path "$root/lib" "$root/bin/minilute" "$root/bin/sarcasm.luau" --as "${FILC_ASSEMBLER_SHIM:-$root/bin/unsupported-as}" "$@"
