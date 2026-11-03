"""Fil-C modes before rules_cc user arguments; input/output protocol last."""

load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

def filc_cc_toolchain(name, tool_map, args):
    cc_toolchain(
        name = name,
        tool_map = tool_map,
        args = [args],
        # Mode defaults precede protocol features carrying user compile flags.
        enabled_features = [
            "@toolchains_filc//toolchain/features:no_legacy",
            "@toolchains_filc//toolchain/features:default_compile_flags",
            "@rules_cc//cc/toolchains/args/soname_flags:set_soname_feature",
            "@toolchains_filc//toolchain/features:opt",
            "@toolchains_filc//toolchain/features:dbg",
            "@toolchains_filc//toolchain/features:fastbuild",
            # Archivers need this marker in addition to supports_param_files.
            "@llvm//toolchain/features:archive_param_file",
            # Driver protocol, followed by user arguments and compiler I/O.
            "@rules_cc//cc/toolchains/args/dependency_file:feature",
            "@rules_cc//cc/toolchains/args/random_seed:feature",
            "@rules_cc//cc/toolchains/args/pic_flags:feature",
            "@rules_cc//cc/toolchains/args/preprocessor_defines:feature",
            "@rules_cc//cc/toolchains/args/include_flags:feature",
            "@rules_cc//cc/toolchains/args/archiver_flags:feature",
            "@rules_cc//cc/toolchains/args/libraries_to_link:feature",
            "@rules_cc//cc/toolchains/args/link_flags:feature",
            "@rules_cc//cc/toolchains/args/linkstamp_flags:feature",
            "@rules_cc//cc/toolchains/args/library_search_directories:feature",
            "@rules_cc//cc/toolchains/args/runtime_library_search_directories:feature",
            "@rules_cc//cc/toolchains/args/shared_flag:feature",
            "@rules_cc//cc/toolchains/args/linker_param_file:feature",
            "@rules_cc//cc/toolchains/args/strip_debug_symbols:feature",
            "@rules_cc//cc/toolchains/args/strip_flags:feature",
            "@rules_cc//cc/toolchains/args/compile_flags:feature",
            "@rules_cc//cc/toolchains/args/compiler_input_flags:feature",
            "@rules_cc//cc/toolchains/args/compiler_output_flags:feature",
        ],
        known_features = [
            "@llvm//toolchain/features:external_include_paths",
            "@toolchains_filc//toolchain/features:dynamic_linking_mode",
            "@toolchains_filc//toolchain/features:fully_static_link",
            "@toolchains_filc//toolchain/features:opt_stub",
            "@toolchains_filc//toolchain/features:dbg_stub",
            "@toolchains_filc//toolchain/features:fastbuild_stub",
            "@toolchains_filc//toolchain/features:unsupported_features",
        ],
        supports_param_files = True,
        compiler = "filc",
        target_libc = select({
            "@llvm//constraints/libc:musl": "musl",
            "@llvm//constraints/libc:gnu.2.44": "glibc",
        }),
        target_system_name = select({
            "@llvm//platforms/config:linux_x86_64_musl": "x86_64-unknown-linux-musl",
            "@llvm//platforms/config:linux_aarch64_musl": "aarch64-unknown-linux-musl",
            "@llvm//platforms/config:linux_x86_64_gnu.2.44": "x86_64-unknown-linux-gnu",
            "@llvm//platforms/config:linux_aarch64_gnu.2.44": "aarch64-unknown-linux-gnu",
        }),
    )
