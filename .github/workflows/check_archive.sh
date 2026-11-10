#!/usr/bin/env bash
# Exercise committed release sources without creating a tag or publishing anything.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
scratch=$(mktemp -d "${TMPDIR:-/tmp}/toolchains-filc-release.XXXXXX")
echo "Archive verification: $scratch"
cd "$scratch"
bash "$root/.github/workflows/release_prep.sh" v0.0.0-ci HEAD > release-notes.md
archive=toolchains_filc-v0.0.0-ci.tar.gz
cp "$archive" first.tar.gz
bash "$root/.github/workflows/release_prep.sh" v0.0.0-ci HEAD > repeated-notes.md
cmp first.tar.gz "$archive"
cmp release-notes.md repeated-notes.md
tar -tzf toolchains_filc-v0.0.0-ci.docs.tar.gz | LC_ALL=C sort > actual-docs.txt
printf '%s\n' \
    docs/filc.binaryproto \
    docs/filc_run.binaryproto \
    docs/filc_runtime.binaryproto \
    docs/filc_test.binaryproto > expected-docs.txt
diff -u expected-docs.txt actual-docs.txt
tar -xzf "$archive"
cd toolchains_filc-0.0.0-ci
test -f LICENSE
test -f NOTICE
test -f prebuilt/LICENSING.md
test -f toolchain/tools/LLVM-LICENSE.txt
test -f .bcr/presubmit.yml
test -f .bcr/source.template.json
test -f examples/smoke/MODULE.bazel
test ! -e .github
test ! -e .bazelrc.user
test ! -e MODULE.bazel.lock
test ! -e e2e
test ! -e plans
cd examples/smoke
trap 'bazel --nosystem_rc --nohome_rc shutdown >/dev/null 2>&1' EXIT
bazel --nosystem_rc --nohome_rc test //... --lockfile_mode=off "$@"
