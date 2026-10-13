---
tags:
  - curso/modulo04
  - bash/argumentos
  - parametros_posicionales
  - interactividad
modulo: 4
tiempo_estimado: 20 min
---

# 🎯 Módulo 4: Parámetros Posicionales y Argumentos

[[03 - Variables, Sintaxis y la Regla de Oro|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[05 - Códigos de Salida y Estructuras Condicionales|Siguiente Módulo ➡️]]

---

## 🎯 Objetivo de este Módulo
Hacer que tus scripts dejen de tener rutas o datos fijos (*hardcoded*) y se conviertan en verdaderas herramientas dinámicas. Aprenderás a recibir parámetros desde la línea de comandos (`$1`, `$2`), dominar las variables mágicas (`$#`, `$@`) y solicitar datos al usuario con `read`.

---

## 1. El Concepto de Parámetros Posicionales

Cuando ejecutas un comando nativo de Linux como `cp origen.txt destino.txt`, el programa sabe qué copiar gracias a la posición de las palabras. En Bash, tus scripts reciben esos argumentos a través de variables automáticas numeradas:

```text
./mi_script.sh   servidor.com   8080   /var/www
      │               │           │       │
     $0              $1          $2      $3
```

- **`$0`**: Contiene el nombre del script tal como fue invocado (`./mi_script.sh`).
- **`$1`**: El primer argumento (`servidor.com`).
- **`$2`**: El segundo argumento (`8080`).
- **`$3`**: El tercer argumento (`/var/www`).
- **`${10}`**: A partir del argumento 10 en adelante, **debes usar llaves obligatoriamente** para evitar que Bash interprete `$10` como `$1` seguido del número `0`.

---

## 2. El Cuarteto de Variables Mágicas

Bash reserva variables automáticas fundamentales para el control de argumentos:

| Variable Mágica | Significado | Caso de Uso Típico |
| :---: | :--- | :--- |
| **`$#`** | Número total de argumentos pasados | Comprobar si el usuario olvidó pasar parámetros: `if [[ $# -lt 2 ]]...` |
| **`"$@"`** | Todos los argumentos por separado | Iterar sobre cada parámetro respetando comillas y espacios. |
| **`"$*"`** | Todos los argumentos unidos en un solo texto | Escribir un mensaje de log con todo lo que se pasó. |
| **`$$`** | El ID de Proceso (PID) de este script | Crear archivos temporales únicos: `/tmp/temp_$$` |

> [!tip] La diferencia vital entre `"$@"` y `"$*"`
> Si ejecutas `./script.sh "dos palabras" "tres palabras"`:
> - `"$@"` genera **2** bloques: `"dos palabras"` y `"tres palabras"`.
> - `"$*"` genera **1** solo bloque gigante: `"dos palabras tres palabras"`.
> **En el 99% de los casos debes usar `"$@"`.**

---

## 3. Asignación Elegante de Valores por Defecto

¿Qué pasa si el usuario ejecuta tu script sin pasar ningún argumento? Puedes usar la potente sintaxis de **expansión de parámetros**:

```bash
# Si $1 existe y no está vacío, usa $1. Si está vacío, usa "invitado":
USUARIO="${1:-invitado}"

# Si $2 está vacío, detén el script de inmediato con un mensaje de error:
PUERTO="${2:?Error: Debes indicar un puerto obligatoriamente}"
```

Observa qué limpio resulta: no necesitas escribir 5 líneas de `if/else` para asignar un valor predeterminado seguro.

---

## 4. Entrada Interactiva con `read`

Si prefieres que el script pregunte interactivamente al usuario mientras corre:

```bash
# -p muestra un texto de prompt
read -p "¿Cuál es tu nombre? " NOMBRE_USUARIO
echo "Encantado de saludarte, $NOMBRE_USUARIO."

# -s oculta lo que se escribe (modo silencioso, ideal para contraseñas o tokens)
read -sp "Introduce tu token secreto: " TOKEN_API
echo "" # Salto de línea estético
```

---

## 🧪 Laboratorio Práctico 4: Herramienta de Empaquetado Automático

Vamos a crear un script que reciba una carpeta a respaldar por parámetro, y si no se especifica, use una por defecto:

1. Crea el archivo:
   ```bash
   nano empaquetador.sh
   ```
2. Escribe este código:
   ```bash
   #!/usr/bin/env bash

   # 1. Validar cuántos argumentos llegaron
   echo "Invocado como : $0"
   echo "Argumentos totales recibidos: $#"

   # 2. Asignar parámetros con valor por defecto
   ORIGEN="${1:-$PWD}"
   NOMBRE_ARCHIVO="${2:-empaque_$(date +%Y%m%d).tar.gz}"

   echo "----------------------------------------"
   echo "Directorio a empaquetar : $ORIGEN"
   echo "Nombre del archivo final: $NOMBRE_ARCHIVO"
   echo "----------------------------------------"

   # 3. Preguntar confirmación al usuario
   read -p "¿Deseas proceder con la compresión? (s/n): " CONFIRMACION

   if [[ "$CONFIRMACION" == "s" || "$CONFIRMACION" == "S" ]]; then
     echo "📦 Empaquetando en proceso..."
     tar -czf "$NOMBRE_ARCHIVO" -C "$ORIGEN" . 2>/dev/null
     echo "✅ Archivo generado con éxito: $(ls -lh "$NOMBRE_ARCHIVO" | awk '{print $9, "(" $5 ")"}')"
   else
     echo "❌ Operación cancelada por el usuario."
   fi
   ```
3. Otorga permisos y pruébalo de dos maneras:
   ```bash
   chmod +x empaquetador.sh

   # Prueba 1: Sin argumentos (usará valores por defecto)
   ./empaquetador.sh

   # Prueba 2: Con argumentos personalizados
   ./empaquetador.sh /etc respaldo_etc.tar.gz
   ```

---

## 🧩 Checkpoint de Comprensión

> [!question]- Si invocas `./script.sh uno dos tres` y dentro tienes `shift`, ¿qué contendrá `$1`?
> El comando interno `shift` desplaza los argumentos a la izquierda: descarta el antiguo `$1` (`uno`), de modo que el nuevo `$1` pasa a ser `dos` y `$2` pasa a ser `tres`. Se usa frecuentemente en bucles para procesar banderas como `-h` o `--verbose`.

---

### 🚀 Siguiente Paso
Ahora que tus scripts reciben datos, es momento de aprender a tomar decisiones inteligentes evaluando códigos de salida y condiciones:
➡️ **[[05 - Códigos de Salida y Estructuras Condicionales|Módulo 5: Códigos de Salida y Estructuras Condicionales ➡️]]**
