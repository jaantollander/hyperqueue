#!/bin/bash
set -euo pipefail
cd "$LOCAL_SCRATCH"
FILENAME=$SLURMD_NODENAME.sdf.tar.gz
tar -czf "$FILENAME" -- ./smiles/*.sdf
cp "$FILENAME" "$1"
