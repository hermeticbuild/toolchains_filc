#!/bin/sh
# A bounded supported-mode guard; target/resource/link policy lives in cc_args.
# The linkage checks reject incompatible requests for the pinned distributions.
# The raw-option checks below also enforce deliberately disabled integration
# features (for example LTO), not a claim that Fil-C fundamentally rejects them.
# They inspect direct argv only; this is not a security boundary or a complete
# option parser for arbitrary user response files.
set -eu
# Link argv commonly arrives in a response file. Action-scoped capability
# markers keep rejection independent of driver response-file parsing.
if [ "${FILC_UNSUPPORTED_PIE:-}" = off ]; then
  echo "Unsupported Fil-C PIE policy: pie:off; Fil-C requires PIE, including static executables" >&2
  exit 1
fi
if [ "${FILC_UNSUPPORTED_LINKAGE:-}" = fully_static_shared_link ]; then
  echo "Unsupported Fil-C fully_static_link on a shared-library link: Fil-C -static requires static PIE and conflicts with -shared" >&2
  exit 1
fi
if [ "${FILC_UNSUPPORTED_LINKAGE:-}" = glibc_fully_static_link ]; then
  echo "Unsupported Fil-C fully_static_link with glibc 2.44: Optfil lacks the required native/runtime archives" >&2
  exit 1
fi
for arg do
  case "$arg" in
    -yolo-assembler|-flto*) echo "Unsupported Fil-C reference mode: $arg" >&2; exit 1 ;;
    --filc-unsupported-feature=*|-fsanitize=*|-fsanitize-coverage=*|-fprofile-generate*|-fprofile-instr-generate*|-fprofile-arcs|-ftest-coverage|-fcoverage-mapping|--coverage|-fopenmp|-fopenmp=*|-fopenmp-targets=*|-fxray-instrument*)
      echo "Unsupported Fil-C pipeline (compatible runtime/tool integration required): $arg" >&2; exit 1 ;;
  esac
done
# cc_args.format uses the target configuration; cc_tool resolves the backing
# linker on the execution platform. Keep this before the configured arguments
# so dynamic/shared links can select linker.sh.
if [ -n "${FILC_LINKER:-}" ]; then
  exec "$FILC_COMPILER" "--ld-path=$FILC_LINKER" "$@"
fi
exec "$FILC_COMPILER" "$@"
