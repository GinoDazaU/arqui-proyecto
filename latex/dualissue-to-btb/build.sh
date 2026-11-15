#!/usr/bin/env bash
# Builds every figure (figs/*.tex -> figs/*.pdf), copies the dual-issue datapath (proc-dual.pdf),
# exports the processor figure to docs/imgs/dualissue-btb-processor.svg and builds dualissue-to-btb.pdf.
#   ./build.sh         # figures + document
#   ./build.sh figs    # only the figures (and the svg)
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
  # every .tex in figs/ with \documentclass (proc-btb-body.tex, common.tex... are \input files)
  for f in figs/*.tex; do
    grep -q '\\documentclass' "$f" || continue
    build_tex figs "$(basename "$f" .tex)" 1
  done
  # starting point: the complete dual-issue datapath of the previous guide
  cp ../pipeline-to-dualissue/figs/proc-dual.pdf figs/proc-dual.pdf
  echo "ok  figs/proc-dual.pdf (from pipeline-to-dualissue)"
  pdftocairo -svg figs/proc-btb.pdf ../../docs/imgs/dualissue-btb-processor.svg
  echo "ok  docs/imgs/dualissue-btb-processor.svg"
fi
if [ "${1:-all}" != figs ]; then
  build_tex . dualissue-to-btb 2
fi
