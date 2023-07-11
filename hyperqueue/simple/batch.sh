#!/bin/bash
puhti_partial_single_node() {
    sbatch \
        --partition=small \
        --nodes=1 \
        --tasks-per-node=1 \
        --cpus-per-task=10 \
        --mem-per-cpu=1000 \
        --time=00:15:00 \
        ./manual.sh
}

puhti_partial_multi_node() {
    sbatch \
        --partition=large \
        --nodes=2 \
        --tasks-per-node=1 \
        --cpus-per-task=10 \
        --mem-per-cpu=1000 \
        --time=00:15:00 \
        ./manual.sh
}

puhti_full_single_node() {
    sbatch \
        --partition=small \
        --nodes=1 \
        --tasks-per-node=1 \
        --cpus-per-task=40 \
        --mem-per-cpu=0 \
        --time=00:15:00 \
        --exclusive \
        ./manual.sh
}

puhti_full_multi_node() {
    sbatch \
        --partition=large \
        --nodes=2 \
        --tasks-per-node=1 \
        --cpus-per-task=40 \
        --mem-per-cpu=0 \
        --time=00:15:00 \
        --exclusive \
        ./manual.sh
}

"$@"
