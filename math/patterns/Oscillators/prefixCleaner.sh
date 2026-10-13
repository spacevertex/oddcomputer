#!/bin/bash
prefix="osc_n3_b0_"
for f in "$prefix"*; do
  [ -e "$f" ] || continue
  mv -n -- "$f" "${f#"$prefix"}"
done
