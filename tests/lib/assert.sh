#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ASSERT FAIL: $*" >&2
  exit 1
}

assert_file_exists() {
  local f="$1"
  [[ -f "$f" ]] || fail "expected file to exist: $f"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq -- "$pattern" "$file" || fail "expected '$pattern' in $file"
}

assert_regex() {
  local file="$1"
  local pattern="$2"
  grep -Eq -- "$pattern" "$file" || fail "expected regex '$pattern' in $file"
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq -- "$pattern" "$file"; then
    fail "did not expect '$pattern' in $file"
  fi
}