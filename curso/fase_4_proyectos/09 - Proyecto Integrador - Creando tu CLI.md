---
tags:
  - curso/modulo09
  - proyecto_integrador
  - cli
  - bash/avanzado
modulo: 9
tiempo_estimado: 35 min
---

# 🏆 Módulo 9: Proyecto Integrador — Creando tu Propia CLI ("SysSentry")

[[08 - Programación Defensiva y Debug|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[10 - Glosario Maestro y Próximos Pasos|Siguiente Módulo ➡️]]

---

## 🎯 El Desafío
Ha llegado el momento de graduarte como creador de scripts. En este módulo uniremos todo lo aprendido (Shebang, variables, comillas, tuberías, parámetros posicionales, códigos de salida, bucles, funciones con `local`, trampas con `trap` y menú de opciones con `case`) para construir una herramienta CLI profesional llamada **SysSentry**.

```text
  _____             _____             _              
 / ____|           / ____|           | |             
| (___  _   _ ___ | (___   ___ _ __  | |_ _ __ _   _ 
 \___ \| | | / __| \___ \ / _ \ '_ \ | __| '__| | | |
 ____) | |_| \__ \ ____) |  __/ | | || |_| |  | |_| |
|_____/ \__, |___/|_____/ \___|_| |_(_)__|_|   \__, |
         __/ |                                  __/ |
        |___/                                  |___/ 
```

---

## 📋 Especificaciones de "SysSentry"

Tu herramienta debe cumplir con los siguientes requisitos de ingeniería de software:
1. **Modo Estricto:** Ejecutarse con `set -euo pipefail`.
2. **Menú de Opciones:** Aceptar subcomandos (`diagnostico`, `backup`, `limpieza`, `--help`).
3. **Manejo de Señales:** Usar `trap` para limpiar archivos temporales si se cancela.
4. **Modularidad:** Cada funcionalidad debe ser una función independiente con variables `local`.
5. **Salida con Estilo:** Mensajes coloreados mediante funciones de registro (*logging*).
6. **Generación de Reportes:** Guardar un informe estructurado con fecha y hora.

---

## 🛠️ Código Completo de la Herramienta

Crea el archivo `syssentry.sh` en tu espacio de trabajo:

```bash
#!/usr/bin/env bash
# ==============================================================================
# SysSentry - Utilidad de Diagnóstico y Mantenimiento del Sistema
# Creada como Proyecto Integrador del Curso de Fundamentos de Shell Scripting
# ==============================================================================

set -euo pipefail

# 1. Variables Globales y Configuración
VERSION="1.0.0"
DIRECTORIO_REPORTES="$HOME/reportes_syssentry"
STAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVO_REPORTE="$DIRECTORIO_REPORTES/diagnostico_$STAMP.txt"

# 2. Paleta de Colores ANSI
C_AZUL="\033[1;34m"
C_VERDE="\033[1;32m"
C_AMARILLO="\033[1;33m"
C_ROJO="\033[1;31m"
C_RESET="\033[0m"

# 3. Funciones de Mensajería
log_info()    { echo -e "${C_AZUL}[*]${C_RESET} $*"; }
log_ok()      { echo -e "${C_VERDE}[+]${C_RESET} $*"; }
log_warn()    { echo -e "${C_AMARILLO}[!]${C_RESET} $*"; }
log_err()     { echo -e "${C_ROJO}[x]${C_RESET} $*" >&2; }

# 4. Trampa de Limpieza Defensiva
TEMP_DIR="$(mktemp -d -t syssentry_XXXXXX)"
limpieza() {
  rm -rf "$TEMP_DIR"
}
trap limpieza EXIT INT TERM

# 5. Funcionalidad: Diagnóstico del Sistema
ejecutar_diagnostico() {
  mkdir -p "$DIRECTORIO_REPORTES"
  log_info "Recopilando métricas del sistema..."

  local uptime_info
  local uso_disco
  local memoria_total
  local memoria_usada

  uptime_info="$(uptime -p)"
  uso_disco="$(df -h / | awk 'NR==2 {print $5 " de " $2}')"
  memoria_total="$(free -h | awk '/Mem:/ {print $2}')"
  memoria_usada="$(free -h | awk '/Mem:/ {print $3}')"

  # Construir reporte
  {
    echo "=========================================="
    echo "        REPORTE DE SALUD - SYSSENTRY      "
    echo "=========================================="
    echo "Fecha y Hora     : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host             : $(hostname)"
    echo "Usuario          : $USER"
    echo "Tiempo encendido : $uptime_info"
    echo "Uso de Disco (/) : $uso_disco"
    echo "Memoria RAM      : $memoria_usada usada / $memoria_total total"
    echo "=========================================="
  } > "$ARCHIVO_REPORTE"

  cat "$ARCHIVO_REPORTE"
  log_ok "Reporte guardado con éxito en: $ARCHIVO_REPORTE"
}

# 6. Funcionalidad: Copia de Seguridad Rápida
ejecutar_backup() {
  local ruta_origen="${1:-}"

  if [[ -z "$ruta_origen" ]]; then
    log_err "Debes especificar una carpeta para respaldar."
    echo "Uso: $0 backup /ruta/de/la/carpeta"
    exit 1
  fi

  if [[ ! -d "$ruta_origen" ]]; then
    log_err "La carpeta '$ruta_origen' no existe."
    exit 1
  fi

  mkdir -p "$DIRECTORIO_REPORTES"
  local nombre_tar="$DIRECTORIO_REPORTES/backup_$(basename "$ruta_origen")_$STAMP.tar.gz"

  log_info "Empaquetando '$ruta_origen'..."
  tar -czf "$nombre_tar" -C "$(dirname "$ruta_origen")" "$(basename "$ruta_origen")" 2>/dev/null
  log_ok "Respaldo completado: $nombre_tar ($(du -h "$nombre_tar" | cut -f1))"
}

# 7. Funcionalidad: Limpieza de Basura Temporal
ejecutar_limpieza() {
  log_info "Buscando archivos temporales descartables del usuario..."
  local conteo=0

  # Buscar archivos .tmp en la carpeta del usuario
  for archivo in "$HOME"/*.tmp; do
    [[ -e "$archivo" ]] || continue
    rm -f "$archivo"
    conteo=$(( conteo + 1 ))
  done

  log_ok "Limpieza finalizada. Se eliminaron $conteo archivos temporales."
}

# 8. Menú de Ayuda
mostrar_ayuda() {
  cat <<AYUDA
SysSentry v$VERSION - Herramienta de Línea de Comandos

USO:
  $0 [COMANDO] [OPCIONES]

COMANDOS DISPONIBLES:
  diagnostico            Ejecuta un chequeo del sistema y genera un reporte.
  backup <carpeta>       Crea un archivo comprimido .tar.gz de la carpeta indicada.
  limpieza               Elimina archivos residuales .tmp del directorio personal.
  --help, -h             Muestra este mensaje de ayuda.
  --version, -v          Muestra la versión instalada.

EJEMPLOS:
  $0 diagnostico
  $0 backup /home/$USER/Documentos
AYUDA
}

# 9. Enrutador Principal de Opciones (Router CLI con case)
main() {
  local comando="${1:-ayuda}"

  case "$comando" in
    diagnostico)
      ejecutar_diagnostico
      ;;
    backup)
      ejecutar_backup "${2:-}"
      ;;
    limpieza)
      ejecutar_limpieza
      ;;
    --help|-h|ayuda)
      mostrar_ayuda
      ;;
    --version|-v)
      echo "SysSentry versión $VERSION"
      ;;
    *)
      log_err "Comando desconocido: '$comando'"
      mostrar_ayuda
      exit 1
      ;;
  esac
}

# Invocar la función principal pasando todos los argumentos del usuario
main "$@"
```

---

## 🧪 Pruebas de Funcionamiento

1. Dale permisos de ejecución:
   ```bash
   chmod +x syssentry.sh
   ```
2. Prueba el menú de ayuda:
   ```bash
   ./syssentry.sh --help
   ```
3. Ejecuta el diagnóstico del sistema:
   ```bash
   ./syssentry.sh diagnostico
   ```
4. Prueba a hacer un respaldo de prueba:
   ```bash
   mkdir -p /tmp/prueba_sentry
   echo "Archivo secreto" > /tmp/prueba_sentry/info.txt
   ./syssentry.sh backup /tmp/prueba_sentry
   ```

---

## 🌟 Cómo Convertirlo en un Comando Global del Sistema

¿Te gustaría poder escribir simplemente `syssentry diagnostico` desde cualquier lugar de tu terminal sin necesidad de escribir `./` ni estar en la misma carpeta?

> [!tip] Instálalo en tu `$HOME/.local/bin`
> 1. Asegúrate de que la carpeta existe:
>    ```bash
>    mkdir -p "$HOME/.local/bin"
>    ```
> 2. Copia tu script allí con el nombre limpio:
>    ```bash
>    cp syssentry.sh "$HOME/.local/bin/syssentry"
>    chmod +x "$HOME/.local/bin/syssentry"
>    ```
> 3. ¡Listo! Ahora abre una nueva terminal y ejecuta directamente:
>    ```bash
>    syssentry diagnostico
>    ```

---

### 🚀 Siguiente Paso
¡Felicidades por construir tu primera CLI profesional! Revisa el glosario maestro y las siguientes rutas formativas recomendadas:
➡️ **[[10 - Glosario Maestro y Próximos Pasos|Módulo 10: Glosario Maestro y Próximos Pasos ➡️]]**
