#!/usr/bin/env bash
# Builds informe-final.pdf: converts the top diagram (docs/imgs/*.svg -> figs/*.pdf), copies the
# BTB figures of docs/guias/dualissue-to-btb/figs and runs pdflatex twice (auxiliary files in a temp dir).
#   ./build.sh          # diagrams + document
#   ./build.sh waves    # also re-render the waveforms (needs iverilog and matplotlib, via uv)
set -e
cd "$(dirname "$0")"
rsvg-convert -f pdf -o figs/dualissue-btb-top.pdf ../../../docs/imgs/dualissue-btb-top.svg
for f in proc-btb proc-btb-zoom-fetch btb-inside bu-inside fsm-2bit pd-nopred pd-pred-slot0 pd-pred-slot1 pd-mispredict; do
  cp "../../guias/dualissue-to-btb/figs/$f.pdf" figs/
done
if [ "${1:-}" = waves ]; then
  (cd waves && uv run -q --with matplotlib python3 waves.py render ../figs)
fi
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT
for _ in 1 2; do
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$AUX" informe-final.tex > "$AUX/out" 2>&1 \
    || { grep -A3 '^!' "$AUX"/*.log | head -20; exit 1; }
done
cp "$AUX/informe-final.pdf" .
grep -E "undefined|multiply defined" "$AUX/informe-final.log" | head || true
echo "ok  informe-final.pdf"
