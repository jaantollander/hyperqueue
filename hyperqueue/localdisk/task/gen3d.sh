#!/bin/bash
set -euo pipefail
cd "$LOCAL_SCRATCH"
FILE=${1:-$HQ_ENTRY}
obabel "$FILE" -O "${FILE%.*}.sdf" --gen3d best
