"""Target-side Fil-C dynamic runtime, independent of compiler execution CPU."""

def _runtime_impl(ctx):
    return [platform_common.ToolchainInfo(
        loader = ctx.file.loader,
        libraries = depset(ctx.files.libraries),
        licenses = depset(ctx.files.licenses),
    )]

filc_runtime = rule(
    implementation = _runtime_impl,
    doc = """Provides a target loader, runtime libraries, and redistribution notices.

Used by the registered Fil-C runtime toolchains. Custom runtime toolchains must
provide a loader and libraries matching the selected target CPU and libc.
""",
    attrs = {
        "loader": attr.label(allow_single_file = True, mandatory = True, doc = "Target ELF dynamic loader."),
        "libraries": attr.label(allow_files = True, mandatory = True, doc = "Target runtime shared libraries."),
        "licenses": attr.label(allow_files = True, mandatory = True, doc = "Upstream notices to include in runtime bundles."),
    },
)
