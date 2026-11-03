#!/bin/sh
# Verify deployment closure using the execution-platform ELF inspector.
set -eu
readelf=$1
root=$2
loader=$3
scratch=$(mktemp -d "${TMPDIR:-/tmp}/filc-bundle.XXXXXX")
trap 'rm -rf "$scratch"' 0
trap 'exit 1' 1 2 3 15
"$readelf" -h "$root/bin/app" > "$scratch/header"
"$readelf" -l "$root/bin/app" > "$scratch/program"
interpreter=$(sed -n 's/.*Requesting program interpreter: \([^]]*\)\].*/\1/p' "$scratch/program")
if test "$interpreter" != "/lib/$loader"; then
    echo "Fil-C bundle: expected dynamic executable with /lib/$loader interpreter; got $interpreter" >&2
    exit 1
fi
machine=$(sed -n 's/^ *Machine: *//p' "$scratch/header")
for library in "$root"/lib/*; do
    "$readelf" -h -d "$library" > "$scratch/elf"
    actual=$(sed -n 's/^ *Machine: *//p' "$scratch/elf")
    if test "$actual" != "$machine"; then
        echo "Fil-C bundle: wrong ELF machine in $library ($actual; expected $machine)" >&2
        exit 1
    fi
    soname=$(sed -n 's/.*(SONAME).*\[\([^]]*\)\].*/\1/p' "$scratch/elf")
    if test -n "$soname"; then
        case "$soname" in
            */*|.|..) echo "Fil-C bundle: invalid SONAME $soname" >&2; exit 1 ;;
        esac
        if test -f "$scratch/soname.$soname"; then
            previous=$(cat "$scratch/soname.$soname")
            if ! cmp -s "$previous" "$library"; then
                echo "Fil-C bundle: SONAME collision $soname: $previous and $library" >&2
                exit 1
            fi
        else
            printf '%s\n' "$library" > "$scratch/soname.$soname"
        fi
    fi
done
for elf in "$root/bin/app" "$root"/lib/*; do
    "$readelf" -d "$elf" > "$scratch/elf"
    sed -n 's/.*(NEEDED).*\[\([^]]*\)\].*/\1/p' "$scratch/elf" > "$scratch/needed"
    while IFS= read -r needed; do
        case "$needed" in
            */*) echo "Fil-C bundle: nonrelocatable NEEDED $needed in $elf" >&2; exit 1 ;;
        esac
        if ! test -r "$root/lib/$needed"; then
            echo "Fil-C bundle: missing target library $needed needed by $elf" >&2
            exit 1
        fi
    done < "$scratch/needed"
done
