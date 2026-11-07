#!/usr/bin/env bash
# Runs every program on the pipeline (A) and the dual-issue (B) designs,
# checks that both end with the same registers and data memory, and prints
# cycles / IPC for each one.
#   ./tb/run_all.sh                 # all programs under tb/programs (recursive)
#   ./tb/run_all.sh branch          # only the programs whose path contains the text
#   ./tb/run_all.sh dualissue/      # only one folder
set -e
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

iverilog -g2012       -o "$OUT/pipe.out" designs/pipeline/*.v   tb/perf_tb.v
iverilog -g2012 -DDUAL -o "$OUT/dual.out" designs/dualissue/*.v tb/perf_tb.v

printf "%-26s | %6s %6s %6s | %6s %6s %6s | %7s | %s\n" \
       program "A cyc" "A ins" "A IPC" "B cyc" "B ins" "B IPC" speedup result
fail=0
for p in $(find tb/programs -name '*.mem' -path "*${1}*" | sort); do
  n=${p#tb/programs/}; n=${n%.mem}     # e.g. dualissue/branch
  f=${n//\//_}                         # file-safe name for the temp outputs
  for d in pipe dual; do
    vvp -n "$OUT/$d.out" +prog="$p" | grep -v "WARNING\|finish" > "$OUT/$f.$d.txt"
  done
  # functional state = final registers + data memory
  state() { sed -n '/REGS:/,/cycles=/p' "$1" | grep -v cycles=; }
  if [ -n "$(state "$OUT/$f.pipe.txt")" ] && diff -q <(state "$OUT/$f.pipe.txt") <(state "$OUT/$f.dual.txt") > /dev/null; then
    r=OK
  else
    r=DIFF; fail=1
  fi
  m() { grep -o "$2=[0-9.]*" "$1" | head -1 | cut -d= -f2; }
  ca=$(m "$OUT/$f.pipe.txt" cycles); cb=$(m "$OUT/$f.dual.txt" cycles)
  sp=$( [ -n "$ca" ] && [ -n "$cb" ] && awk "BEGIN{printf \"%.3f\", $ca/$cb}" || echo -)
  printf "%-26s | %6s %6s %6s | %6s %6s %6s | %7s | %s\n" "$n" \
    "$ca" "$(m "$OUT/$f.pipe.txt" retired)" "$(m "$OUT/$f.pipe.txt" IPC)" \
    "$cb" "$(m "$OUT/$f.dual.txt" retired)" "$(m "$OUT/$f.dual.txt" IPC)" "$sp" "$r"
done
exit $fail
