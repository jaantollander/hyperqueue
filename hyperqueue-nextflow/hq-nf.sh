#!/bin/bash
#SBATCH --partition=large
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1000
#SBATCH --time=00:10:00

# Load the required modules
module load hyperqueue nextflow

# Create a per job directory
WORKDIR=$PWD/work/$SLURM_JOB_ID

# Specify a location for the HyperQueue server
export HQ_SERVER_DIR=$WORKDIR/.hq-server
mkdir -p "$HQ_SERVER_DIR"

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

# Start the workers in the background and wait until they have started
(
    srun --overlap --cpu-bind=none --hint=nomultithread --mpi=none hq worker start \
        --manager slurm \
        --idle-timeout 5m \
        --on-server-lost finish-running \
        --cpus="$SLURM_CPUS_PER_TASK" \
        --resource "mem=sum($((SLURM_CPUS_PER_TASK * SLURM_MEM_PER_CPU * 1000000)))" &
)
hq worker wait "$SLURM_NTASKS"

# Make sure nextflow uses the right executor and knows how much it can submit.
echo "executor {
  name = 'hq'
  queueSize = $(( SLURM_CPUS_PER_TASK * SLURM_NTASKS ))
  cpus = $(( SLURM_CPUS_PER_TASK * SLURM_NTASKS ))
  memory = $(( SLURM_CPUS_PER_TASK * SLURM_MEM_PER_CPU * SLURM_NTASKS )) MB
}" > "$WORKDIR/nextflow.config"

# Copy the nextflow workflow
cp main.nf "$WORKDIR"

# Change to work directory
cd "$WORKDIR" || exit 1

# Run the nextflow workflow
nextflow run main.nf

# Shut down the HyperQueue workers and server once nextflow is done
hq worker stop all
hq server stop
