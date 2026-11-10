#!/usr/bin/env bash
# Called by bazel-contrib's release workflow; optional ref supports local dry runs.
set -euo pipefail
tag=${1:?usage: release_prep.sh vVERSION [git-ref]}
ref=${2:-$tag}
root=$(cd "$(dirname "$0")/../.." && pwd)
if [[ ! $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
    echo "Expected a v-prefixed release version, got: $tag" >&2
    exit 1
fi
prefix="toolchains_filc-${tag#v}"
archive="toolchains_filc-$tag.tar.gz"
git -C "$root" archive --format=tar --prefix="$prefix/" "$ref" | gzip -n > "$archive"
checksum=$(shasum -a 256 "$archive" | cut -d ' ' -f 1)
integrity="sha256-$(openssl dgst -sha256 -binary "$archive" | openssl base64 -A)"
# Extract API docs from the committed sources shipped in this release.
docs_archive="$PWD/${archive%.tar.gz}.docs.tar.gz"
source_dir=$(mktemp -d "${TMPDIR:-/tmp}/toolchains-filc-docs.XXXXXX")
tar -xzf "$archive" -C "$source_dir"
(
    cd "$source_dir/$prefix"
    trap 'bazel shutdown >/dev/null 2>&1' EXIT
    bash docs/package.sh "$docs_archive" --lockfile_mode=off
)
cat <<EOF
## Bzlmod

After the BCR submission is merged, add:

\`\`\`starlark
bazel_dep(name = "toolchains_filc", version = "${tag#v}")
\`\`\`

See the [setup instructions](https://github.com/hermeticbuild/toolchains_filc/blob/$tag/README.md)
for Fil-C registration and LLVM selection. Requires Bazel 9+ and Linux AMD64 or
ARM64 execution with glibc 2.34+.

Before the BCR submission is merged, also add:

\`\`\`starlark
archive_override(
    module_name = "toolchains_filc",
    integrity = "$integrity",
    strip_prefix = "$prefix",
    urls = ["https://github.com/hermeticbuild/toolchains_filc/releases/download/$tag/$archive"],
)
\`\`\`

Archive SHA-256: \`$checksum\`
EOF
