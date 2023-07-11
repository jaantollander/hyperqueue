#!/bin/bash
#SBATCH --partition=interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2000
#SBATCH --time=00:15:00

# Load dependencies
module load hyperqueue

# Specify a location for the HyperQueue server
export HQ_SERVER_DIR=$PWD/hq-server/$SLURM_JOB_ID
mkdir -p "$HQ_SERVER_DIR"

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

# Start the workers (one per node, in the background) and wait until they have started
(
    unset -v $(printenv | grep --only-matching '^SLURM_[[:upper:]_]*') &&
    hq alloc add slurm \
        --time-limit 10m \
        --workers-per-alloc 2 \
        --cpus 20 \
        --backlog 1 \
        --max-worker-count 1 \
        -- \
        --cpus-per-task 20 \
        --mem-per-cpu 1500 \
        --partition large &
)

# Submit jobs
for _ in {1..1000} ; do
    hq submit --stdout=none --stderr=none --cpus=1 ./task &
done
hq job wait all

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
