"""Pinned Fil-C compiler and target compatibility set."""

VERSION = "0.687"
RELEASE_COMMIT = "2db72c646daa1acad2754bcb0e2f220f732e9789"

# Reported by the pinned compiler's --version, distinct from the release tag.
COMPILER_COMMIT = "e7947f079c976fb167108f7407c20240bca0ca89"
ARCHIVES = {
    "x86_64": "aab538401f78a47ab261ee79afed8c6b99e1d4848e263ae159a75b03c1288da1",
    "aarch64": "f1337799051664f93c7712141deaebe78571ae96ffcf05563d517b89440bcbc0",
}

# Optfil supplies the matched glibc 2.44 target stack. Execution still uses
# Pizfix: its pinned driver and resource ABI match this distribution.
GLIBC_ARCHIVES = {
    "x86_64": "2dc295715dc3347c1cc1b41f7a937b13a076e651e71db42f3adf00d5fb075bfe",
    "aarch64": "375995867dcd3e91533efba6328a5057e51cf7db5a1ffa413ad391d0336ade6e",
}
