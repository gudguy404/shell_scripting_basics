---
tags:
  - curso/modulo07
  - bash/funciones
  - modularidad
  - scope
  - librerias
modulo: 7
tiempo_estimado: 25 min
---

# 🧩 Módulo 7: Funciones y Modularidad Limpia

[[06 - Bucles y Automatización Masiva|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[08 - Programación Defensiva y Debug|Siguiente Módulo ➡️]]

---

## 🎯 Objetivo de este Módulo
Dejar atrás los scripts monolíticos de cientos de líneas desordenadas. Aprenderás a estructurar código en funciones modulares, dominarás el uso obligatorio de `local` para evitar colisiones de memoria, entenderás cómo devolver datos realmente en Bash y cómo crear tus propias librerías reutilizables con `source`.

---

## 1. Declaración de Funciones

En Bash moderno, la forma más limpia y estándar de declarar una función es:

```bash
saludar() {
  echo "Hola desde la función, $1!"
}

# Invocar la función (se llama como cualquier comando ordinario):
saludar "Estudiante"
```

> [!important] Los Argumentos dentro de una Función
> Dentro del cuerpo de una función, `$1`, `$2`, `$#` y `"$@"` pertenecen **exclusivamente a los argumentos pasados a esa función**, no a los argumentos globales del script.

---

## 2. La Regla de Oro del Ámbito: Usa SIEMPRE `local`

Por defecto, **toda variable creada dentro de una función en Bash es GLOBAL**. Si no tienes cuidado, una función puede sobreescribir silenciosamente variables del resto de tu programa.

```bash
# ❌ PELIGRO: Variable global contaminada
contador_global=100

incrementar() {
  contador_global=5   # ¡Sobrescribe la variable del programa principal!
}

incrementar
echo "$contador_global" # Imprime 5, no 100
```

### ✅ La Solución Profesional: La palabra clave `local`

```bash
contador_global=100

incrementar() {
  local contador_global=5  # Vive y muere SOLO dentro de esta función
  echo "Dentro: $contador_global"
}

incrementar
echo "Fuera: $contador_global" # Sigue siendo 100 intacto
```

> [!tip] Mandamiento del Desarrollador Bash
> **Toda variable declarada dentro de una función debe comenzar con `local`.**

---

## 3. El Mito de `return`: ¿Cómo se devuelven datos?

En Python o JavaScript escribes `return "resultado"`. **En Bash eso no existe.**

- **`return N`:** Solo puede devolver un **código de salida numérico entre 0 y 255** (para indicar éxito o fallo).
- **¿Cómo devolvemos texto o datos?** Imprimiendo el resultado con `echo` en la función y capturándolo con sustitución de comandos `$(...)` al invocarla:

```bash
sumar() {
  local num1="$1"
  local num2="$2"
  local resultado=$(( num1 + num2 ))
  
  # Devolvemos el dato a través de stdout
  echo "$resultado"
  
  # Devolvemos el estado de éxito a través del código de salida
  return 0
}

# Capturamos el resultado impreso
TOTAL=$(sumar 40 2)
echo "El total calculado es: $TOTAL"
```

---

## 4. Creación de Librerías y el Comando `source`

A medida que creces como desarrollador, no querrás reescribir tus funciones de colores y logs en cada nuevo script. Puedes guardarlas en un archivo común e importarlas usando `source` (o su alias `.`):

```bash
# Archivo: mi_script.sh
#!/usr/bin/env bash

# Importar funciones desde un archivo externo
source "./libreria_colores.sh"

log_info "Iniciando proceso..."
log_ok "Todo salió perfecto."
```

---

## 🧪 Laboratorio Práctico 7: Creando tu Kit de Utilidades Profesional

Vamos a crear una librería de funciones de registro (logging) y un script que la utilice:

1. Crea la librería reutilizable `logger.sh`:
   ```bash
   nano logger.sh
   ```
2. Pega este código:
   ```bash
   #!/usr/bin/env bash
   # Librería utilitaria de mensajes con colores ANSI

   C_AZUL="\033[1;34m"
   C_VERDE="\033[1;32m"
   C_AMARILLO="\033[1;33m"
   C_ROJO="\033[1;31m"
   C_RESET="\033[0m"

   log_info() {
     echo -e "${C_AZUL}[INFO $(date +%H:%M:%S)]${C_RESET} $*"
   }

   log_ok() {
     echo -e "${C_VERDE}[OK   $(date +%H:%M:%S)]${C_RESET} $*"
   }

   log_warn() {
     echo -e "${C_AMARILLO}[WARN $(date +%H:%M:%S)]${C_RESET} $*"
   }

   log_err() {
     echo -e "${C_ROJO}[ERR  $(date +%H:%M:%S)]${C_RESET} $*" >&2
   }
   ```
3. Ahora crea el script principal `app.sh` que la consuma:
   ```bash
   nano app.sh
   ```
4. Pega este código:
   ```bash
   #!/usr/bin/env bash

   # Importar la librería local
   DIR_ACTUAL="$(dirname "$0")"
   source "$DIR_ACTUAL/logger.sh"

   log_info "Cargando componentes del sistema..."
   sleep 0.5

   log_warn "Uso de memoria ligeramente elevado."
   sleep 0.5

   if [[ -f "/etc/os-release" ]]; then
     log_ok "Sistema operativo verificado con éxito."
   else
     log_err "No se pudo identificar la distribución de Linux."
   fi
   ```
5. Dale permisos y pruébalo:
   ```bash
   chmod +x app.sh logger.sh
   ./app.sh
   ```

---

## 🧩 Checkpoint de Comprensión

> [!question]- ¿Por qué en la función `log_err` pusimos `>&2` al final del `echo`?
> Porque los mensajes de error deben emitirse por el canal de error estándar (`stderr`, descriptor 2). Si el usuario redirige la salida limpia de tu programa a un archivo (`./app.sh > salida.txt`), los errores seguirán viéndose en su pantalla gracias a `>&2`, en lugar de quedar ocultos dentro del archivo de datos.

---

### 🚀 Siguiente Paso
Tu código ahora es modular y ordenado. Es momento de aprender a blindarlo contra cualquier fallo inesperado con programación defensiva y técnicas de depuración:
➡️ **[[08 - Programación Defensiva y Debug|Módulo 8: Programación Defensiva y Debug ➡️]]**
