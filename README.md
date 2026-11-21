# Aula de HPC con Slurm y BLAST+

**Duración orientativa: 35–45 minutos.** Desde la terminal de Codespaces entrarás por SSH al HPC simulado, enviarás trabajos con Slurm y compararás secuencias con BLAST+. Solo necesitas una cuenta de GitHub con acceso a Codespaces y el enlace del docente. La práctica presupone manejo básico de la terminal Linux e introduce Slurm, FASTA y BLAST+.

Un **trabajo** es una tarea que Slurm ejecuta a partir de un script. La **cola** muestra los trabajos que esperan y los que están en ejecución. El **nodo** es la máquina que los ejecuta. Cada Codespace simula un clúster de un solo nodo y tiene su propia cola.

## 0. Entra al HPC simulado por SSH

1. Inicia sesión en GitHub y abre el enlace del docente.
2. Pulsa **Create codespace**. Si puedes elegir máquina, usa la de **2 núcleos**.
3. Abre **Terminal → New Terminal** y ejecuta:

   ```bash
   ssh hpc@hpc-local
   ```

   `hpc` es tu usuario dentro del HPC simulado. `hpc-local` es el nombre del servidor SSH, que se ejecuta dentro de tu Codespace. La clave de la sesión y la huella del servidor se preparan al arrancar el entorno.

4. Confirma que has entrado como `hpc`, ve a la carpeta de prácticas y comprueba Slurm y BLAST+.

   ```bash
   whoami
   cd ~/practica
   sinfo
   blastn -version
   ```

   `whoami` debe mostrar `hpc`. En `sinfo` busca la partición `docencia`, el nodo `aula01` y el estado `idle` (disponible). Haz los dos ejercicios siguientes dentro de esta sesión SSH. Conserva la sesión para mantener los identificadores guardados.

## 1. Envía dos trabajos y observa la cola

```bash
cat 01-cola.sbatch
```

En el script, las líneas `#SBATCH` indican a Slurm qué recursos reservar y dónde guardar la salida. Las demás líneas son los comandos del trabajo. La línea `sleep 120` hace que dure unos dos minutos.

```bash
primero=$(sbatch --parsable 01-cola.sbatch)
segundo=$(sbatch --parsable 01-cola.sbatch)
printf 'Identificadores: %s y %s\n' "$primero" "$segundo"
squeue -u "$USER"
```

`sbatch` envía el script. Con `--parsable`, devuelve el identificador que guardamos en `primero` o `segundo`. `squeue` muestra los trabajos activos y pendientes.

| Estado | Significado | Qué verás aquí |
|---|---|---|
| `R` | En ejecución | El primer trabajo ocupa el nodo. |
| `PD` | Pendiente | El segundo espera. Busca `(Resources)` en la última columna. |

Si ambos salen pendientes al principio, espera unos segundos y repite `squeue -u "$USER"`. La partición reserva el nodo entero para cada trabajo, así que el segundo solo puede arrancar cuando termine el primero.

Inspecciona el segundo y cancélalo mientras espera.

```bash
scontrol show job "$segundo"
scancel "$segundo"
squeue -u "$USER"
```

Cuando el primero desaparezca de la cola, consulta su salida. Slurm sustituye `%j` por el identificador al crear el archivo.

```bash
cat "cola-${primero}.out"
```

**Comprueba** qué motivo aparecía en la cola y qué hora se registró al inicio y al final. Si pasó el tiempo y el segundo ya había terminado, repite el bloque de envío y cancelación.

## 2. Compara una secuencia con BLAST+

Un **FASTA** es un archivo de texto. Cada secuencia empieza con una cabecera que comienza por `>`, seguida por las letras de la secuencia. Aquí todas las secuencias son sintéticas.

```bash
cat datos/consulta.fasta
head datos/referencias.fasta
cat 02-blast.sbatch
```

La **consulta** es la secuencia que buscas. La **base de referencia** contiene las secuencias con las que la comparas. Ya está indexada con `makeblastdb`. `blastn` busca regiones de ADN que se parezcan a la consulta.

```bash
busqueda=$(sbatch --parsable 02-blast.sbatch)
printf 'Búsqueda: %s\n' "$busqueda"
squeue -u "$USER"
```

Con el nodo libre, BLAST puede terminar antes de que veas el trabajo en la cola. Tras salir de la cola, verifica su estado. `COMPLETED` indica que el script terminó correctamente.

```bash
scontrol show job "$busqueda"
cat "blast-${busqueda}.out"
head "resultados/hits-${busqueda}.tsv"
```

Un **TSV** separa sus columnas con tabuladores. Cada fila describe un alineamiento entre una región de la consulta y una región de una referencia.

| Columna | Qué indica |
|---|---|
| `qseqid` | Identificador de la consulta. |
| `sseqid` | Identificador de la referencia alineada. |
| `pident` | Porcentaje de posiciones idénticas dentro del alineamiento. |
| `length` | Longitud del alineamiento en nucleótidos para este ejemplo. |
| `evalue` | Número esperado de coincidencias de esa puntuación o mejor por azar en una búsqueda de ese tamaño. |
| `bitscore` | Puntuación normalizada del alineamiento. Un valor mayor indica un alineamiento de mayor puntuación. |

**Comprueba** que ves una fila con `consulta_docente`, `referencia_objetivo`, **100 % de identidad** y **180 posiciones**. Aquí coincide la consulta completa porque se extrajo de esa referencia. En otros resultados, compara `length` con la longitud de la consulta antes de interpretar un porcentaje alto.

**Busca en el script** dónde se pide una CPU a Slurm y cómo se indica a BLAST que use ese número de hilos.

## 3. Cierra la sesión y guarda el resultado

Ejecuta `exit` para volver a la terminal de Codespaces. Si quieres descargar el TSV, cópialo primero a la carpeta de trabajo del editor. Sustituye `123` por el identificador que mostró tu búsqueda.

```bash
ssh hpc@hpc-local 'cat ~/practica/resultados/hits-123.tsv' > hits.tsv
```

## Si te atascas

| Qué ves | Qué probar |
|---|---|
| `No such file or directory` al abrir un script | Ejecuta `whoami`. Si ves `alumno`, entra con `ssh hpc@hpc-local`. Dentro de la sesión SSH, ejecuta `cd ~/practica`. |
| Una variable de trabajo está vacía | Vuelve a ejecutar su línea de envío y comprueba que `sbatch` no dio un error. |
| La cola está vacía y falta el TSV | Abre `blast-<id>.out` sustituyendo `<id>` por el número del trabajo. El registro puede explicar el fallo. |
| SSH devuelve `Connection refused` o `Permission denied` | Comprueba que Codespaces terminó de arrancar y que estás usando `ssh hpc@hpc-local`. Si persiste, pasa el mensaje al docente. |
| Codespaces indica que no tienes cuota o acceso | Avisa al docente antes de contratar un plan o cambiar la facturación. |
| `sinfo` no conecta o el nodo figura como `down` | Copia el mensaje y pásaselo al docente. |

Guarda los archivos que necesites. En [Tus Codespaces](https://github.com/codespaces), abre el menú de tu entorno y elige **Stop codespace** cuando termines.

[Preparación y prueba para el docente](DOCENTE.md)
