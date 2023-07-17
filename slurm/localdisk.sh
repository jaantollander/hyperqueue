#!/bin/bash
#SBATCH --output=%j.out
#SBATCH --partition=large
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --mem-per-cpu=1000
#SBATCH --gres=nvme:1

srun -m arbitrary -w "$SLURM_JOB_NODELIST" bash -c "hostname > \$LOCAL_SCRATCH/hostname"
srun bash -c "cat \$LOCAL_SCRATCH/hostname"
