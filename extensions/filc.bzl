"""Explicit Fil-C registration for matched Linux target stacks."""

load("//prebuilt:releases.bzl", "ARCHIVES", "VERSION")
load("//prebuilt/repositories:filc_distribution.bzl", "filc_distribution")
load("//prebuilt/repositories:filc_toolchains.bzl", "filc_toolchains")
load("//prebuilt/repositories:optfil_distribution.bzl", "optfil_distribution")

def _filc_impl(mctx):
    requests = [t for m in mctx.modules for t in m.tags.prebuilt]
    if len(requests) != 1:
        fail("Fil-C requires exactly one explicit prebuilt(version = ...) request")
    if requests[0].version != VERSION:
        fail("Unsupported Fil-C version {}; pinned version is {}".format(requests[0].version, VERSION))
    for arch in ARCHIVES:
        for role in ["exec", "target"]:
            filc_distribution(name = "filc_{}_{}".format(role, arch), arch = arch)
        optfil_distribution(name = "filc_glibc_target_" + arch, arch = arch)
    filc_toolchains(name = "filc_toolchains")
    for module in mctx.modules:
        if module.is_root and module.name == "toolchains_filc":
            # This module owns the distribution mappings used by its BUILD
            # files; consumers only need the registration repository.
            return mctx.extension_metadata(
                root_module_direct_deps = "all",
                root_module_direct_dev_deps = [],
                reproducible = True,
            )
    return mctx.extension_metadata(
        root_module_direct_deps = ["filc_toolchains"],
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

filc = module_extension(
    implementation = _filc_impl,
    doc = """Declares the pinned Fil-C compiler and matched Linux target distributions.

The consuming root must provide exactly one `prebuilt(version = "0.687")` tag,
import `filc_toolchains`, and register `@filc_toolchains//:all`. The compiler runs
on Linux AMD64 or ARM64; target toolchains support musl and Fil-C glibc 2.44.
""",
    tag_classes = {"prebuilt": tag_class(
        attrs = {"version": attr.string(
            mandatory = True,
            doc = "Fil-C distribution version. This module supports only 0.687.",
        )},
        doc = "Selects the pinned Fil-C distribution; required once across the module graph.",
    )},
)
