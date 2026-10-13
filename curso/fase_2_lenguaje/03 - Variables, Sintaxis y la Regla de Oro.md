---
tags:
  - curso/modulo03
  - bash/variables
  - bash/sintaxis
  - bash/comillas
  - aritmetica
modulo: 3
tiempo_estimado: 20 min
---

# 📝 Módulo 3: Variables, Sintaxis y la Regla de Oro

[[02 - El Flujo de Datos UNIX y Redirecciones|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[04 - Parámetros Posicionales y Argumentos|Siguiente Módulo ➡️]]

---

## 🎯 Objetivo de este Módulo
Comprender cómo almacena y manipula datos Bash. Dominarás la regla de oro del espacio en blanco, el comportamiento exacto de las comillas simples vs dobles, cómo capturar la salida de comandos en variables y cómo realizar operaciones matemáticas.

---

## 1. Todo en Bash es Texto (Strings)

A diferencia de Python o Java, donde defines enteros (`int`), flotantes (`float`) o booleanos (`bool`), en Bash **todo dato es fundamentalmente una cadena de caracteres**. Bash solo interpreta una variable como número cuando se lo pides explícitamente dentro de una expresión aritmética.

---

## 2. La Regla de Oro del Espacio en Blanco

En Bash, el espacio en blanco es el delimitador oficial de comandos y argumentos. Por tanto:

```bash
# ❌ ERROR FATAL:
NOMBRE = "Carlos"
# ¿Por qué falla? Bash cree que 'NOMBRE' es un comando que quieres ejecutar,
# y que '=' y '"Carlos"' son dos argumentos pasados a ese comando.
# Salida de error: 'NOMBRE: orden no encontrada'

# ✅ CORRECTO: Sin espacios antes ni después del signo '='
NOMBRE="Carlos"
```

> [!warning] Grábate esta regla en la memoria
> **En la asignación de variables en Bash no debe existir ningún espacio alrededor del signo igual (`=`).**

---

## 3. La Trinidad de las Comillas

El 80% de los errores misteriosos en scripts de principiantes se deben a un mal uso de las comillas. Comparemos los tres casos:

```bash
CIUDAD="Buenos Aires"
```

### Caso A: Comillas Dobles (`"..."`) — *Permite Expansión*
Permite que Bash reemplace `$CIUDAD` por su contenido, pero mantiene el valor unido como un solo argumento aunque contenga espacios:
```bash
echo "Vivo en $CIUDAD"
# Salida: Vivo en Buenos Aires
```

### Caso B: Comillas Simples (`'...'`) — *Texto Literal Puro*
Desactiva cualquier interpretación especial. Lo que ves es lo que obtienes:
```bash
echo 'Vivo en $CIUDAD'
# Salida: Vivo en $CIUDAD
```

### Caso C: Sin Comillas — *El Peligro del Word Splitting*
Si escribes:
```bash
mkdir $CIUDAD
```
Bash divide la variable por los espacios en blanco (*word splitting*) y ejecutará `mkdir Buenos Aires`, **creando dos carpetas distintas** (`Buenos` y `Aires`).  
Con comillas dobles:
```bash
mkdir "$CIUDAD"
```
Crea una única carpeta llamada `Buenos Aires`.

> [!tip] Regla de Oro del Scripter
> **Siempre envuelve tus variables en comillas dobles: `"$VARIABLE"`.**

---

## 4. Sustitución de Comandos: `$(comando)`

¿Cómo guardamos el resultado de un programa en una variable para usarlo más tarde? Con la sintaxis **`$(...)`**:

```bash
FECHA_ACTUAL="$(date +%Y-%m-%d)"
ESPACIO_DISCO="$(df -h / | awk 'NR==2 {print $5}')"

echo "Hoy es $FECHA_ACTUAL y la raíz está al $ESPACIO_DISCO de uso."
```

*(Nota histórica: En scripts antiguos verás comillas invertidas como \`date\`. Evítalas: la sintaxis moderna `$(...)` es mucho más legible y permite anidar comandos como `$(cat $(find . -name "*.txt"))`).*

---

## 5. Aritmética en Bash: `$(( expresión ))`

Para sumar, restar, multiplicar o dividir números enteros, se utiliza la doble paréntesis:

```bash
A=15
B=4

SUMA=$(( A + B ))       # 19
RESTA=$(( A - B ))      # 11
MULTIPLICACION=$(( A * B )) # 60
DIVISION_ENTERA=$(( A / B )) # 3 (Bash solo maneja enteros)
RESTO_MODULO=$(( A % B ))    # 3
```

> [!info] Operaciones con Decimales
> Si necesitas decimales (ej. `3.75`), Bash no puede calcularlo directamente. Se utiliza la calculadora de Linux `bc`:
> ```bash
> RESULTADO=$(echo "scale=2; 15 / 4" | bc)  # Devuelve 3.75
> ```

---

## 🧪 Laboratorio Práctico 3: Calculador de Respaldo Dinámico

Vamos a crear un script que calcule el espacio ocupado por tus documentos y genere un nombre de archivo único para un backup.

1. Crea el archivo:
   ```bash
   nano calculo_backup.sh
   ```
2. Escribe este código:
   ```bash
   #!/usr/bin/env bash

   # 1. Variables de configuración
   CARPETA_ORIGEN="$HOME"
   FECHA_STAMP="$(date +%Y%m%d_%H%M%S)"
   NOMBRE_BACKUP="backup_${USER}_${FECHA_STAMP}.tar.gz"

   echo "=== GENERADOR DE ARCHIVO DE RESPALDO ==="
   echo "Usuario             : $USER"
   echo "Carpeta analizada   : $CARPETA_ORIGEN"
   echo "Nombre generado     : $NOMBRE_BACKUP"

   # 2. Aritmética de prueba
   MINUTOS_ESPERA=120
   HORAS=$(( MINUTOS_ESPERA / 60 ))
   echo "Frecuencia de respaldo: cada $MINUTOS_ESPERA minutos ($HORAS horas)."

   # 3. Guardar simulación en archivo
   echo "$NOMBRE_BACKUP" > ultimo_backup.log
   echo "✅ Registro guardado en 'ultimo_backup.log'."
   ```
3. Otorga permisos y ejecútalo:
   ```bash
   chmod +x calculo_backup.sh
   ./calculo_backup.sh
   ```

---

## 🧩 Checkpoint de Comprensión

> [!question]- ¿Qué imprimirá exactamente el comando `X=10; echo '$(( X + 5 ))'`?
> Imprimirá textualmente `$(( X + 5 ))`. Como usamos comillas simples `'...'`, Bash no evalúa ni la variable ni la expresión aritmética; lo trata como una cadena estática. Para que calcule `15`, debe ir con comillas dobles o sin comillas: `echo "$(( X + 5 ))"`.

---

### 🚀 Siguiente Paso
Ahora que dominas las variables fijas, aprenderás a hacer que tus scripts reciban argumentos externos al invocarse desde la terminal:
➡️ **[[04 - Parámetros Posicionales y Argumentos|Módulo 4: Parámetros Posicionales y Argumentos ➡️]]**
