FROM ubuntu:26.10

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       ca-certificates git munge ncbi-blast+ openssh-client openssh-server procps slurm-client slurmctld slurmd sudo util-linux \
    && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' slurmd)" ge 26.05.4 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/munge/munge.key /etc/ssh/ssh_host_*_key* \
    && useradd --create-home --shell /bin/bash alumno \
    && useradd --create-home --shell /bin/bash hpc \
    && printf 'alumno ALL=(root) NOPASSWD: NOSETENV: /usr/local/sbin/iniciar-aula ""\n' > /etc/sudoers.d/alumno \
    && chmod 0440 /etc/sudoers.d/alumno \
    && visudo -cf /etc/sudoers

COPY --chown=root:root --chmod=0755 .devcontainer/iniciar-aula.sh /usr/local/sbin/iniciar-aula

COPY datos/referencias.fasta /opt/aula-blast/referencias.fasta
RUN makeblastdb -in /opt/aula-blast/referencias.fasta -dbtype nucl \
    -parse_seqids -out /opt/aula-blast/referencias

COPY --chown=root:root --chmod=0755 .devcontainer/iniciar-ssh.sh /usr/local/sbin/iniciar-ssh-aula
COPY --chown=root:root --chmod=0644 .devcontainer/sshd_aula.conf /etc/ssh/sshd_aula.conf
COPY --chown=root:root --chmod=0644 .devcontainer/ssh_aula.conf /etc/ssh/ssh_config.d/20-aula.conf

RUN install -d -o hpc -g hpc -m 0755 /home/hpc/practica
COPY --chown=hpc:hpc 01-cola.sbatch 02-blast.sbatch /home/hpc/practica/
COPY --chown=hpc:hpc datos/ /home/hpc/practica/datos/
COPY --chown=hpc:hpc scripts/verificar.sh /home/hpc/practica/scripts/verificar.sh
