#!/bin/bash

if [[ -n "$3" ]]; then
  OUT_FILE="$3.patch"
else
  OUT_FILE="patches/$2.patch"
fi

# $1: base branch/tag/commit
# $2: feature branch/tag/commit
if [[ -n "$1" && -n "$2" ]]; then
  echo "Creating patch from $1 to $2"
else
  echo "Usage: $0 <base> <feature> [output_file]"
  exit 1
fi
git diff -U3 $1..$2 > $OUT_FILE
