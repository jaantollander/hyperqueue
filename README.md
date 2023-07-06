# Workflows
## Hyperqueue
Installation

```bash
mkdir -p appl/hyperqueue/0.15.0
wget https://github.com/It4innovations/hyperqueue/releases/download/v0.15.0/hq-v0.15.0-linux-x64.tar.gz
tar xf hq-v0.15.0-linux-x64.tar.gz --directory=appl/hyperqueue/0.15.0
```

```bash
module use "$PWD/modulefiles"
module load hyperqueue/0.15.0
```

Running scripts

```bash
export SBATCH_ACCOUNT=project_<id>
sbatch ./hyperqueue/hq-<name>.sh
```

Resources

- https://docs.csc.fi/apps/hyperqueue/
- https://csc-training.github.io/csc-env-eff/hands-on/throughput/hyperqueue.html
