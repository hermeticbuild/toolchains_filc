"""Pinned Fil-C execution and musl target distribution."""

load("//prebuilt:releases.bzl", "ARCHIVES", "VERSION")

visibility(["//extensions"])

def _filc_distribution_impl(rctx):
    rctx.download_and_extract(
        url = "https://github.com/pizlonator/fil-c/releases/download/v{0}/filc-{0}-linux-{1}.tar.xz".format(VERSION, rctx.attr.arch),
        sha256 = ARCHIVES[rctx.attr.arch],
        stripPrefix = "filc-{}-linux-{}".format(VERSION, rctx.attr.arch),
    )
    rctx.file("BUILD.bazel", rctx.read(rctx.attr._build).replace("{arch}", rctx.attr.arch))

    # Relocate the helper without setup.sh, patchelf or host header symlinks.
    rctx.file("pizfix/bin/sarcasm.luau", rctx.read("pizfix/bin/sarcasm"), executable = False)
    rctx.template("pizfix/bin/sarcasm", rctx.attr._launcher, substitutions = {"{arch}": rctx.attr.arch})
    rctx.file("pizfix/bin/unsupported-as", rctx.read(rctx.attr._unsupported))

filc_distribution = repository_rule(
    implementation = _filc_distribution_impl,
    attrs = {
        "arch": attr.string(mandatory = True, values = ["x86_64", "aarch64"]),
        "_build": attr.label(default = "//prebuilt:distribution.BUILD.bazel"),
        "_launcher": attr.label(default = "//prebuilt:sarcasm.sh.tpl"),
        "_unsupported": attr.label(default = "//toolchain/tools:unsupported.sh"),
    },
)
