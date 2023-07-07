#!/bin/bash
#SBATCH --partition=large
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=1000
#SBATCH --time=00:15:00
#SBATCH --gres=nvme:1

module load hyperqueue openbabel

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

# Extract the input files to the local disk
srun ./hyperqueue/localdisk/task/extract.sh

# Submit each Open Babel conversion as a separate HyperQueue job
FILES=$(tar -tf ./data/smiles.tar.gz | grep "\.smi")
for FILE in $FILES ; do
    hq submit --stdout=none --stderr=none --cpus=1 ./hyperqueue/localdisk/task/gen3d.sh "$FILE" &
done
hq job wait all

# Compress the output .sdf files and copy the package back to /scratch
srun ./hyperqueue/localdisk/task/archive-copy.sh "$SLURM_SUBMIT_DIR"

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
