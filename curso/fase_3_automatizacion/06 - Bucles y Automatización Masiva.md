---
tags:
  - curso/modulo06
  - bash/bucles
  - automatizacion
  - for
  - while
modulo: 6
tiempo_estimado: 25 min
---

# 🔄 Módulo 6: Bucles y Automatización Masiva

[[05 - Códigos de Salida y Estructuras Condicionales|⬅️ Módulo Anterior]] • [[00 - MOC - Fundamentos de Shell Scripting|🏠 Inicio (MOC)]] • [[07 - Funciones y Modularidad Limpia|Siguiente Módulo ➡️]]

---

## 🎯 Objetivo de este Módulo
Liberarte del trabajo repetitivo. Aprenderás a dominar los bucles `for` y `while`, la técnica estándar de la industria para procesar archivos línea por línea de forma segura (`IFS= read -r`) y cómo controlar el flujo con `break` y `continue`.

---

## 1. El Bucle `for`: Cuando conoces los elementos

El bucle `for` itera sobre una lista de elementos conocidos:

### A. Sobre una lista de palabras explícitas
```bash
for servicio in nginx mysql ssh docker; do
  echo "Verificando el estado del servicio: $servicio"
done
```

### B. Sobre rangos numéricos con `{inicio..fin..paso}`
```bash
# Del 1 al 5
for i in {1..5}; do
  echo "Intento número $i"
done

# De 0 a 10 de 2 en 2 (0, 2, 4, 6, 8, 10)
for num in {0..10..2}; do
  echo "Paso par: $num"
done
```

### C. Sobre archivos mediante comodines (Globbing)
```bash
for archivo in /var/log/*.log; do
  # Comprobar si el archivo realmente existe (evita errores si no hay coincidencias)
  [[ -e "$archivo" ]] || continue
  echo "Procesando archivo de registro: $archivo"
done
```

---

## 2. El Bucle `while`: Mientras la condición sea Verdadera

El bucle `while` sigue repitiéndose mientras la condición evaluada devuelva código de salida `0`:

```bash
CONTADOR=1
while [[ $CONTADOR -le 5 ]]; do
  echo "Contando: $CONTADOR"
  CONTADOR=$(( CONTADOR + 1 ))
  sleep 0.5  # Pausa de medio segundo
done
```

---

## 3. La Forma Sagrada de Leer Archivos Línea por Línea

> [!warning] El Antipatrón Peligroso: `for linea in $(cat archivo)`
> Muchos principiantes escriben:
> ```bash
> # ❌ NUNCA HAGAS ESTO:
> for linea in $(cat archivo.txt); do
>   echo "$linea"
> done
> ```
> **¿Por qué está mal?** Porque Bash dividirá el texto por **cada espacio en blanco**, no por saltos de línea. Si una línea dice `Hola Mundo`, el bucle se ejecutará dos veces (`Hola` y luego `Mundo`), destrozando el formato.

### ✅ La Forma Profesional y Segura: `while IFS= read -r`

```bash
while IFS= read -r linea; do
  echo "Línea leída: $linea"
done < "archivo.txt"
```

Desglosemos cada parte de esta estructura de oro:
1. **`while read`:** Lee una línea completa hasta encontrar un salto de línea (`\n`).
2. **`IFS=` (Internal Field Separator vacío):** Impide que Bash elimine los espacios en blanco o tabulaciones al inicio o final de cada línea.
3. **`-r` (Raw input):** Evita que las barras invertidas `\` se interpreten como caracteres de escape (por ejemplo, `\n` se lee como texto literal).
4. **`< "archivo.txt"`:** Alimenta el bucle directamente redirigiendo el archivo hacia el descriptor de entrada.

---

## 4. Control de Saltos: `break` y `continue`

- **`break`:** Detiene y sale inmediatamente del bucle.
  ```bash
  for ip in 192.168.1.{1..50}; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
      echo "¡Encontré un equipo activo en $ip! Deteniendo búsqueda."
      break
    fi
  done
  ```
- **`continue`:** Salta el resto del código de la iteración actual y pasa de inmediato a la siguiente.

---

## 🧪 Laboratorio Práctico 6: Procesador de Tareas por Lotes

Vamos a crear una utilidad que lea una lista de tareas desde un archivo y las ejecute una por una simulando un gestor de trabajos:

1. Crea un archivo con nombres de servidores a auditar:
   ```bash
   cat <<EOF > servidores.txt
   google.com
   github.com
   servidor_falso_que_no_existe.xyz
   cloudflare.com
   EOF
   ```
2. Crea el script de procesamiento:
   ```bash
   nano verificador_red.sh
   ```
3. Pega este código:
   ```bash
   #!/usr/bin/env bash

   LISTA="servidores.txt"

   if [[ ! -f "$LISTA" ]]; then
     echo "❌ Error: No se encuentra el archivo $LISTA"
     exit 1
   fi

   TOTAL=0
   EXITOSOS=0

   echo "=== AUDITORÍA MASIVA DE CONECTIVIDAD ==="

   while IFS= read -r servidor || [[ -n "$servidor" ]]; do
     # Ignorar líneas vacías o comentarios que empiecen con #
     [[ -z "$servidor" || "$servidor" =~ ^# ]] && continue

     TOTAL=$(( TOTAL + 1 ))
     echo -n "Probando enlace con '$servidor'... "

     if ping -c 1 -W 2 "$servidor" >/dev/null 2>&1; then
       echo "🟢 ONLINE"
       EXITOSOS=$(( EXITOSOS + 1 ))
     else
       echo "🔴 INACCESIBLE"
     fi
   done < "$LISTA"

   echo "----------------------------------------"
   echo "Resumen: $EXITOSOS de $TOTAL servidores respondieron correctamente."
   ```
4. Otorga permisos y pruébalo:
   ```bash
   chmod +x verificador_red.sh
   ./verificador_red.sh
   ```

---

## 🧩 Checkpoint de Comprensión

> [!question]- ¿Por qué agregamos `|| [[ -n "$servidor" ]]` en la condición del `while read`?
> Muchos editores de texto no añaden un salto de línea (`\n`) en la última línea de un archivo. Sin esa comprobación, el comando `read` devolvería código de salida 1 en la última línea y el bucle terminaría sin procesar el último servidor. Esa condición asegura que se procese hasta el último dato.

---

### 🚀 Siguiente Paso
Ahora que sabes cómo repetir tareas, aprenderás a organizar tu código en funciones limpias, reusables y con ámbito local seguro:
➡️ **[[07 - Funciones y Modularidad Limpia|Módulo 7: Funciones y Modularidad Limpia ➡️]]**
