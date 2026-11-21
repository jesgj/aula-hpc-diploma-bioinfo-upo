#!/usr/bin/env bash
#SBATCH --job-name=cola
#SBATCH --partition=docencia
#SBATCH --cpus-per-task=1
#SBATCH --time=00:03:00
#SBATCH --output=cola-%j.out

set -euo pipefail
printf 'Trabajo %s en %s\n' "$SLURM_JOB_ID" "$(hostname)"
date -Iseconds
sleep 120
date -Iseconds
