"""Expose the Fil-C toolchain registration package."""

visibility(["//extensions"])

def _filc_toolchains_impl(rctx):
    rctx.file("BUILD.bazel", rctx.read(rctx.attr._build))

filc_toolchains = repository_rule(
    implementation = _filc_toolchains_impl,
    attrs = {
        "_build": attr.label(default = "//prebuilt:toolchains.BUILD.bazel"),
    },
)
