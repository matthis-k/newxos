#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s QUERY_FILE [OUTPUT_FILE]\n' "$(basename "$0")" >&2
  printf '\nReads one launcher query per line and writes JSON: { "query": <debugSearch result>, ... }.\n' >&2
  printf 'Blank lines are included as the empty query; duplicate query keys keep the last result.\n' >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 2
fi

query_file=$1
output_file=${2:-}

if [ ! -f "$query_file" ]; then
  printf 'query file not found: %s\n' "$query_file" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'missing dependency: jq\n' >&2
  exit 1
fi

if ! command -v newshell >/dev/null 2>&1; then
  printf 'missing dependency: newshell\n' >&2
  exit 1
fi

result='{}'
line_number=0

while IFS= read -r query || [ -n "$query" ]; do
  line_number=$((line_number + 1))
  printf 'collecting [%d]: %s\n' "$line_number" "$query" >&2

  if ! raw=$(newshell ipc call launcher debugSearch "$query" 2>&1); then
    printf 'debugSearch failed for line %d: %s\n' "$line_number" "$query" >&2
    result=$(jq --arg query "$query" --arg error "$raw" '. + {($query): {"error": $error}}' <<<"$result")
    continue
  fi

  if ! jq -e . >/dev/null 2>&1 <<<"$raw"; then
    printf 'debugSearch returned invalid JSON for line %d: %s\n' "$line_number" "$query" >&2
    result=$(jq --arg query "$query" --arg error "$raw" '. + {($query): {"error": "invalid json", "raw": $error}}' <<<"$result")
    continue
  fi

  result=$(jq --arg query "$query" --argjson value "$raw" '. + {($query): $value}' <<<"$result")
done < "$query_file"

if [ -n "$output_file" ]; then
  printf '%s\n' "$result" > "$output_file"
else
  printf '%s\n' "$result"
fi
