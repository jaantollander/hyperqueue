#!/bin/bash
set -euo pipefail
FILENAME="$LOCAL_SCRATCH/$SLURMD_NODENAME.sdf.tar.gz"
tar -czf "$FILENAME" -- "$LOCAL_SCRATCH/smiles/"*.sdf
cp "$FILENAME" "$PWD"
