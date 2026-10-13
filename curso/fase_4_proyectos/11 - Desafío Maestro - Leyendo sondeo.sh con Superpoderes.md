---
tags:
  - curso/modulo11
  - graduacion
  - ciberseguridad
  - redes
  - analisis_codigo
modulo: 11
tiempo_estimado: 20 min
---

# 👾 Módulo 11: El Final Boss — Diseccionando, Debugeando y Venciendo a `sondeo.sh`

[[10 - Glosario Maestro y Próximos Pasos|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]]

---

## 🎯 El Desafío Final: Enfrentándote al "Final Boss"

Has completado los 10 módulos formativos del curso. Ahora llega la prueba definitiva que todo estudiante de scripting debe superar: **enfrentarse al Jefe Final**.

El Final Boss y su taller de construcción guiado se encuentran en su propia carpeta:  
📁 **`proyecto_final_sondeo/`**  
- 📘 Manual Guiado: **[[GUIA_CONSTRUCCION|GUIA_CONSTRUCCION.md]]** (construcción en 6 bloques)
- 🛠️ Plantilla de Trabajo: **[[esqueleto_starter.sh]]** (para programar paso a paso)
- 🛡️ Solución Completa: **[[sondeo.sh]]** (código de referencia)
- 📖 Documentación: **[[proyecto_final_sondeo/README|README del Boss]]**

Al inicio del curso, este script de 257 líneas podía parecer una maraña indescifrable de tuberías, variables mágicas, subredes y llamadas a Python. Hoy tienes **ojos de desarrollador** para construirlo y entenderlo bloque a bloque.

---

## ⚔️ Las 3 Misiones para Vencer al Boss

### 🎯 Misión 1: La Radiografía del Código (Comprenderlo al 100%)
Abre [sondeo.sh](file:///home/mikha/Escritorio/curso_shell_scripting/proyecto_final_sondeo/sondeo.sh) junto a esta guía y comprueba cómo cada una de sus secciones encaja con lo aprendido:

---

### 1. El Encabezado y el Modo Escudo (Líneas 1 a 7)
```bash
#!/usr/bin/env bash
set -uo pipefail
```
- **Lo que ves ahora:**
  - `#!/usr/bin/env bash` *(Módulo 1)*: Shebang portable buscando la ruta dinámica de Bash.
  - `set -uo pipefail` *(Módulo 8)*: El escudo de programación defensiva que detiene el script si hay variables no definidas (`-u`) o si un comando falla dentro de un pipe (`-o pipefail`).

---

### 2. Variables de Configuración y Timestamp (Líneas 9 a 18)
```bash
SUBNET=""
OUTBASE="$HOME/escaneos"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUTDIR="$OUTBASE/scan_$STAMP"
```
- **Lo que ves ahora:**
  - Asignaciones sin espacios alrededor del `=` *(Módulo 3)*.
  - Comillas dobles protectoras `"$..."` para evitar *word splitting* *(Módulo 3)*.
  - Sustitución de comandos `$(date ...)` para generar nombres de carpeta únicos por segundo *(Módulo 3)*.

---

### 3. Funciones de Registro Coloreadas (Líneas 21 a 26)
```bash
C_OK="\033[1;32m"; C_INFO="\033[1;34m"; C_WARN="\033[1;33m"; C_ERR="\033[1;31m"; C_RST="\033[0m"
log()  { echo -e "${C_INFO}[*]${C_RST} $*"; }
ok()   { echo -e "${C_OK}[+]${C_RST} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RST} $*"; }
err()  { echo -e "${C_ERR}[x]${C_RST} $*"; }
```
- **Lo que ves ahora:**
  - Paleta de códigos de escape ANSI *(Módulo 7)*.
  - Funciones modulares que reciben texto mediante la variable mágica `$*` *(Módulo 4 y 7)*.

---

### 4. Chequeo de Root y Dependencias (Líneas 28 a 41)
```bash
if [[ $EUID -ne 0 ]]; then
  err "Ejecuta como root: sudo $0"
  exit 1
fi

for bin in nmap arp-scan xsltproc; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    err "Falta '$bin'. Instala con: sudo apt install -y nmap arp-scan xsltproc"
    exit 1
  fi
done

mkdir -p "$OUTDIR" || { err "No pude crear $OUTDIR"; exit 1; }
```
- **Lo que ves ahora:**
  - Dobles corchetes `[[ $EUID -ne 0 ]]` evaluando que el ID sea superusuario *(Módulo 5)*.
  - `$0` imprimiendo el nombre del script en el mensaje de error *(Módulo 4)*.
  - Bucle `for` iterando sobre una lista de programas *(Módulo 6)*.
  - `command -v` verificando existencia en `$PATH` y silenciando con `>/dev/null 2>&1` *(Módulo 1 y 2)*.
  - Operador de cortocircuito `||` saliendo con código de error `exit 1` si `mkdir` falla *(Módulo 2 y 5)*.

---

### 5. La Tubería de Detección de Red y Here-Document (Líneas 43 a 60)
```bash
IFACE="$(ip route show default | awk '{print $5; exit}')"
IP_CIDR="$(ip -4 -o addr show dev "$IFACE" | awk '{print $4; exit}')"
SUBNET="$(python3 - <<PY
import ipaddress
print(ipaddress.ip_interface("$IP_CIDR").network)
PY
)"
```
- **Lo que ves ahora:**
  - Tuberías conectando `ip` con `awk` *(Módulo 2)*.
  - Here-Document `<<PY ... PY` enviando código a Python por `stdin` expandiendo la variable `$IP_CIDR` *(Módulo 2 y 4)*.

---

### 6. La Tubería de Deduplicación y Ordenamiento (Líneas 68 a 74)
```bash
{
  awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' "$DISCOVERY" 2>/dev/null
  awk '/Status: Up/ {print $2}' "$OUTDIR/.ping.gnmap" 2>/dev/null
} | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n > "$OUTDIR/.hosts.txt"

HOSTCOUNT=$(wc -l < "$OUTDIR/.hosts.txt")
```
- **Lo que ves ahora:**
  - Agrupación de salidas `{ ... ; }` canalizadas por un pipe `|` *(Módulo 2)*.
  - `sort -u` eliminando duplicados y ordenando los 4 octetos numéricamente (`-t.` y `-kn`) *(Módulo 2)*.
  - `wc -l < ...` contando líneas mediante redirección de entrada sin ensuciar con el nombre del archivo *(Módulo 2)*.

---

### 7. Parámetros de Nmap y Formatos Multi-Salida (Líneas 84 a 109)
```bash
nmap -Pn -sS -sV -O --osscan-guess -p- --min-rate 1000 -iL "$OUTDIR/.hosts.txt" -oA "$PORTS_SCAN"
```
- **Lo que ves ahora:**
  - `-iL`: Leyendo la lista de IPs creada en el paso anterior *(Módulo 4)*.
  - `-oA`: Generando los tres formatos (normal, grepable y XML) a la vez.

---

### 8. Sanitización y Generación del Reporte HTML (Líneas 230 a 244)
```bash
cat > "$OUTDIR/REPORTE.html" <<HTML
...
<pre>$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$REPORT_TXT")</pre>
...
HTML
```
- **Lo que ves ahora:**
  - Here-Doc escribiendo un archivo HTML completo directamente con `cat > archivo <<HTML` *(Módulo 2)*.
  - Sustitución de comandos `$(sed ...)` sanitizando caracteres para que el navegador los muestre limpios.

---

### 🎯 Misión 2: Debugear al Boss en Acción
Pon a prueba lo aprendido en el [[08 - Programación Defensiva y Debug|Módulo 8]]:
1. Dirígete a la carpeta del proyecto:
   ```bash
   cd proyecto_final_sondeo
   ```
2. Ejecuta al Boss en **modo traza** para ver cómo se evalúa cada variable y comando paso a paso:
   ```bash
   sudo bash -x ./sondeo.sh
   ```
3. Comprueba el código de salida que devuelve al finalizar (`echo $?`). ¿Devuelve `0`?

---

### 🎯 Misión 3: Modificar y Superar al Boss (Mejoras de Código)
Ahora te toca a ti alterar el código de `sondeo.sh` para demostrar tu maestría:
- [ ] **Añadir el cronómetro del Módulo 3 y 8:** Agrega `SECONDS=0` al inicio y muestra al final cuántos minutos y segundos exactos tardó el escaneo.
- [ ] **Crear un selector rápido del Módulo 4:** Agrega una bandera `--fast` para que escanee solo `--top-ports 100` en lugar de todos los 65,535 puertos (`-p-`).
- [ ] **Blindar con Shellcheck:** Ejecuta `shellcheck ./sondeo.sh` y analiza las recomendaciones del linter.

---

## 🏆 Tu Certificado Personal de Dominio

Si has sido capaz de analizar, depurar y modificar al Boss, **has alcanzado el objetivo supremo del curso**. Ya no eres un consumidor pasivo de scripts: eres un programador de shell capaz de:
1. Leer cualquier script del mundo real y entender su arquitectura interna.
2. Depurar y corregir fallos en herramientas complejas de Linux.
3. Crear tus propias herramientas de administración, ciberseguridad y auditoría desde cero.

¡Bienvenido al mundo de los verdaderos creadores de software en Linux! 🚀
