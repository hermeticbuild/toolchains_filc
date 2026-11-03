"""Bind execution installations and register the isolated Fil-C matrix."""

load("@toolchains_filc//runtime:filc_runtime.bzl", "filc_runtime")
load(":cc_toolchain.bzl", "filc_cc_toolchain")
load(":tools.bzl", "tools")

def declare_toolchains(compilers, targets):
    """Bind fixed execution installations separately from target bundle labels."""

    # Target aliases select a complete matched libc/CPU stack independently
    # from the execution compiler. Reject unspecified or unsupported libcs.
    for arch in targets:
        filc_runtime(
            name = "runtime_" + arch,
            loader = "//target:dynamic_loader",
            libraries = "//target:runtime_dsos",
            target_compatible_with = [
                "@platforms//os:linux",
                "@platforms//cpu:" + arch,
                "@toolchains_filc//:abi",
            ],
        )
        native.toolchain(
            name = "runtime_toolchain_" + arch,
            toolchain = "runtime_" + arch,
            toolchain_type = "@toolchains_filc//:runtime_toolchain_type",
            target_compatible_with = [
                "@platforms//os:linux",
                "@platforms//cpu:" + arch,
                "@toolchains_filc//:abi",
            ],
            target_settings = ["@toolchains_filc//:supported_libc"],
        )
        native.toolchain(
            name = "test_toolchain_" + arch,
            toolchain = "runtime_" + arch,
            toolchain_type = "@toolchains_filc//:test_toolchain_type",
            exec_compatible_with = [
                "@platforms//os:linux",
                "@platforms//cpu:" + arch,
            ],
            target_compatible_with = [
                "@platforms//os:linux",
                "@platforms//cpu:" + arch,
                "@toolchains_filc//:abi",
            ],
            target_settings = ["@toolchains_filc//:supported_libc"],
        )
    for exec_arch, compiler in compilers.items():
        tools(
            name = "linux_" + exec_arch,
            compiler = compiler,
        )
        filc_cc_toolchain(
            name = "linux_" + exec_arch + "_cc",
            tool_map = "linux_" + exec_arch + "_tools",
            args = "//toolchain/" + exec_arch + ":toolchain_args",
        )
        for target_arch in targets:
            native.toolchain(
                name = "linux_" + exec_arch + "_to_linux_" + target_arch,
                toolchain = "linux_" + exec_arch + "_cc",
                toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
                exec_compatible_with = [
                    "@platforms//os:linux",
                    "@platforms//cpu:" + exec_arch,
                    "@toolchains_filc//:worker",
                ],
                target_compatible_with = [
                    "@platforms//os:linux",
                    "@platforms//cpu:" + target_arch,
                    "@toolchains_filc//:abi",
                ],
                target_settings = ["@toolchains_filc//:supported_libc"],
            )
    native.alias(
        name = "linux_x86_64",
        actual = "linux_x86_64_to_linux_x86_64",
    )
