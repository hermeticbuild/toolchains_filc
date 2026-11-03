"""Remote driver-contract inspection using the selected Fil-C toolchain."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _environment(configuration, action, variables):
    environment = cc_common.get_environment_variables(
        feature_configuration = configuration,
        action_name = action,
        variables = variables,
    )

    # Preserve each resolved action's environment independently. Values become
    # literal env(1) arguments, not shell assignments or interpolated shell code.
    return " ".join(["'" + (key + "=" + value).replace("'", "'\\''") + "'" for key, value in environment.items()])

def _probe_impl(ctx):
    cc = find_cc_toolchain(ctx)
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    object_path = output.path + ".o"
    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc,
        feature_configuration = configuration,
        source_file = ctx.file.src.path,
        output_file = object_path,
        user_compile_flags = ["-Werror"],
    )
    link_variables = cc_common.create_link_variables(
        cc_toolchain = cc,
        feature_configuration = configuration,
        output_file = output.path + ".exe",
        user_link_flags = ["-Werror"],
    )
    parameter_files = []
    executables = []
    environments = []
    for action, variables in [("c-compile", compile_variables), ("c++-link-executable", link_variables)]:
        arguments = ctx.actions.args()
        arguments.add_all(cc_common.get_memory_inefficient_command_line(
            feature_configuration = configuration,
            action_name = action,
            variables = variables,
        ))
        parameters = ctx.actions.declare_file(ctx.label.name + "." + action + ".params")
        ctx.actions.write(parameters, arguments)
        parameter_files.append(parameters)
        executables.append(cc_common.get_tool_for_action(feature_configuration = configuration, action_name = action))
        environments.append(_environment(configuration, action, variables))
    helper = cc_common.get_tool_for_action(feature_configuration = configuration, action_name = "filc-helper-probe")
    helper_environment = _environment(configuration, "filc-helper-probe", compile_variables)
    ctx.actions.run_shell(
        inputs = depset(ctx.files.src + parameter_files, transitive = [cc.all_files]),
        outputs = [output],
        arguments = executables + [output.path] + [f.path for f in parameter_files] + [object_path, helper],
        # Match the matrix runner's explicit action nonce without inheriting the
        # rest of the client's environment.
        env = {"FILC_MATRIX_RUN": ctx.configuration.default_shell_env.get("FILC_MATRIX_RUN", "")},
        # /bin/sh, uname, grep and env come from the pinned execution image.
        command = """set -eu
{
  /usr/bin/uname -m
  /usr/bin/grep -m 1 -E '^(vendor_id|CPU architecture)' /proc/cpuinfo
  /usr/bin/env {compile_env} "$1" --version
  /usr/bin/env {compile_env} "$1" -### @"$4"
  # Materialize the configured C object so the link probe needs no compile flags.
  /usr/bin/env {compile_env} "$1" @"$4"
  /usr/bin/env {link_env} "$2" -### @"$5" "$6"
  /usr/bin/env {helper_env} "$7" --help
} > "$3" 2>&1
""".replace("{compile_env}", environments[0]).replace("{link_env}", environments[1]).replace("{helper_env}", helper_environment),
        mnemonic = "FilCDriverProbe",
        toolchain = "@bazel_tools//tools/cpp:toolchain_type",
    )
    return [DefaultInfo(files = depset([output]))]

filc_driver_probe = rule(
    implementation = _probe_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
