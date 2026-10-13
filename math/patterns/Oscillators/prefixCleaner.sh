#!/bin/bash
prefix="osc_n5_b0_"
for f in "$prefix"*; do
  [ -e "$f" ] || continue
  mv -n -- "$f" "${f#"$prefix"}"
done
