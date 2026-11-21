# Preparación para el docente

## Antes de convocar a los 60 alumnos

1. Descomprime el paquete y publica el contenido de `hpc-codespaces/` en la raíz del repositorio. Incluye **`.devcontainer/`** y **`.gitignore`**. Si el repositorio es público, cualquiera con el enlace puede leer la práctica. El paquete solo contiene datos sintéticos.
2. Abre `https://codespaces.new/PROPIETARIO/REPOSITORIO` en el navegador. En un Codespace nuevo de 2 núcleos, abre la terminal y ejecuta, con la cola vacía, `ssh -o BatchMode=yes hpc@hpc-local "cd ~/practica && bash scripts/verificar.sh"`. Verifica también el acceso interactivo con `ssh hpc@hpc-local`. La prueba debe ver los estados `R` y `PD`, confirmar la cancelación, esperar a `COMPLETED` y verificar el alineamiento de 180 posiciones al 100 %.
3. Detén y reanuda el Codespace. Vuelve a entrar por SSH y comprueba `sinfo`. En una cuenta de alumno sin permiso de escritura, repite la apertura desde el enlace y comprueba la cuota, el tiempo de arranque y si puedes entrar por SSH, acceder a `~/practica` y enviar un trabajo.
4. Comparte ese enlace con los cuatro grupos de 15 tras el piloto. Pide que abran el entorno antes de clase con el margen que hayas medido.
5. El HPC simulado vive en cada Codespace. SSH autentica al alumno en una segunda cuenta local, `hpc`, desde la cual se envían trabajos a una cola individual. El usuario, el nodo de acceso simulado y los servicios de cómputo residen en el mismo contenedor.

## Configuración y mantenimiento

- La versión anterior usaba Debian trixie. Se cambió a Ubuntu 26.10 y se exige Slurm **26.05.4 o posterior** por el aviso CVE-2026-65168. Revisa el soporte de la imagen y los avisos de Slurm antes de reutilizarla en otra edición. Para refrescar los paquetes de un Codespace existente, usa **Codespaces: Full Rebuild Container** y repite la prueba.
- El usuario del aula solo tiene `sudo` para el script de arranque, instalado en una ruta propiedad de root y ejecutado sin argumentos. La clave MUNGE se genera en cada contenedor y se guarda con permisos restringidos. SSH escucha solo en `127.0.0.1:2222`, autentica únicamente a `hpc` con una clave de ese contenedor y deshabilita el reenvío por SSH. La configuración de Codespaces también desactiva el reenvío automático de puertos.
- Usa este entorno individual con datos sintéticos. Conserva los puertos sin publicar y deja fuera los secretos de Codespaces, las claves de la universidad y los datos identificables.
- Si SSH o `sinfo` falla, ejecuta `sudo -n /usr/local/sbin/iniciar-aula` desde la terminal inicial de Codespaces y guarda el diagnóstico. Las copias de los scripts en `~/practica` se preparan al construir la imagen. Tras cambiar esos archivos en el repositorio, reconstruye el contenedor. Guarda antes los resultados que quieras conservar. Si el error se produjo durante la construcción del entorno, revisa el registro de creación de Codespaces.

## Referencias

- [Enlaces de creación rápida de Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/setting-up-your-repository/facilitating-quick-creation-and-resumption-of-codespaces)
- [Seguridad en Codespaces](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces)
- [Aviso CVE-2026-65168 en Debian](https://security-tracker.debian.org/tracker/CVE-2026-65168)
- [Guía de usuario de Slurm](https://slurm.schedmd.com/quickstart.html)
- [Manual de BLAST+](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [Configuración del servidor OpenSSH](https://man.openbsd.org/sshd_config)
