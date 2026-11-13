#!/usr/bin/env bash
# Runs every program on the three architectures:
#   A = pipeline single-issue, B = dual-issue, C = dual-issue + branch predictor (BTB + 2-bit counter)
# checks that the three end with the same registers and data memory, and prints
# cycles / IPC / speedups and the branch prediction metrics.
#   ./tb/run_all.sh                 # all programs under tb/programs (recursive)
#   ./tb/run_all.sh branch          # only the programs whose path contains the text
#   ./tb/run_all.sh opt/            # only one folder
#   ./tb/run_all.sh -v bench/       # also print the full report (stores, registers, memory) of C
set -e
cd "$(dirname "$0")/.."
verbose=0
if [ "${1:-}" = -v ]; then verbose=1; shift; fi
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

iverilog -g2012              -o "$OUT/A.out" designs/pipeline/*.v      tb/perf_tb.v
iverilog -g2012 -DDUAL       -o "$OUT/B.out" designs/dualissue/*.v     tb/perf_tb.v
iverilog -g2012 -DDUAL -DOPT -o "$OUT/C.out" designs/dualissue-btb/*.v tb/perf_tb.v

m() { grep -o "\b$2=[0-9.]*" "$1" | head -1 | cut -d= -f2; }
# functional state = final registers + data memory
state() { sed -n '/REGS:/,/cycles=/p' "$1" | grep -v cycles=; }
div() { [ -n "$1" ] && [ -n "$2" ] && awk "BEGIN{printf \"%.3f\", $1/$2}" || echo -; }

printf "%-25s | %4s | %5s %5s | %5s %5s | %5s %5s | %5s %5s %5s | %4s %4s %4s | %s\n" \
       program "ins" "A cyc" "A IPC" "B cyc" "B IPC" "C cyc" "C IPC" "A/B" "A/C" "B/C" \
       "brs" "misB" "misC" result
fail=0
for p in $(find tb/programs -name '*.mem' -path "*${1:-}*" | sort); do
  n=${p#tb/programs/}; n=${n%.mem}     # e.g. dualissue/branch
  f=${n//\//_}                         # file-safe name for the temp outputs
  for d in A B C; do
    vvp -n "$OUT/$d.out" +prog="$p" | grep -v "WARNING\|finish" > "$OUT/$f.$d.txt"
  done
  ref=$(state "$OUT/$f.A.txt")
  if [ -n "$ref" ] && ! grep -q TIMEOUT "$OUT/$f".?.txt \
     && [ "$ref" = "$(state "$OUT/$f.B.txt")" ] && [ "$ref" = "$(state "$OUT/$f.C.txt")" ]; then
    r=OK
  else
    r=DIFF; fail=1
  fi
  ca=$(m "$OUT/$f.A.txt" cycles); cb=$(m "$OUT/$f.B.txt" cycles); cc=$(m "$OUT/$f.C.txt" cycles)
  printf "%-25s | %4s | %5s %5s | %5s %5s | %5s %5s | %5s %5s %5s | %4s %4s %4s | %s\n" "$n" \
    "$(m "$OUT/$f.A.txt" retired)" \
    "$ca" "$(m "$OUT/$f.A.txt" IPC)" "$cb" "$(m "$OUT/$f.B.txt" IPC)" "$cc" "$(m "$OUT/$f.C.txt" IPC)" \
    "$(div "$ca" "$cb")" "$(div "$ca" "$cc")" "$(div "$cb" "$cc")" \
    "$(m "$OUT/$f.C.txt" branches)" "$(m "$OUT/$f.B.txt" mispredicts)" "$(m "$OUT/$f.C.txt" mispredicts)" "$r"
  if [ $verbose = 1 ]; then
    for d in A B C; do echo "  --- $d"; sed 's/^/  /' "$OUT/$f.$d.txt"; done
  fi
done
echo "ins = retired instructions (equal in A, B and C); A/B, A/C, B/C = speedups;"
echo "brs = branches/jumps executed; misB/misC = mispredictions (B: every taken branch)"
exit $fail
