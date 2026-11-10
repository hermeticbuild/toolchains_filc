"""Run a dynamic Fil-C executable with its bundled runtime on the target CPU."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("//runtime/private:deployment.bzl", "RUNTIME_TOOLCHAIN", "RUN_ATTRS", "run_impl")

filc_test = rule(
    implementation = run_impl,
    doc = """Tests a dynamic Fil-C executable with its bundled target runtime.

Uses the registered Fil-C test toolchain to select a Linux test executor with
the target CPU. The wrapped binary must exit zero to pass. Both musl and glibc
targets run with the bundled loader and libraries rather than the host runtime.
""",
    attrs = RUN_ATTRS | {"_test": attr.bool(default = True)},
    test = True,
    exec_groups = {"test": exec_group(toolchains = [Label("//:test_toolchain_type")])},
    fragments = ["cpp"],
    toolchains = [RUNTIME_TOOLCHAIN] + use_cc_toolchain(),
)
