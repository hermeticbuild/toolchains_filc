"""Relocatable deployment of ordinary dynamically linked Fil-C cc_binary targets."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

_RUNTIME = Label("//:runtime_toolchain_type")

def _quote(value):
    return "'" + value.replace("'", "'\\''") + "'"

def _runfile_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return ctx.workspace_name + "/" + file.short_path

def _copy(copies, file, destination):
    previous = copies.get(destination)
    if previous != None and previous != file:
        fail("Fil-C bundle collision at {}: {} and {}".format(destination, previous.path, file.path))
    copies[destination] = file

def _library(copies, libraries, aliases, file):
    previous = libraries.get(file.basename)
    if previous != None and previous != file:
        aliases.append((previous, file))
        return
    libraries[file.basename] = file
    _copy(copies, file, "lib/" + file.basename)

def _run_impl(ctx):
    runtime = ctx.toolchains[_RUNTIME]
    cc = find_cc_toolchain(ctx)
    configuration = cc_common.configure_features(ctx = ctx, cc_toolchain = cc, requested_features = ctx.features, unsupported_features = ctx.disabled_features)
    readelf = cc_common.get_tool_for_action(feature_configuration = configuration, action_name = "filc-inspect")
    environment = cc_common.get_environment_variables(feature_configuration = configuration, action_name = "filc-inspect", variables = cc_common.empty_variables())
    binary = ctx.attr.binary[DefaultInfo]
    executable = binary.files_to_run.executable
    if executable == None:
        fail("binary must provide an executable")
    bundle = ctx.actions.declare_directory(ctx.label.name + ".bundle")
    launcher = ctx.actions.declare_file(ctx.label.name)
    libraries = {}
    aliases = []
    copies = {}
    inputs = []

    for file in runtime.libraries.to_list():
        _library(copies, libraries, aliases, file)
    _library(copies, libraries, aliases, runtime.loader)
    _copy(copies, runtime.loader, "lib/" + runtime.loader.basename)
    _copy(copies, executable, "bin/app")
    runfiles = binary.default_runfiles
    for plugin in ctx.attr.plugins:
        runfiles = runfiles.merge(plugin[DefaultInfo].default_runfiles)
        for file in plugin[DefaultInfo].files.to_list():
            _library(copies, libraries, aliases, file)
    for file in runfiles.files.to_list():
        _copy(copies, file, "runfiles/" + _runfile_path(ctx, file))
        if file.basename.endswith(".so") or ".so." in file.basename:
            _library(copies, libraries, aliases, file)
    for entry in runfiles.symlinks.to_list():
        _copy(copies, entry.target_file, "runfiles/" + ctx.workspace_name + "/" + entry.path)
    for entry in runfiles.root_symlinks.to_list():
        _copy(copies, entry.target_file, "runfiles/" + entry.path)
    mapping = getattr(binary.files_to_run, "repo_mapping_manifest", None)
    if mapping != None:
        _copy(copies, mapping, "runfiles/_repo_mapping")
    commands = ["set -eu", "mkdir -p " + _quote(bundle.path + "/runfiles")]
    for previous, file in aliases:
        commands.append("cmp -s " + _quote(previous.path) + " " + _quote(file.path) + " || { echo " + _quote("Fil-C library basename collision {}: {} and {}".format(file.basename, previous.path, file.path)) + " >&2; exit 1; }")
        inputs.extend([previous, file])
    for destination, file in copies.items():
        path = bundle.path + "/" + destination
        commands.append("mkdir -p " + _quote(path.rsplit("/", 1)[0]))
        commands.append("cp -RL " + _quote(file.path) + " " + _quote(path))
        inputs.append(file)
    for name in runfiles.empty_filenames.to_list():
        destination = "runfiles/" + name
        if destination not in copies:
            path = bundle.path + "/" + destination
            commands.append("mkdir -p " + _quote(path.rsplit("/", 1)[0]))
            commands.append(": > " + _quote(path))
    commands.append("chmod +x " + _quote(bundle.path + "/lib/" + runtime.loader.basename))
    commands.append(_quote(ctx.file._check.path) + " " + _quote(readelf) + " " + _quote(bundle.path) + " " + _quote(runtime.loader.basename))
    ctx.actions.run_shell(
        inputs = depset(inputs + [ctx.file._check], transitive = [cc.all_files]),
        env = dict(ctx.configuration.default_shell_env) | environment,
        toolchain = "@bazel_tools//tools/cpp:toolchain_type",
        outputs = [bundle],
        command = "\n".join(commands),
        mnemonic = "FilCBundle",
        progress_message = "Packaging target Fil-C loader and runfiles for %{label}",
    )
    ctx.actions.write(launcher, """#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/{bundle}
for library in {libraries}; do
    if ! test -r "$root/lib/$library"; then
        echo "Fil-C application: missing bundled library $library" >&2
        exit 1
    fi
done
export RUNFILES_DIR="$root/runfiles"
export TEST_SRCDIR="$root/runfiles"
{test_chdir}
unset RUNFILES_MANIFEST_FILE LD_LIBRARY_PATH LD_PRELOAD
exec "$root/lib/{loader}" --library-path "$root/lib" "$root/bin/app" "$@"
""".replace("{test_chdir}", 'cd "$root/runfiles/' + ctx.workspace_name + '"' if ctx.attr._test else "").replace("{bundle}", _quote(bundle.basename)).replace("{loader}", runtime.loader.basename).replace("{libraries}", " ".join([_quote(n) for n in sorted(libraries.keys())])), is_executable = True)
    return [DefaultInfo(
        executable = launcher,
        files = depset([launcher, bundle]),
        runfiles = ctx.runfiles(files = [bundle]),
    )]

_ATTRS = {
    "binary": attr.label(mandatory = True, cfg = "target"),
    "plugins": attr.label_list(allow_files = True),
    "_test": attr.bool(default = False),
    "_check": attr.label(default = "//:check_bundle.sh", allow_single_file = True),
}

filc_run = rule(
    implementation = _run_impl,
    attrs = _ATTRS,
    executable = True,
    fragments = ["cpp"],
    toolchains = [_RUNTIME] + use_cc_toolchain(),
)

filc_test = rule(
    implementation = _run_impl,
    attrs = _ATTRS | {"_test": attr.bool(default = True)},
    test = True,
    exec_groups = {"test": exec_group(toolchains = [Label("//:test_toolchain_type")])},
    fragments = ["cpp"],
    toolchains = [_RUNTIME] + use_cc_toolchain(),
)
