#!/bin/bash
set -euo pipefail
cd "$LOCAL_SCRATCH"
tar -czf sdf.tar.gz -- ./smiles/*.sdf
cp sdf.tar.gz "$1"
