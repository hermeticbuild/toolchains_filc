"""Explicit Fil-C registration for matched Linux target stacks."""

load("//prebuilt:releases.bzl", "ARCHIVES", "GLIBC_ARCHIVES", "VERSION")
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
    filc_toolchains(
        name = "filc_toolchains",
        compilers = {"@filc_exec_{}//:compiler".format(arch): arch for arch in ARCHIVES},
        targets = {"@filc_target_{}//:c_headers".format(arch): arch for arch in ARCHIVES},
        glibc_targets = {"@filc_glibc_target_{}//:headers".format(arch): arch for arch in GLIBC_ARCHIVES},
        # Resolve the shared repository in this module's mapping. The target
        # honors the target CPU/kernel constraints and the root MODULE default.
        kernel_headers = Label("@kernel_headers//:kernel_headers_directory"),
    )
    return mctx.extension_metadata(root_module_direct_deps = ["filc_toolchains"], root_module_direct_dev_deps = [])

filc = module_extension(
    implementation = _filc_impl,
    tag_classes = {"prebuilt": tag_class(attrs = {"version": attr.string(mandatory = True)})},
)
