#!/usr/bin/env bash
# Builds every figure (figs/*.tex -> figs/*.pdf) and then pipeline-to-dualissue.pdf.
#   ./build.sh         # figures + document
#   ./build.sh figs    # only the figures
#   ./build.sh doc     # only the document (figures must already exist)
set -e
cd "$(dirname "$0")"
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT

build_tex() {  # $1 = directory, $2 = file name without .tex, $3 = number of passes
  local dir=$1 name=$2 passes=${3:-1}
  for _ in $(seq "$passes"); do
    if ! (cd "$dir" && pdflatex -interaction=nonstopmode -halt-on-error \
            -output-directory="$AUX" "$name.tex" > "$AUX/$name.stdout" 2>&1); then
      echo "ERROR in $dir/$name.tex:"; grep -A3 '^!' "$AUX/$name.log" | head -20; exit 1
    fi
  done
  cp "$AUX/$name.pdf" "$dir/$name.pdf"
  if grep -qE "Reference .* undefined|There were undefined references" "$AUX/$name.log"; then
    echo "WARNING: undefined references in $dir/$name.tex"
    grep -E "Reference .* undefined" "$AUX/$name.log" | head
  fi
  echo "ok  $dir/$name.pdf"
}

if [ "${1:-all}" != doc ]; then
  # every .tex in figs/ with \documentclass (proc-body.tex, common.tex... are \input files)
  for f in figs/*.tex; do
    grep -q '\\documentclass' "$f" || continue
    build_tex figs "$(basename "$f" .tex)" 1
  done
fi
if [ "${1:-all}" != figs ]; then
  build_tex . pipeline-to-dualissue 2
fi
