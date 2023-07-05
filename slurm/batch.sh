#!/bin/bash
#SBATCH --job-name=example
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH --partition=test
#SBATCH --time=00:15:00
#SBATCH --nodes=2
#SBATCH --mem-per-cpu=1000

srun bash -c 'echo "Hello world $SLURMD_NODENAME"'
srun bash -c '>&2 echo "Hello world $SLURMD_NODENAME"'

echo "Finished"
