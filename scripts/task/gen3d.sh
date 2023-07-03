#!/bin/bash
set -euo pipefail
cd "$LOCAL_SCRATCH"
obabel "$1" -O "${1%.*}.sdf" --gen3d best
