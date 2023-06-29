cd "$LOCAL_SCRATCH" || exit 1
obabel "$1" -O "${1%.*}.sdf" --gen3d best
