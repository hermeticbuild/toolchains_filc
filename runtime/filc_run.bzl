"""Package a dynamic Fil-C executable with its target runtime and launcher."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("//runtime/private:deployment.bzl", "RUNTIME_TOOLCHAIN", "RUN_ATTRS", "run_impl")

filc_run = rule(
    implementation = run_impl,
    attrs = RUN_ATTRS,
    executable = True,
    fragments = ["cpp"],
    toolchains = [RUNTIME_TOOLCHAIN] + use_cc_toolchain(),
)
