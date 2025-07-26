#!/bin/bash

if [[ -n "$3" ]]; then
  OUT_FILE="$3.patch"
else
  OUT_FILE="patches/$2.patch"
fi

# $1: base branch/tag/commit
# $2: feature branch/tag/commit
if [[ -n "$1" && -n "$2" ]]; then
  echo "Creating patch from $1 to $2 and saving to \"$OUT_FILE\""
else
  echo "Usage: $0 <base> <feature> [output_file]"
  echo 'If output_file is provided, it will be used as the name for the patch file;'
  echo 'if output_file is not provided, it will default to "patches/<feature>.patch".'
  exit 1
fi
git diff -U3 $1..$2 > "$OUT_FILE"
if [[ $? -ne 0 ]]; then
  echo "Error creating patch. Please check the branch names and try again."
  rm -f "$OUT_FILE"
  exit 1
fi
