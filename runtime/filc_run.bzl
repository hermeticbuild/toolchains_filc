"""Package a dynamic Fil-C executable with its target runtime and launcher."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("//runtime/private:deployment.bzl", "RUNTIME_TOOLCHAIN", "RUN_ATTRS", "run_impl")

filc_run = rule(
    implementation = run_impl,
    doc = """Packages a dynamic Fil-C executable with its target loader and libraries.

The output includes an executable launcher and a sibling `.bundle` directory.
Keep them together when deploying. Run on Linux with the target CPU; remote
compilation does not change where `bazel run` executes the resulting program.
""",
    attrs = RUN_ATTRS,
    executable = True,
    fragments = ["cpp"],
    toolchains = [RUNTIME_TOOLCHAIN] + use_cc_toolchain(),
)
