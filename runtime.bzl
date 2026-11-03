"""Target-side Fil-C dynamic runtime, independent of compiler execution CPU."""

def _runtime_impl(ctx):
    return [platform_common.ToolchainInfo(
        loader = ctx.file.loader,
        libraries = depset(ctx.files.libraries),
    )]

filc_runtime = rule(
    implementation = _runtime_impl,
    attrs = {
        "loader": attr.label(allow_single_file = True, mandatory = True),
        "libraries": attr.label(allow_files = True, mandatory = True),
    },
)
