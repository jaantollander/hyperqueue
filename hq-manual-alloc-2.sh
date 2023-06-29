#!/bin/bash
#SBATCH --partition=small
#SBATCH --account=project_2001659
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --time=00:10:00
#SBATCH --gres=nvme:1

#module load hyperqueue openbabel
module load openbabel

# Use local hyperqueue
export PATH="$PWD/bin:$PATH"

# Specify a location for the HyperQueue server
export HQ_SERVER_DIR=${PWD}/hq-server/${SLURM_JOB_ID}
mkdir -p "${HQ_SERVER_DIR}"

# Start the server in the background (&) and wait until it has started
hq server start &
until hq job list &>/dev/null ; do sleep 1 ; done

# Start the workers (one per node, in the background) and wait until they have started
srun --exact --cpu-bind=none --mpi=none hq worker start --cpus="${SLURM_CPUS_PER_TASK}" &
hq worker wait "${SLURM_NTASKS}"

# Extract the input files to the local disk and cd there
hq submit --stdout=none --stderr=none --cpus=all bash ./task/extract.sh &
hq job wait all

# Submit each Open Babel conversion as a separate HyperQueue job
FILES=$(tar -tf smiles.tar.gz | grep "\.smi")
for FILE in $FILES ; do
    hq submit --stdout=none --stderr=none --cpus=1 bash ./task/gen3d.sh "$FILE" &
done
hq job wait all

# Compress the output .sdf files and copy the package back to /scratch
hq submit --stdout=none --stderr=none --cpus=all bash ./task/archive-copy.sh "$SLURM_SUBMIT_DIR" &
hq job wait all

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
