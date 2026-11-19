#!/usr/bin/env bash
# Builds presentacion-final.pdf: copies the figures used by the slides from docs/informes, docs/guias and docs/imgs
# (diagrams from the reports, waveforms from informe-final) and runs pdflatex twice.
set -e
cd "$(dirname "$0")"
mkdir -p figs
I=../../informes; G=../../guias
cp ../../imgs/pipeline-processor.png "$I"/informe-final/figs/utec-logo.png figs/
rsvg-convert -f pdf -o figs/dualissue-top.pdf ../../imgs/dualissue-top.svg
rsvg-convert -f pdf -o figs/dualissue-btb-top.pdf ../../imgs/dualissue-btb-top.svg
cp "$I"/informe-e2/figs/dualissue-processor.pdf figs/
for f in pd-regroup pd-raw pd-loaduse pd-branch pd-pairs proc-zoom-fwd; do cp "$G/pipeline-to-dualissue/figs/$f.pdf" figs/; done
for f in proc-btb proc-btb-zoom-fetch btb-inside bu-inside fsm-2bit pd-nopred pd-pred-slot0 pd-pred-slot1 pd-mispredict; do
  cp "$G/dualissue-to-btb/figs/$f.pdf" figs/
done
cp "$I"/informe-e2/figs/waveform-regroup.png "$I"/informe-e2/figs/waveform-raw-forward.png figs/
cp "$I"/informe-final/figs/waveform-*.png figs/
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT
for _ in 1 2; do
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$AUX" presentacion-final.tex > "$AUX/out" 2>&1 \
    || { grep -A3 '^!' "$AUX"/*.log | head -20; exit 1; }
done
cp "$AUX/presentacion-final.pdf" .
grep -E "Overfull|undefined" "$AUX/presentacion-final.log" | head || true
echo "ok  presentacion-final.pdf"
