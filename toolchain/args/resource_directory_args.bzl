"""Compiler resources explicitly bound to an execution installation."""

load("@rules_cc//cc/toolchains:args.bzl", "cc_args")

def resource_directory_args(name, builtin_resources, helper_resources):
    """Declare resource arguments without selecting against the target CPU."""
    cc_args(
        name = name,
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile",
            "@rules_cc//cc/toolchains/actions:linkstamp_compile",
            "@rules_cc//cc/toolchains/actions:assemble",
            "@rules_cc//cc/toolchains/actions:preprocess_assemble",
        ],
        allowlist_include_directories = [builtin_resources],
        args = [
            "--filc-resource-dir={helpers}",
            "-resource-dir={resources}",
        ],
        data = [
            builtin_resources,
            helper_resources,
        ],
        format = {
            "helpers": helper_resources,
            "resources": builtin_resources,
        },
    )
