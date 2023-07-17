#!/bin/bash
#SBATCH --output=%j.out
#SBATCH --partition=interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2000
#SBATCH --time=00:15:00

module load hyperqueue/0.16.0
module load openbabel

# Specify a location for the HyperQueue server
export HQ_SERVER_DIR=${PWD}/.hq-server/${SLURM_JOB_ID}
mkdir -p "${HQ_SERVER_DIR}"

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

# TODO: add start and stop scripts for extract and archive
# Start the workers in the background
(
    unset -v $(printenv | grep --only-matching '^SLURM_[[:upper:]_]*') &&
    hq alloc add slurm \
        --time-limit 10m \
        --workers-per-alloc 1 \
        --cpus 20 \
        --backlog 1 \
        --max-worker-count 1 \
        -- \
        --cpus-per-task 20 \
        --mem-per-cpu 1500 \
        --gres nvme:1 \
        --partition small &
)

# Extract the input files to the local disk and cd there
hq submit --stdout=none --stderr=none --cpus=all ./hyperqueue/localdisk/task/extract.sh &
hq job wait all

# Submit each Open Babel conversion as a separate HyperQueue job
FILES=$(tar -tf ./data/smiles.tar.gz | grep "\.smi")
for FILE in $FILES ; do
    hq submit --stdout=none --stderr=none --cpus=1 ./hyperqueue/localdisk/task/gen3d.sh "$FILE"
done
hq job wait all

# Compress the output .sdf files and copy the package back to /scratch
hq submit --stdout=none --stderr=none --cpus=all ./hyperqueue/localdisk/task/archive.sh "$SLURM_SUBMIT_DIR" &
hq job wait all

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
