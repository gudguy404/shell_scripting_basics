---
tags:
  - curso/modulo05
  - bash/condicionales
  - codigos_de_salida
  - operadores_logicos
modulo: 5
tiempo_estimado: 25 min
---

# ⚖️ Módulo 5: Códigos de Salida y Estructuras Condicionales

[[04 - Parámetros Posicionales y Argumentos|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[06 - Bucles y Automatización Masiva|Siguiente Módulo ➡️]]

---

## 🎯 Objetivo de este Módulo
Entender cómo piensa Linux para tomar decisiones. Descubrirás el choque cultural del código de salida (`$?`), la diferencia entre comparadores numéricos y de texto, las pruebas sobre archivos y cómo estructurar bloques `if/elif/else` limpios.

---

## 1. El Gran Choque Cultural: ¿Qué es la Verdad en UNIX?

En casi todos los lenguajes de programación (Python, JavaScript, C), el número `0` significa *Falso* (`False`) y `1` significa *Verdadero* (`True`).

> [!warning] La Lógica Invertida de Linux
> En los sistemas UNIX y en Bash ocurre exactamente lo contrario:
> - **`0` = ÉXITO / VERDADERO (`True`)**
> - **`1 al 255` = ERROR / FALLO / FALSO (`False`)**

### ¿Por qué se diseñó así?
Porque **solo hay una forma de que una tarea salga bien** (`0 = Sin errores`), pero existen **cientos de razones para fallar**:
- `1` = Error general.
- `2` = Error de sintaxis en el comando.
- `126` = Comando encontrado pero sin permiso de ejecución.
- `127` = Comando no encontrado.
- `130` = Programa interrumpido manualmente con `Ctrl + C`.

La variable mágica **`$?`** almacena el código de salida del último comando ejecutado:
```bash
ls /etc >/dev/null 2>&1
echo $?   # Imprime 0 (éxito total)

ls /no_existe >/dev/null 2>&1
echo $?   # Imprime 2 (error)
```

---

## 2. Operadores de Cortocircuito: `&&` y `||`

Puedes encadenar acciones rápidas sin necesidad de escribir un `if` completo:

- **`ComandoA && ComandoB` (AND):** Ejecuta B **solo si** A terminó con éxito (`$? == 0`).
  ```bash
  mkdir /tmp/respaldo && echo "Carpeta creada con éxito"
  ```
- **`ComandoA || ComandoB` (OR):** Ejecuta B **solo si** A falló (`$? != 0`).
  ```bash
  cd /carpeta_critica || { echo "No puedo entrar"; exit 1; }
  ```

---

## 3. El Evaluador Moderno: `[[ condición ]]`

Para evaluar condiciones en Bash moderno se utilizan **dobles corchetes `[[ ... ]]`**.

> [!tip] Siempre deja espacios dentro de los corchetes
> `[[ $X == 5 ]]` es correcto. `[[$X == 5]]` fallará porque Bash necesita ver `[[` y `]]` como palabras separadas.

### A. Pruebas sobre el Sistema de Archivos

| Operador | Significado | Ejemplo |
| :---: | :--- | :--- |
| **`-f`** | Es un archivo regular y existe | `[[ -f "/etc/hosts" ]]` |
| **`-d`** | Es un directorio y existe | `[[ -d "$HOME/Documentos" ]]` |
| **`-e`** | Existe (sea archivo, carpeta o socket) | `[[ -e "/dev/null" ]]` |
| **`-s`** | Existe y **no está vacío** (tamaño > 0) | `[[ -s "reporte.txt" ]]` |
| **`-r` / `-w` / `-x`** | Tiene permiso de lectura / escritura / ejecución | `[[ -x "script.sh" ]]` |

### B. Comparación de Texto (Strings)

| Operador | Significado | Ejemplo |
| :---: | :--- | :--- |
| **`==`** | Es idéntico | `[[ "$RESPUESTA" == "si" ]]` |
| **`!=`** | Es diferente | `[[ "$USER" != "root" ]]` |
| **`-z`** | La cadena está **vacía** (*zero length*) | `[[ -z "$SUBNET" ]]` |
| **`-n`** | La cadena **NO está vacía** | `[[ -n "$TOKEN" ]]` |
| **`=~`** | Coincide con una **Expresión Regular** | `[[ "$IP" =~ ^[0-9]+\.[0-9]+ ]]` |

### C. Comparación de Números (Aritmética)

> [!warning] ¡Cuidado con `<` y `>`!
> Si usas `<` o `>` dentro de `[[ ... ]]`, Bash comparará alfabéticamente (ej. dirá que `"10"` es menor que `"2"`). Para números enteros debes usar los operadores mnemotécnicos:

| Operador | Significado en Inglés | Equivalente Matemático |
| :---: | :--- | :---: |
| **`-eq`** | *Equal* | `==` |
| **`-ne`** | *Not Equal* | `!=` |
| **`-gt`** | *Greater Than* | `>` |
| **`-ge`** | *Greater or Equal* | `>=` |
| **`-lt`** | *Less Than* | `<` |
| **`-le`** | *Less or Equal* | `<=` |

---

## 4. Estructura `if / elif / else / fi`

Observa la sintaxis completa y limpia:

```bash
if [[ $EUID -eq 0 ]]; then
  echo "Eres el superusuario root."
elif [[ "$USER" == "admin" ]]; then
  echo "Eres el usuario administrativo común."
else
  echo "Eres un usuario estándar ($USER)."
fi
```
*(Recuerda que todo bloque condicional en Bash se cierra con `fi`, que es `if` escrito al revés).*

---

## 🧪 Laboratorio Práctico 5: El Guardián del Servidor

Vamos a crear un script centinela que verifique si el usuario tiene permisos, si existe espacio en disco y si un archivo crítico está intacto:

1. Crea el archivo:
   ```bash
   nano centinela_sistema.sh
   ```
2. Escribe este código:
   ```bash
   #!/usr/bin/env bash

   echo "=== INICIANDO CHEQUEO DE INTEGRIDAD ==="

   # 1. Chequeo de usuario
   if [[ $EUID -ne 0 ]]; then
     echo "ℹ️ Aviso: Se recomienda ejecutar con privilegios root para ver todo."
   fi

   # 2. Chequeo de archivo crítico
   ARCHIVO_OBJETIVO="/etc/resolv.conf"
   if [[ -f "$ARCHIVO_OBJETIVO" && -r "$ARCHIVO_OBJETIVO" ]]; then
     echo "✅ Archivo DNS ($ARCHIVO_OBJETIVO) existe y es legible."
   else
     echo "❌ ERROR: No se puede leer el archivo de configuración DNS."
     exit 1
   fi

   # 3. Chequeo de porcentaje de disco ocupado en /
   USO_DISCO=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

   echo "Uso actual del disco raíz: ${USO_DISCO}%"

   if [[ "$USO_DISCO" -ge 90 ]]; then
     echo "🚨 PELIGRO CRÍTICO: El disco está por encima del 90% de capacidad."
   elif [[ "$USO_DISCO" -ge 70 ]]; then
     echo "⚠️ ADVERTENCIA: El disco supera el 70% de ocupación."
   else
     echo "🟢 ESTADO ÓPTIMO: Espacio de almacenamiento saludable."
   fi
   ```
3. Otorga permisos y ejecútalo:
   ```bash
   chmod +x centinela_sistema.sh
   ./centinela_sistema.sh
   ```

---

## 🧩 Checkpoint de Comprensión

> [!question]- ¿Qué significa la expresión `[[ -z "${TOKEN:-}" ]]` y por qué tiene `:-`?
> `-z` comprueba si la variable está vacía. La sintaxis `${TOKEN:-}` asegura que si la variable `TOKEN` no fue declarada en absoluto y el script tiene activado `set -u` (modo estricto), Bash no aborte con un error fatal por variable inexistente, devolviendo una cadena vacía segura para la comparación.

---

### 🚀 Siguiente Paso
Una vez dominadas las condiciones, es hora de poner a la máquina a trabajar en tareas repetitivas mediante bucles:
➡️ **[[06 - Bucles y Automatización Masiva|Módulo 6: Bucles y Automatización Masiva ➡️]]**
