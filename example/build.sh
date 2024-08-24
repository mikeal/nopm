#!/bin/sh

identify() {
  # Make a git hash from a string
  echo "$1" | git hash-object --stdin
}

read_hash() {
  # Read a file by hash (must be committed to local git repo)
  local hash="$1"
  local content
  content=$(git show "$hash")

  # Validate the content by re-computing the hash
  local computed_hash
  computed_hash=$(echo "$content" | git hash-object --stdin)

  if [ "$computed_hash" != "$hash" ]; then
    echo "Validation failed: content hash does not match original hash" >&2
    return 1
  fi

  echo "$content"
}

# Define the source files
source_files=("one.js" "two.js" "three.js")

# Initialize variables
build_from_proof=false
proof_hashes=()

# Parse command-line arguments
while getopts ":i" opt; do
  case $opt in
    i)
      build_from_proof=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Initialize content list
content=()

if [ "$build_from_proof" = true ]; then
  # Build from proof mode
  while IFS= read -r hash; do
    proof_hashes+=("$hash")
  done
  for hash in "${proof_hashes[@]}"; do
    content_item=$(read_hash "$hash")
    if [ $? -ne 0 ]; then
      exit 1
    fi
    content+=("$content_item")
  done
else
  # No arguments passed, use local files
  for file in "${source_files[@]}"; do
    if [ -f "$file" ]; then
      content+=("$(cat "$file")")
    else
      echo "File not found: $file" >&2
      exit 1
    fi
  done
fi

# Simple concatenation for a build example
concatenated_content=$(printf "%s\n" "${content[@]}")

# Print the concatenated content to stdout
echo "$concatenated_content" > program.js

# Print the hashes of the content
for c in "${content[@]}"; do
  echo "$(identify "$c")"
done
