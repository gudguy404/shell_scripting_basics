#!/usr/bin/env bash
# ==============================================================================
# 🐛 LABORATORIO DE DEPURACIÓN: "ENCUENTRA Y CORRIGE LOS 5 BUGS"
# ==============================================================================
# Instrucciones:
# Este script contiene 5 errores clásicos de principiante que hacen que falle
# o se comporte de manera peligrosa.
#
# Tu misión:
# 1. Ejecútalo con: bash -x ./ejercicio_debug.sh
# 2. O analízalo con: shellcheck ./ejercicio_debug.sh
# 3. Encuentra y repara los 5 errores.
# ==============================================================================

set -uo pipefail

# BUG 1: Observa los espacios en la asignación de variable
DIRECTORIO_BASE = "/tmp/sandbox_scripting"

# BUG 2: Comillas faltantes en variable que contiene espacios
MENSAJE_BIENVENIDA=Bienvenido al laboratorio de depuración

echo $MENSAJE_BIENVENIDA

# BUG 3: Uso incorrecto de comillas en sustitución de comando
echo 'Hoy es: $(date)'

# BUG 4: Comparación numérica usando operadores de texto
CANTIDAD_ARCHIVOS=10
if [[ "$CANTIDAD_ARCHIVOS" > 5 ]]; then
  echo "La cantidad es mayor a 5"
fi

# BUG 5: Variable local declarada fuera de una función, o sobrescritura accidental
procesar_datos() {
  # Falta la palabra clave obligatoria aquí:
  contador=5
  echo "Contador interno: $contador"
}

contador=100
procesar_datos
echo "Contador final (debería seguir siendo 100): $contador"
