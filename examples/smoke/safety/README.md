# Upstream memory-safety acceptance cases

`upstream/arrayoob` and `upstream/uaf` are copied verbatim, including their
manifests, from Fil-C release revision
[`2db72c646daa1acad2754bcb0e2f220f732e9789`](https://github.com/pizlonator/fil-c/tree/2db72c646daa1acad2754bcb0e2f220f732e9789):

- [`filc/tests/arrayoob`](https://github.com/pizlonator/fil-c/tree/2db72c646daa1acad2754bcb0e2f220f732e9789/filc/tests/arrayoob): an out-of-bounds stack write. Upstream makes the index opaque to optimization with inline assembly; it must fail with `filc safety error`.
- [`filc/tests/uaf`](https://github.com/pizlonator/fil-c/tree/2db72c646daa1acad2754bcb0e2f220f732e9789/filc/tests/uaf): a write through a freed pointer. It must fail with `filc safety error`, `cannot access pointer to free object`, and `,free`; it must not print `hello`.

The upstream project license is retained at
[`toolchain/tools/LLVM-LICENSE.txt`](../../../toolchain/tools/LLVM-LICENSE.txt).

The BUILD file renames each C `main` through a local define. The harness calls
each entrypoint in a separate child of the packaged Fil-C executable, preserving
the invalid operations. The released musl runtime reports `cannot write pointer
to free object` for `strcpy`, whereas the upstream manifest expects `cannot
access pointer to free object`. The adapter checks their shared `pointer to free
object` diagnostic, `,free`, and absence of `hello`. It additionally
requires a `filc panic:` diagnostic, so an unrelated crash cannot pass. A valid
allocation/read/free control must exit successfully without a safety diagnostic.

`//:memory_safety_test` runs through `filc_test` and its bundled target runtime,
on both supported CPUs and libcs. It runs in every archive CI and BCR smoke task.
The complete upstream Ruby test driver is not needed.
