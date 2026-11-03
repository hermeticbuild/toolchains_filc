# Licenses for downloaded Fil-C distributions

The Apache 2.0 license at the module root applies to this Bazel integration.
Downloaded compiler and runtime components retain their upstream licenses; they
are not relicensed by toolchains_filc.

Fil-C's [license documentation](https://github.com/pizlonator/fil-c/blob/2db72c646daa1acad2754bcb0e2f220f732e9789/README.md#license)
identifies these files in the pinned 0.687 distributions:

| Component | Upstream notice |
| --- | --- |
| Compiler, libc++ and libc++abi | `LLVM-LICENSE.txt`, Apache 2.0 with LLVM exceptions and legacy notices |
| Fil-C runtime/libpas | `PAS-LICENSE.txt`, BSD notices |
| Pizfix musl | `MUSL-LICENSE.txt`, MIT and component notices |
| Optfil glibc | `additional_licenses/glibc-LICENSE.txt`, LGPL 2.1 |

Repository extraction preserves the upstream notices. `//target:runtime_licenses`
provides the notices for the selected target libc and CPU, plus the upstream
README with its attribution and source information. Application packagers,
including those distributing statically linked programs, can include those files
with their distribution. Compiler distribution notices remain in its downloaded
repository alongside the compiler and helper files.

`filc_run` and `filc_test` copy the selected runtime notices verbatim into
`<name>.bundle/licenses/fil-c/`. The generated launcher's project notices and
this document are in `licenses/toolchains_filc/`. This covers the toolchain's
runtime components; an application's own dependencies may require other notices.

License files alone do not fulfill all glibc redistribution requirements. When
redistributing glibc binaries, provide the corresponding library sources and
meet the applicable modification/relinking requirements in LGPL 2.1, notably
sections 4 and 6. This toolchain does not package those sources or create a
written source offer on a distributor's behalf.

The source for the pinned Fil-C release is
[`2db72c646daa1acad2754bcb0e2f220f732e9789`](https://github.com/pizlonator/fil-c/tree/2db72c646daa1acad2754bcb0e2f220f732e9789),
including `projects/user-glibc-2.44`, `projects/yolo-glibc-2.44` and the build
scripts. Preserve the source matching the binaries you distribute; an upstream
link is provenance, not a replacement for your source-distribution obligations.
