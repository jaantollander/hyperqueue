#!/bin/bash
#SBATCH --output=%j.out
#SBATCH --partition=large
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=1000
#SBATCH --time=00:15:00
#SBATCH --gres=nvme:1

module load hyperqueue/0.16.0
module load openbabel

export HQ_SERVER_DIR=$PWD/.hq-server/$SLURM_JOB_ID
mkdir -p "$HQ_SERVER_DIR"

hq server start &

until hq job list &>/dev/null ; do sleep 1 ; done

srun --overlap --cpu-bind=none --mpi=none hq worker start \
    --manager slurm \
    --idle-timeout 5m \
    --on-server-lost finish-running \
    --cpus="$SLURM_CPUS_PER_TASK" \
    --resource "mem=sum($((SLURM_CPUS_PER_TASK * SLURM_MEM_PER_CPU * 1000000)))" &

hq worker wait "$SLURM_NTASKS"

srun -m arbitrary -w "$SLURM_JOB_NODELIST" ./task/extract.sh

# TODO: try --each-line <(echo "$FILES"), HQ_ENTRY
FILES=$(tar -tf ./data/smiles.tar.gz | grep "\.smi")
#for FILE in $FILES ; do
#    hq submit --stdout=none --stderr=none --cpus=1 ./task/gen3d.sh "$FILE"
#done
hq submit --stdout=none --stderr=none --cpus=1 --each-line <(echo "$FILES") ./task/gen3d.sh
hq job wait all

srun -m arbitrary -w "$SLURM_JOB_NODELIST" ./task/archive.sh "$SLURM_SUBMIT_DIR"

hq worker stop all
hq server stop
