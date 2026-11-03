"""Execution installation tools; no target selection or argument policy."""

load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")

def tools(name, compiler):
    compiler = Label(compiler)
    cc_tool(
        name = name + "_driver",
        src = "@toolchains_filc//toolchain/tools:guard.sh",
        # rules_cc's compiler_files also supplies .s/.S actions.
        data = [
            compiler,
            "@toolchains_filc//toolchain/tools:assemble.sh",
            "@llvm//tools:clang",
        ],
        env = {
            "FILC_COMPILER": "{compiler}",
            "FILC_ASSEMBLER": "{assembler}",
            "FILC_ASSEMBLER_SHIM": "{shim}",
        },
        format = {
            "compiler": compiler,
            "assembler": "@llvm//tools:clang",
            "shim": "@toolchains_filc//toolchain/tools:assemble.sh",
        },
        capabilities = [
            "@rules_cc//cc/toolchains/capabilities:supports_pic",
            "@rules_cc//cc/toolchains/capabilities:supports_dynamic_linker",
        ],
    )
    cc_tool(
        name = name + "_linker_driver",
        src = "@toolchains_filc//toolchain/tools:guard.sh",
        data = [
            compiler,
            "@toolchains_filc//toolchain/tools:linker.sh",
            "@toolchains_filc//toolchain/tools:linker_rewrite",
            "@llvm//tools:ld.lld",
        ],
        env = {
            "FILC_COMPILER": "{compiler}",
            "FILC_LINKER": "{linker}",
            "FILC_LINKER_REWRITE": "{rewrite}",
        },
        format = {
            "compiler": compiler,
            "linker": "@llvm//tools:ld.lld",
            "rewrite": "@toolchains_filc//toolchain/tools:linker_rewrite",
        },
    )
    cc_tool(
        name = name + "_archiver",
        src = "@llvm//tools:llvm-ar",
    )
    cc_tool(
        name = name + "_strip",
        src = "@llvm//tools:llvm-strip",
        data = [
            "@llvm//tools:llvm-objcopy",
            "@llvm//tools:llvm-readelf",
            "@llvm//tools:llvm-readobj",
        ],
    )
    cc_tool(
        name = name + "_objcopy",
        src = "@llvm//tools:llvm-objcopy",
    )
    cc_tool(
        name = name + "_dwp",
        src = "@llvm//tools:llvm-dwp",
    )
    cc_tool(
        name = name + "_readelf",
        src = "@llvm//tools:llvm-readelf",
        data = ["@llvm//tools:llvm-readobj"],
    )
    cc_tool(
        name = name + "_unsupported",
        src = "@toolchains_filc//toolchain/tools:unsupported.sh",
    )
    cc_tool_map(
        name = name + "_tools",
        tools = {
            "@rules_cc//cc/toolchains/actions:c_compile": name + "_driver",
            "@rules_cc//cc/toolchains/actions:cpp_compile": name + "_driver",
            "@rules_cc//cc/toolchains/actions:linkstamp_compile": name + "_driver",
            "@rules_cc//cc/toolchains/actions:assemble": name + "_driver",
            "@rules_cc//cc/toolchains/actions:preprocess_assemble": name + "_driver",
            "@rules_cc//cc/toolchains/actions:cpp_link_executable": name + "_linker_driver",
            "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library": name + "_linker_driver",
            "@rules_cc//cc/toolchains/actions:cpp_link_nodeps_dynamic_library": name + "_linker_driver",
            "@rules_cc//cc/toolchains/actions:cpp_link_static_library": name + "_archiver",
            "@rules_cc//cc/toolchains/actions:strip": name + "_strip",
            "@rules_cc//cc/toolchains/actions:objcopy_embed_data": name + "_objcopy",
            "@rules_cc//cc/toolchains/actions:dwp": name + "_dwp",
            "@rules_cc//cc/toolchains/actions:lto_index_for_executable": name + "_unsupported",
            "@rules_cc//cc/toolchains/actions:lto_index_for_dynamic_library": name + "_unsupported",
            "@rules_cc//cc/toolchains/actions:lto_index_for_nodeps_dynamic_library": name + "_unsupported",
            "@rules_cc//cc/toolchains/actions:lto_backend": name + "_unsupported",
            "@toolchains_filc//runtime:inspect_action": name + "_readelf",
        },
    )
