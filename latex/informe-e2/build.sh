#!/usr/bin/env bash
# Builds informe-e2.pdf: converts the diagrams (docs/imgs/*.svg -> figs/*.pdf) and runs
# pdflatex twice (auxiliary files go to a temp dir).
#   ./build.sh          # diagrams + document
#   ./build.sh waves    # also re-render the waveforms (needs iverilog and matplotlib, via uv)
set -e
cd "$(dirname "$0")"
for d in dualissue-top dualissue-processor; do
  rsvg-convert -f pdf -o "figs/$d.pdf" "../../docs/imgs/$d.svg"
done
if [ "${1:-}" = waves ]; then
  (cd waves && uv run -q --with matplotlib python3 waves.py render ../figs)
fi
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT
for _ in 1 2; do
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$AUX" informe-e2.tex > "$AUX/out" 2>&1 \
    || { grep -A3 '^!' "$AUX"/*.log | head -20; exit 1; }
done
cp "$AUX/informe-e2.pdf" .
grep -E "undefined|multiply defined" "$AUX/informe-e2.log" | head || true
echo "ok  informe-e2.pdf"
