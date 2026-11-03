"""Explicit, isolated Fil-C registration for matched Linux target stacks."""

load(":releases.bzl", "ARCHIVES", "GLIBC_ARCHIVES", "VERSION")

def _distribution_impl(rctx):
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

_distribution = repository_rule(
    implementation = _distribution_impl,
    attrs = {
        "arch": attr.string(mandatory = True, values = ["x86_64", "aarch64"]),
        "_build": attr.label(default = "//prebuilt:distribution.BUILD.bazel"),
        "_launcher": attr.label(default = "//:sarcasm.sh.tpl"),
        "_unsupported": attr.label(default = "//:unsupported.sh"),
    },
)

def _glibc_distribution_impl(rctx):
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

_glibc_distribution = repository_rule(
    implementation = _glibc_distribution_impl,
    attrs = {
        "arch": attr.string(mandatory = True, values = ["x86_64", "aarch64"]),
        "_build": attr.label(default = "//prebuilt:glibc.BUILD.bazel"),
    },
)

def _toolchains_impl(rctx):
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

_toolchains = repository_rule(
    implementation = _toolchains_impl,
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

def _filc_impl(mctx):
    requests = [t for m in mctx.modules for t in m.tags.prebuilt]
    if len(requests) != 1:
        fail("Fil-C requires exactly one explicit prebuilt(version = ...) request")
    if requests[0].version != VERSION:
        fail("Unsupported Fil-C version {}; pinned version is {}".format(requests[0].version, VERSION))
    for arch in ARCHIVES:
        for role in ["exec", "target"]:
            _distribution(name = "filc_{}_{}".format(role, arch), arch = arch)
        _glibc_distribution(name = "filc_glibc_target_" + arch, arch = arch)
    _toolchains(
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
