"""Pinned Optfil glibc target distribution."""

load("//prebuilt:releases.bzl", "GLIBC_ARCHIVES", "VERSION")

visibility(["//extensions"])

def _optfil_distribution_impl(rctx):
    rctx.download_and_extract(
        url = "https://github.com/pizlonator/fil-c/releases/download/v{0}/optfil-{0}-linux-{1}.tar.xz".format(VERSION, rctx.attr.arch),
        sha256 = GLIBC_ARCHIVES[rctx.attr.arch],
        stripPrefix = "optfil-{}-linux-{}".format(VERSION, rctx.attr.arch),
    )

    # Only target headers/libraries are needed. In particular, the unrelated
    # terminfo tree contains case-colliding names on macOS filesystems.
    rctx.extract("fil.tar.xz", output = "fil/include", stripPrefix = "fil/include")

    # Linux UAPI contains distinct case-only names. Fail instead of silently
    # publishing a corrupted tree when the repository filesystem folds case.
    if rctx.read("fil/include/linux/netfilter/xt_DSCP.h") == rctx.read("fil/include/linux/netfilter/xt_dscp.h"):
        fail("Optfil headers require a case-sensitive repository filesystem; use a Linux Bazel host or a case-sensitive output/repository cache directory")
    rctx.extract("fil.tar.xz", output = "fil/lib", stripPrefix = "fil/lib")

    # The installer assumes /opt/fil. Keep the three linker scripts' GROUP and
    # AS_NEEDED semantics; the driver's declared -L path resolves these names.
    # No installer, ELF patching, or executor library discovery is necessary.
    for script in ["libc.so", "libyoloc.so", "libyolom.so"]:
        path = "fil/lib/" + script
        content = rctx.read(path)
        if "/opt/fil/lib/" not in content:
            fail("Optfil linker script layout changed: " + script)
        rctx.file(path, content.replace("/opt/fil/lib/", ""), executable = False)
    rctx.template("BUILD.bazel", rctx.attr._build, substitutions = {"{arch}": rctx.attr.arch})

optfil_distribution = repository_rule(
    implementation = _optfil_distribution_impl,
    attrs = {
        "arch": attr.string(mandatory = True, values = ["x86_64", "aarch64"]),
        "_build": attr.label(default = "//prebuilt:glibc.BUILD.bazel"),
    },
)
