#!/bin/bash
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LC_ALL=C
umask 022
cd /

install -d -o munge -g munge -m 0755 /run/munge
install -d -o slurm -g slurm -m 0755 /run/slurm /var/spool/slurmctld
install -d -m 0755 /var/spool/slurmd
exec 9>/run/aula-hpc.lock
flock 9

if ! test -s /etc/munge/munge.key; then
    key=$(mktemp /etc/munge/munge.key.XXXXXXXX)
    trap 'rm -f -- "$key"' EXIT
    dd if=/dev/urandom of="$key" bs=1024 count=1 status=none
    chown munge:munge "$key"
    chmod 0400 "$key"
    mv -f -- "$key" /etc/munge/munge.key
    trap - EXIT
fi
chown munge:munge /etc/munge/munge.key
chmod 0400 /etc/munge/munge.key
if ! munge -n >/dev/null 2>&1; then
    runuser -u munge -- munged 9>&-
fi

install -d -m 0755 /etc/slurm
host=$(hostname -s)
topology=$(slurmd -C | awk '
    /^NodeName=/ {
        for (i = 2; i <= NF; i++)
            if ($i ~ /^(CPUs|Boards|SocketsPerBoard|CoresPerSocket|ThreadsPerCore)=/)
                printf " %s", $i
        exit
    }')
test -n "$topology"

# Las asignaciones son exclusivas por nodo para poder observar la cola.
cat > /etc/slurm/slurm.conf <<CONFIG
ClusterName=aula
SlurmctldHost=${host}(127.0.0.1)
SlurmUser=slurm
AuthType=auth/munge
StateSaveLocation=/var/spool/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SlurmctldPidFile=/run/slurm/slurmctld.pid
SlurmdPidFile=/run/slurm/slurmd.pid
SlurmctldLogFile=/var/spool/slurmctld/slurmctld.log
SlurmdLogFile=/var/spool/slurmd/slurmd.log
ProctrackType=proctrack/pgid
TaskPlugin=task/none
SwitchType=switch/none
MpiDefault=none
SelectType=select/linear
ReturnToService=2
NodeName=aula01 NodeHostname=${host} NodeAddr=127.0.0.1${topology} State=UNKNOWN
PartitionName=docencia Nodes=aula01 Default=YES MaxTime=00:10:00 OverSubscribe=EXCLUSIVE State=UP
CONFIG
printf 'CgroupPlugin=disabled\n' > /etc/slurm/cgroup.conf
chmod 0644 /etc/slurm/{slurm,cgroup}.conf

if ! pgrep -u root,slurm -x slurmctld >/dev/null; then
    slurmctld 9>&-
fi
if ! pgrep -u root -x slurmd >/dev/null; then
    slurmd -N aula01 9>&-
fi

for ((attempt=1; attempt<=30; attempt++)); do
    if sinfo -Nh -n aula01 -o '%t' | grep -Eq '^(idle|alloc|mix)$'; then
        sinfo
        exec /usr/local/sbin/iniciar-ssh-aula
    fi
    sleep 1
done

sinfo -Nel || true
tail -n 30 /var/spool/{slurmctld/slurmctld,slurmd/slurmd}.log >&2 || true
echo 'El nodo docente no está disponible.' >&2
exit 1
