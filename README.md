# toolchains_filc

Hermetic [Fil-C](https://github.com/pizlonator/fil-c) toolchains for Bazel: compile
memory-safe C and C++ for Linux AMD64 and ARM64, including cross-compilation in
either direction. Uses Fil-C 0.687 prebuilts, with target headers and runtimes
provided by the toolchain.

Requires **Bazel 9+** and Linux AMD64 or ARM64 execution machines with glibc 2.34+
and POSIX tools. For remote execution, register your Linux execution platforms and
use your usual remote-execution configuration. A macOS client can drive Linux
remote builds; the compiler and output programs run on Linux.

## Setup

There is no BCR release yet. Add this to your `MODULE.bazel`:

```starlark
bazel_dep(name = "toolchains_filc", version = "0.0.0")
bazel_dep(name = "llvm", version = "0.8.26")
bazel_dep(name = "platforms", version = "1.1.0")
bazel_dep(name = "rules_cc", version = "0.2.25")

git_override(
    module_name = "toolchains_filc",
    commit = "2c3f0906b6232b301e0ff64444a26a418203c4bd",
    remote = "https://github.com/hermeticbuild/toolchains_filc.git",
)

# llvm 0.8.26 does not include kernel_headers.configure yet.
git_override(
    module_name = "llvm",
    commit = "3dd710dd9cb57adc0a8baf4220f5bc1e38ebd9bc",
    remote = "https://github.com/hermeticbuild/hermetic-llvm.git",
)

llvm = use_extension("@llvm//extensions:llvm.bzl", "llvm")
llvm.version(llvm_version = "21.1.8")
use_repo(llvm, "llvm-project")

kernel_headers = use_extension("@llvm//kernel/extension:kernel_headers.bzl", "kernel_headers")
kernel_headers.configure(default_version = "6.16")
use_repo(kernel_headers, "kernel_headers")

filc = use_extension("@toolchains_filc//extensions:filc.bzl", "filc")
filc.prebuilt(version = "0.687")
use_repo(filc, "filc_toolchains")

register_toolchains("@filc_toolchains//:all")
```

The LLVM version above selects auxiliary tools such as the linker; the C/C++
compiler comes from Fil-C. Kernel-header selection applies to musl targets;
glibc targets use the headers bundled with Fil-C's glibc distribution.

## Build

Use ordinary `rules_cc` targets. For example, `BUILD.bazel`:

```starlark
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    linkstatic = True,
)
```

With `hello.cc`:

```cpp
#include <iostream>

int main() {
    std::cout << "Hello from Fil-C!\n";
}
```

Build for either CPU, using musl for a fully static executable:

```sh
bazel build //:hello --platforms=@toolchains_filc//:linux_x86_64
bazel build //:hello --platforms=@toolchains_filc//:linux_aarch64
```

Run `bazel-bin/hello` on Linux with the matching CPU. Add your remote-build flags
to these commands when using RBE.

| Target platform | CPU | Libc |
| --- | --- | --- |
| `@toolchains_filc//:linux_x86_64` | AMD64 | musl |
| `@toolchains_filc//:linux_aarch64` | ARM64 | musl |
| `@toolchains_filc//:linux_x86_64_gnu.2.44` | AMD64 | Fil-C glibc 2.44 |
| `@toolchains_filc//:linux_aarch64_gnu.2.44` | ARM64 | Fil-C glibc 2.44 |

Custom target platforms need `@toolchains_filc//:abi`, `@platforms//os:linux`,
either `@platforms//cpu:x86_64` or `@platforms//cpu:aarch64`, and either
`@llvm//constraints/libc:musl` or `@llvm//constraints/libc:gnu.2.44`.
Fil-C selection requires only the Linux and CPU constraints on execution platforms.

## Dynamic programs

Musl supports static and dynamic linking. Glibc always requires Fil-C's dynamic
runtime, even with `linkstatic = True`; `fully_static_link` is unsupported for
glibc. Set `linkstatic = False` on `hello` to try dynamic linking with either libc.

Add these targets to the same `BUILD.bazel`, placing the loads at the top:

```starlark
load("@toolchains_filc//runtime:filc_run.bzl", "filc_run")
load("@toolchains_filc//runtime:filc_test.bzl", "filc_test")

filc_run(
    name = "hello_run",
    binary = "hello",
)

filc_test(
    name = "hello_test",
    binary = "hello",
)
```

`filc_run` packages the executable with its loader and runtime libraries.
For example, on Linux AMD64:

```sh
bazel run //:hello_run --platforms=@toolchains_filc//:linux_x86_64_gnu.2.44
```

`bazel run` executes locally even when compilation is remote. For RBE tests,
register a Linux execution platform matching the target CPU and add your remote
flags:

```sh
bazel test //:hello_test --platforms=@toolchains_filc//:linux_x86_64_gnu.2.44
```

## Limitations

- Rebuild C/C++ dependencies with Fil-C. Arbitrary native objects and libraries
  are not ABI-compatible; some projects need source changes for Fil-C.
- Projects with native build-time C/C++ generators also need a separate native
  C/C++ toolchain registered for their execution platforms.
- Sanitizers, LTO, coverage/FDO and OpenMP are currently unsupported by this
  integration. Compiler and runtime builds from source are not provided.
- Glibc archive extraction needs a case-sensitive Bazel output/repository
  filesystem, including when using a macOS client.

Apache 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). Downloaded Fil-C components
retain their own licenses; see [distribution and redistribution notes](prebuilt/LICENSING.md).
