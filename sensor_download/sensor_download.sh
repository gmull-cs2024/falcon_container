#!/bin/bash

# Check if the required environment variables are set
if [[ -z "$FALCON_API_SENSOR_CLIENT_ID" || -z "$FALCON_API_SENSOR_CLIENT_SECRET" ]]; then
  echo "Error: FALCON_API_SENSOR_CLIENT_ID and FALCON_API_SENSOR_CLIENT_SECRET must be set."
  exit 1
fi

# Array of target values
targets=(
  "falcon-container"
  "falcon-sensor"
  "falcon-kac"
  "falcon-snapshot"
  "falcon-imageanalyzer"
  "kpagent"
  "fcs"
)

# Loop through each target and execute the command
for target in "${targets[@]}"; do
  echo "Pulling sensor for target: $target"
  ./falcon-container-sensor-pull.sh -u "$FALCON_API_SENSOR_CLIENT_ID" -s "$FALCON_API_SENSOR_CLIENT_SECRET" -t "$target" --platform x86_64
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to pull sensor for target: $target"
    exit 1
  fi
done

echo "All sensors pulled successfully."