cd "$LOCAL_SCRATCH" || exit 1
tar -czf sdf.tar.gz -- ./smiles/*.sdf
cp sdf.tar.gz "$1"
