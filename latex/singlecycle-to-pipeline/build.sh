#!/usr/bin/env bash
# Builds singlecycle-to-pipeline.pdf (figures live in ./figs; the SVG is converted to PDF first).
set -e
cd "$(dirname "$0")"
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT
rsvg-convert -f pdf -o figs/pipeline-top.pdf figs/pipeline-top.svg
for _ in 1 2; do
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$AUX" singlecycle-to-pipeline.tex > "$AUX/out" 2>&1 \
    || { grep -A3 '^!' "$AUX"/*.log | head -20; exit 1; }
done
cp "$AUX/singlecycle-to-pipeline.pdf" .
echo "ok  singlecycle-to-pipeline.pdf"
