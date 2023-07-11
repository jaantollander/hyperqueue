#!/bin/bash

# Load dependencies
module load hyperqueue

# Specify a location for the server
export HQ_SERVER_DIR="$PWD/.hq-server/$SLURM_JOB_ID"

# Create a directory for the server
mkdir -p "$HQ_SERVER_DIR"

# Start the server in the background
hq server start &

# Wait until the server has started
until hq job list &> /dev/null ; do sleep 1 ; done

# Set memory for workers in bytes according to SLURM_MEM_PER_CPU if greater than zero.
# Otherwise, leave unset which uses all the memory of the node.
if [[ "${SLURM_MEM_PER_CPU:-0}" -gt 0 ]]; then
    # Calculate the total memory reservation and convert from megabytes to bytes.
    TOTAL_MEM_BYTES=$((SLURM_CPUS_PER_TASK * SLURM_MEM_PER_CPU * 1000000))
    TOTAL_MEM_OPT="--resource mem=sum($TOTAL_MEM_BYTES)"
else
    TOTAL_MEM_OPT=""
fi

# Start the workers in a subshell in the background
srun --overlap --cpu-bind=none --mpi=none hq worker start \
    --manager slurm \
    --idle-timeout 5m \
    --on-server-lost finish-running \
    --cpus="$SLURM_CPUS_PER_TASK" \
    $TOTAL_MEM_OPT &

# Wait until all workers have started
hq worker wait "$SLURM_NTASKS"

# Submit tasks to workers
NUM_TASKS=1000
for ((i=1; i<=NUM_TASKS; i++)); do
    hq submit --stdout=none --stderr=none --cpus=1 ./task
done

# Wait for all the tasks to finish
hq job wait all

# Shut down the workers and server
hq worker stop all
hq server stop
