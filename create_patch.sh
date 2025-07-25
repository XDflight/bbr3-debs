#!/bin/bash

if [[ -n "$3" ]]; then
  OUT_FILE="$3.patch"
else
  OUT_FILE="patches/$2.patch"
fi

# $1: base branch/tag/commit
# $2: feature branch/tag/commit
git diff -U3 $1..$2 > $OUT_FILE
