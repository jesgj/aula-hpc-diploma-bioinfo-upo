#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
work=$(mktemp -d)
first=
second=
blast=
cleanup() {
    for job in "$first" "$second" "$blast"; do
        if [[ -n "$job" ]]; then
            scancel "$job" 2>/dev/null || true
        fi
    done
    rm -rf -- "$work"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

sinfo
sinfo --version
blastn -version

if [[ -n "$(squeue --noheader --format='%i')" ]]; then
    echo 'Vuelve a ejecutar esta prueba cuando la cola esté vacía.' >&2
    exit 1
fi

first=$(sbatch --parsable --output="$work/cola-%j.out" 01-cola.sbatch)
second=$(sbatch --parsable --output="$work/cola-%j.out" 01-cola.sbatch)
seen=0
for ((attempt=1; attempt<=25; attempt++)); do
    queue=$(squeue --noheader --jobs="$first,$second" --format='%i %t')
    if grep -qx "$first R" <<< "$queue" && grep -qx "$second PD" <<< "$queue"; then
        printf '%s\n' "$queue"
        seen=1
        break
    fi
    sleep 1
done
if [[ "$seen" == 0 ]]; then
    echo 'No se observó el primer trabajo en R y el segundo en PD.' >&2
    squeue >&2
    exit 1
fi
scancel "$second" "$first"

wait_for_state() {
    local job=$1 expected=$2 status attempt
    for ((attempt=1; attempt<=60; attempt++)); do
        status=$(scontrol -o show job "$job")
        if [[ " $status " == *" JobState=$expected "* ]]; then
            return 0
        fi
        if [[ "$status" =~ JobState=(COMPLETED|FAILED|TIMEOUT|NODE_FAIL|OUT_OF_MEMORY|CANCELLED)([[:space:]]|$) ]]; then
            break
        fi
        sleep 1
    done
    printf 'El trabajo %s no alcanzó el estado %s.\n%s\n' "$job" "$expected" "$status" >&2
    return 1
}

wait_for_state "$second" CANCELLED
wait_for_state "$first" CANCELLED
second=
first=

blast=$(sbatch --parsable --output="$work/blast.out" 02-blast.sbatch datos/consulta.fasta "$work/hits.tsv")
if ! wait_for_state "$blast" COMPLETED; then
    if [[ -f "$work/blast.out" ]]; then
        cat "$work/blast.out" >&2
    fi
    exit 1
fi
blast=
cat "$work/blast.out"
awk -F '\t' '
    $1 == "consulta_docente" && $2 == "referencia_objetivo" && $3 == 100 && $4 == 180 {
        print
        found = 1
    }
    END { exit !found }
' "$work/hits.tsv"
echo 'Verificación correcta: cola, cancelación y alineamiento BLAST.'
