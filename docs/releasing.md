# Releasing toolchains_filc

The module version is independent of the pinned Fil-C compiler version. The
initial module release is `0.1.0`, using Fil-C `0.687` and LLVM auxiliary tools
`21.1.8` in the consumer example.

## One-time setup

- Make `BCR_PUBLISH_TOKEN` available to this repository, either directly or as
  an organization secret. The publisher needs permission to push to
  `hermeticbuild/bazel-central-registry` and open a pull request against
  `bazelbuild/bazel-central-registry`. Follow the
  [Publish to BCR token setup](https://github.com/bazel-contrib/publish-to-bcr#3-create-a-personal-access-token).
- Keep the registry fork `hermeticbuild/bazel-central-registry` available.
- Allow the release jobs' declared `contents: write`, `id-token: write`,
  `attestations: write`, and `actions: read` permissions.
- Keep the maintainer identity in `.bcr/metadata.template.json` current.

## Prepare and publish

1. Update `MODULE.bazel`, the consumer's dependency version, and the README for
   the intended release. Keep dependency versions available in the BCR; the
   consumer must work without a Git override for LLVM.
2. Merge the release changes after repository checks and all four archive
   consumer jobs pass: latest stable Bazel 9.x, Linux AMD64/ARM64, and musl/glibc.
3. Create and push a `vVERSION` tag on that reviewed commit. For the initial
   release this is `v0.1.0`. Tagging starts `.github/workflows/release.yml`.
4. The workflow reruns the checks, creates and attests the source and API docs
   archives, and creates a draft GitHub release. API protos are extracted from
   the committed source archive. Publish to BCR then generates the registry
   entry and its attestations, uploads them to that draft, and opens a draft
   BCR pull request. Only after this succeeds does the final job publish the
   GitHub release. BCR acceptance remains a separate review step.
5. Inspect the generated BCR PR's source URL, module version, integrity,
   maintainer metadata, attestations, and presubmit configuration. Have the
   PR author mark it ready for review when appropriate; obtain the required
   BCR maintainer review and presubmit authorization for this new module.

Do not create a release manually before this workflow: all attestation assets
must be uploaded while it is a draft, which also supports GitHub immutable
releases. On failure, inspect the failed job and rerun failed jobs in the same
workflow run so Publish to BCR can reuse the release artifacts. If the release
has already been finalized and is immutable, do not try to replace its assets;
prepare a new version instead.

## Source archive and dry run

The release script archives the tagged Git tree and uses `gzip -n` for stable
compression. The source template expects:

- Asset: `toolchains_filc-vVERSION.tar.gz`.
- API docs asset: `toolchains_filc-vVERSION.docs.tar.gz`, linked by `docs_url`.
- Strip prefix: `toolchains_filc-VERSION`.
- Included: Bazel integration, licenses, BCR templates, docs, and consumer example.
- Excluded: GitHub workflows, untracked development suites, local rc files,
  lockfiles, credentials, and build outputs.

After committing the preparation changes, run on Linux AMD64:

```sh
.github/workflows/check_archive.sh --config=musl_x86_64
.github/workflows/check_archive.sh --config=glibc_x86_64
```

Use the `aarch64` configurations on Linux ARM64. The script compares two
independently generated source archives and release notes, checks the API docs
archive contains exactly the four public API protos, checks the extracted source
layout, then tests the packaged sources through `examples/smoke`'s `local_path_override`.
Scratch directories are printed and retained for inspection. Nothing is tagged,
uploaded, or submitted. To prepare only the archive and notes from a committed ref:

```sh
bash /path/to/toolchains_filc/.github/workflows/release_prep.sh v0.1.0 HEAD
```

Run that command in a scratch directory; both archives are written there and notes
go to stdout. Set `USE_BAZEL_VERSION=9.0.0` to check the minimum supported version.

## API documentation

`//docs:api` uses Bazel 9's built-in `starlark_doc_extract` to generate
`stardoc_output.ModuleInfo` binary protos for the `filc` extension and the
`filc_run`, `filc_test`, and `filc_runtime` rules. Dependency filegroups supply
the loaded Starlark sources; private implementation symbols are not exported
into the reference. No Markdown renderer or additional rules dependency is used.

To build and package the reference from the current checkout:

```sh
bash docs/package.sh /tmp/toolchains_filc.docs.tar.gz
```

The release workflow uploads and attests this archive alongside the source
archive. The registry UI renders it through `.bcr/source.template.json`'s
`docs_url`; the README remains the setup and usage guide. See
[BCR Starlark API documentation](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/stardoc.md).

## Provenance and attestations

The setup follows
[`rules_wine`'s draft-release flow](https://github.com/hermeticbuild/rules_wine/blob/b2783f925c2045998dff3c26c9004aff4a73d693/.github/workflows/release.yml)
and [`rules_qemu`'s BCR templates](https://github.com/hermeticbuild/rules_qemu/tree/de0cdb392c5a4095528122a0725d48eec9c6befd/.bcr).
It uses:

- `bazel-contrib/.github`'s `release_ruleset.yaml@v7.7.0` for source- and docs-archive provenance.
- `bazel-contrib/publish-to-bcr`'s `publish.yaml@v1.7.0`, with `attest: true`,
  for `MODULE.bazel` and `source.json` provenance and the generated
  `attestations.json` registry manifest.

Keep these reusable workflows on named release tags: BCR's SLSA verification
uses their workflow identities. Individual checkout and setup actions are pinned
to commits. The publisher generates the standard attestation template, so no
hand-maintained `.bcr/attestations.template.json` is needed.

The draft release should contain these six assets before publication:

```text
toolchains_filc-vVERSION.tar.gz
toolchains_filc-vVERSION.tar.gz.intoto.jsonl
toolchains_filc-vVERSION.docs.tar.gz
toolchains_filc-vVERSION.docs.tar.gz.intoto.jsonl
MODULE.bazel.intoto.jsonl
source.json.intoto.jsonl
```

Verify the published archive through GitHub, then require the BCR attestation
check to pass for all three subjects:

```sh
gh attestation verify toolchains_filc-vVERSION.tar.gz --repo hermeticbuild/toolchains_filc
gh attestation verify toolchains_filc-vVERSION.docs.tar.gz --repo hermeticbuild/toolchains_filc
```

Local packaging checks cannot generate or verify the release's OIDC signatures.
Those require a tagged GitHub Actions run and the resulting BCR presubmit. The
attestations cover this ruleset's packaging and registry metadata; Fil-C's
downloaded compiler/runtime archives retain their separately pinned checksums
and upstream licensing.

References: [BCR contributions](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/README.md),
[BCR attestations](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/attestations.md),
[Publish to BCR](https://github.com/bazel-contrib/publish-to-bcr/tree/v1.7.0).
