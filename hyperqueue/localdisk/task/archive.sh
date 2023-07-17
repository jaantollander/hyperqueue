#!/bin/bash
set -euo pipefail
FILENAME="$SLURMD_NODENAME.sdf.tar.gz"
(cd "$LOCAL_SCRATCH" && tar -czf "$FILENAME" -- ./smiles/*.sdf)
cp "$LOCAL_SCRATCH/$FILENAME" "$PWD"
