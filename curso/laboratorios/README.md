# 🧪 Entorno de Laboratorio y Sandbox

Este directorio contiene datos y scripts diseñados específicamente para acompañar las prácticas del curso:

1. **[[ejercicio_debug.sh]]**:
   - Un script con **5 errores clásicos intencionales**.
   - Objetivo: Utiliza lo aprendido en el [[08 - Programación Defensiva y Debug|Módulo 8]] para ejecutar `bash -x ./ejercicio_debug.sh` o `shellcheck ./ejercicio_debug.sh` y reparar cada fallo.

2. **[[logs_simulados.log]]**:
   - Registro simulado de un servidor Linux con eventos `[INFO]`, `[WARN]`, `[ERROR]`, `[AUTH_FAIL]` y `[AUTH_OK]`.
   - Práctica sugerida:
     - Extraer todas las IPs atacantes con `grep "[AUTH_FAIL]" logs_simulados.log | awk '{print $NF}' | sort | uniq -c`.
     - Contar cuántos errores hubo en total.

3. **[[servidores_prueba.txt]]**:
   - Lista de destinos locales e internacionales para practicar el bucle `while IFS= read -r` del [[06 - Bucles y Automatización Masiva|Módulo 6]].
