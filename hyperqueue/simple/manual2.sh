#!/bin/bash
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=1000
#SBATCH --time=00:15:00

# Load dependencies
module load hyperqueue

# Specify a location for the HyperQueue server
export HQ_SERVER_DIR=$PWD/.hq-server/$SLURM_JOB_ID
mkdir -p "$HQ_SERVER_DIR"

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

# Start the workers in the background and wait until they have started
(
    srun --overlap --cpu-bind=none --mpi=none hq worker start \
        --manager slurm \
        --idle-timeout 5m \
        --on-server-lost finish-running \
        --cpus="$SLURM_CPUS_PER_TASK" \
        --resource "mem=sum($((SLURM_CPUS_PER_TASK * SLURM_MEM_PER_CPU * 1000000)))" &
)
hq worker wait "$SLURM_NTASKS"

# Submit HyperQueue jobs
for _ in {1..1000} ; do
    hq submit --stdout=none --stderr=none --cpus=1 ./hyperqueue/simple/task/work.sh &
done
hq job wait all

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
