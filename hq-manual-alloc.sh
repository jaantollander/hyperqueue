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

# Extract the input files to the local disk
tar -xf smiles.tar.gz -C "$LOCAL_SCRATCH"

# Change directory to the local disk
cd "$LOCAL_SCRATCH/smiles" || exit 1

# Submit each Open Babel conversion as a separate HyperQueue job
for f in *.smi ; do
    hq submit --stdout=none --stderr=none obabel "$f" -O "${f%.*}.sdf" --gen3d best &
done

# Wait until all jobs have finished
hq job wait all

# Compress the output .sdf files and copy the package back to /scratch
tar -czf sdf.tar.gz -- *.sdf
cp sdf.tar.gz "$SLURM_SUBMIT_DIR"

# Shut down the HyperQueue workers and server
hq worker stop all
hq server stop
