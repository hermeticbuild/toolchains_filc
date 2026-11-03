"""Generate matched Fil-C toolchain and target packages."""

visibility(["//extensions"])

def _filc_toolchains_impl(rctx):
    bindings = {}
    substitutions = {}
    for role in ["compilers", "targets", "glibc_targets"]:
        bindings[role] = {arch: label for label, arch in getattr(rctx.attr, role).items()}
        for arch, label in bindings[role].items():
            substitutions["{" + role + "_" + arch + "}"] = str(label)
    rctx.template("BUILD.bazel", rctx.attr._build, substitutions = substitutions)
    target_substitutions = {"{kernel_headers}": str(rctx.attr.kernel_headers)}
    for arch, target in bindings["targets"].items():
        for name in ["c_headers", "stdfil_headers", "cxx_headers", "cxx_config_headers", "runtime", "dynamic_runtime", "dynamic_loader", "runtime_dsos"]:
            target_substitutions["{" + arch + "_" + name + "}"] = str(target.same_package_label(name))
    for arch, target in bindings["glibc_targets"].items():
        for name in ["headers", "runtime", "dynamic_loader", "runtime_dsos"]:
            target_substitutions["{glibc_" + arch + "_" + name + "}"] = str(target.same_package_label(name))
    rctx.template("target/BUILD.bazel", rctx.attr._target, substitutions = target_substitutions)
    rctx.template("toolchain/args/BUILD.bazel", rctx.attr._target_args)
    for arch, compiler in bindings["compilers"].items():
        # Resolve execution resources alongside the fixed tool map, before its
        # exec transition. Target-configured arguments use separate aliases.
        execution_package = "toolchain/" + arch
        rctx.template(execution_package + "/BUILD.bazel", rctx.attr._composition, substitutions = {
            "{execution_args}": "//" + execution_package + "/args",
        })
        rctx.template(execution_package + "/args/BUILD.bazel", rctx.attr._execution_args, substitutions = {
            "{builtin_resources}": str(compiler.same_package_label("builtin_resources")),
            "{helper_resources}": str(compiler.same_package_label("helper_resources")),
        })

filc_toolchains = repository_rule(
    implementation = _filc_toolchains_impl,
    attrs = {
        "_build": attr.label(default = "//prebuilt:toolchains.BUILD.bazel"),
        "_target": attr.label(default = "//prebuilt:target.BUILD.bazel"),
        "_target_args": attr.label(default = "//toolchain/args:target.BUILD.bazel"),
        "_execution_args": attr.label(default = "//toolchain/args:execution.BUILD.bazel"),
        "_composition": attr.label(default = "//toolchain:toolchain.BUILD.bazel"),
        "compilers": attr.label_keyed_string_dict(mandatory = True),
        "targets": attr.label_keyed_string_dict(mandatory = True),
        "glibc_targets": attr.label_keyed_string_dict(mandatory = True),
        "kernel_headers": attr.label(mandatory = True),
    },
)
