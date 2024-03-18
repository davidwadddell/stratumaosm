#!/bin/bash

# With start and end range checks ^..$
pattern_prefix="^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
pattern_suffix="[0-9][0-9][0-9]$"

# Without the start and end range checks.
#pattern_prefix="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
#pattern_suffix="[0-9][0-9][0-9]"

for ((i = 0; i < 100; i = i + 1))
do
  num=$i
  if [[ "${#num}" == "1" ]]; then
    num="0"$num
  fi

  pattern="${pattern_prefix}${num}${pattern_suffix}"
  echo "        - $pattern"
done
