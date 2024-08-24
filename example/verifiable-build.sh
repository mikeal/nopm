#!/bin/sh

identify() {
  # Make a git hash from a string
  echo "$1" | git hash-object --stdin
}

# Run the build script and capture the inclusion proof
inclusion_proof=$(./build.sh)

# Compute the hash of the inclusion proof
input_identity=$(identify "$inclusion_proof")

# Compute the hash of the build script
transformation_identity=$(identify "$(cat build.sh)")

# Compute the hash of the final program
output_identity=$(identify "$(cat program.js)")

proof=(
  "$input_identity"
  "$transformation_identity"
  "$output_identity"
)

# Print the build proof
for c in "${proof[@]}"; do
  echo "$c"
done
