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
WORKDIR=$PWD/work-$SLURM_JOB_ID
mkdir -p "$WORKDIR/.hq-server"

# Set the directory which hyperqueue will use 
export HQ_SERVER_DIR=$WORKDIR/.hq-server

hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

(
    srun --overlap --cpu-bind=none --hint=nomultithread --mpi=none hq worker start \
        --cpus="$SLURM_CPUS_PER_NODE" &
)
hq worker wait "${SLURM_NTASKS}"

# Make sure nextflow uses the right executor and
# knows how much it can submit.
# TODO: provide as arguments to `nextflow`?
echo "executor {
  queueSize = $(( SLURM_CPUS_PER_TASK * SLURM_NTASKS ))
  name = 'hq'
  cpus = $(( SLURM_CPUS_PER_TASK * SLURM_NTASKS ))
}" > "$WORKDIR/nextflow.config"

cp main.nf "$WORKDIR"
cd "$WORKDIR" || exit 1
nextflow run main.nf

# Make sure we exit cleanly once nextflow is done
hq worker stop all
hq server stop
