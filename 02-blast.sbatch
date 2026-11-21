#!/usr/bin/env bash
#SBATCH --job-name=blast
#SBATCH --partition=docencia
#SBATCH --cpus-per-task=1
#SBATCH --time=00:02:00
#SBATCH --output=blast-%j.out

set -euo pipefail
if [[ -z "${SLURM_JOB_ID:-}" ]]; then
    echo 'Envía este script desde Slurm con sbatch 02-blast.sbatch.' >&2
    exit 1
fi
query=${1:-datos/consulta.fasta}
output=${2:-resultados/hits-${SLURM_JOB_ID}.tsv}
if [[ ! -s "$query" ]]; then
    printf 'No se encuentra el FASTA de consulta o está vacío: %s\n' "$query" >&2
    exit 1
fi
mkdir -p -- "$(dirname -- "$output")"

blastn -task blastn \
    -query "$query" -db /opt/aula-blast/referencias \
    -num_threads "$SLURM_CPUS_PER_TASK" \
    -outfmt '6 qseqid sseqid pident length evalue bitscore' -out "$output"

printf 'Resultado: %s\nNúmero de alineamientos: ' "$output"
wc -l < "$output"
