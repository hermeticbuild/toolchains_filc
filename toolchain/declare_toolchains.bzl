"""Bind execution installations and register the isolated Fil-C matrix."""

load("@toolchains_filc//runtime:filc_runtime.bzl", "filc_runtime")
load("//toolchain/args:resource_directory_args.bzl", "resource_directory_args")
load(":cc_toolchain.bzl", "filc_cc_toolchain")

def declare_toolchains():
    """Bind fixed execution installations separately from target bundle labels."""

    # Target aliases select a complete matched libc/CPU stack independently
    # from the execution compiler. Reject unspecified or unsupported libcs.
    for arch in ["x86_64", "aarch64"]:
        filc_runtime(
            name = "runtime_" + arch,
            loader = "@toolchains_filc//target:dynamic_loader",
            libraries = "@toolchains_filc//target:runtime_dsos",
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
    for exec_arch, compiler in {
        "x86_64": Label("@filc_exec_x86_64//:compiler"),
        "aarch64": Label("@filc_exec_aarch64//:compiler"),
    }.items():
        # Bind resources to the same fixed installation as the execution tool
        # map. These arguments are target-configured; selecting by target CPU
        # here would choose the wrong executable helpers when cross compiling.
        resource_directory_args(
            name = "linux_" + exec_arch + "_resource_directory_args",
            builtin_resources = compiler.same_package_label("builtin_resources"),
            helper_resources = compiler.same_package_label("helper_resources"),
        )
        filc_cc_toolchain(
            name = "linux_" + exec_arch + "_cc",
            tool_map = "@toolchains_filc//toolchain/tools:linux_" + exec_arch + "_tools",
            resource_args = "linux_" + exec_arch + "_resource_directory_args",
        )
        for target_arch in ["x86_64", "aarch64"]:
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
