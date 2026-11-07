#!/usr/bin/env bash
# Builds informe-e1.pdf (two passes for references; auxiliary files go to a temp dir).
set -e
cd "$(dirname "$0")"
AUX=$(mktemp -d)
trap 'rm -rf "$AUX"' EXIT
for _ in 1 2; do
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$AUX" informe-e1.tex > "$AUX/out" 2>&1 \
    || { grep -A3 '^!' "$AUX"/*.log | head -20; exit 1; }
done
cp "$AUX/informe-e1.pdf" .
grep -E "undefined|multiply defined" "$AUX/informe-e1.log" | head || true
echo "ok  informe-e1.pdf"
