#!/bin/bash
set -euo pipefail

install -d -o root -g root -m 0755 /run/sshd /run/aula-ssh
dir=/run/aula-ssh
if [[ ! -s "$dir/host" || ! -s "$dir/host.pub" ]]; then
    rm -f -- "$dir/host" "$dir/host.pub"
    ssh-keygen -q -t ed25519 -N '' -C hpc-local -f "$dir/host"
fi
if [[ ! -s "$dir/cliente" || ! -s "$dir/cliente.pub" ]]; then
    rm -f -- "$dir/cliente" "$dir/cliente.pub"
    ssh-keygen -q -t ed25519 -N '' -C alumno-codespace -f "$dir/cliente"
fi
chown alumno:alumno "$dir/cliente"
chmod 0400 "$dir/cliente"
chmod 0644 "$dir/cliente.pub"

printf 'hpc-local %s\n' "$(cat "$dir/host.pub")" > "$dir/known_hosts"
/usr/sbin/sshd -t -f /etc/ssh/sshd_aula.conf
if ! pgrep -F "$dir/sshd.pid" -u root -x sshd >/dev/null 2>&1; then
    /usr/sbin/sshd -f /etc/ssh/sshd_aula.conf 9>&-
fi

runuser -u alumno -- ssh -F /etc/ssh/ssh_config.d/20-aula.conf \
    -o BatchMode=yes -o ConnectTimeout=5 hpc@hpc-local 'test "$(id -un)" = hpc'
echo 'Aula disponible. Entra con: ssh hpc@hpc-local'
