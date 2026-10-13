#!/usr/bin/env bash
# ==============================================================================
# 🛠️ ESQUELETO DE CONSTRUCCIÓN: PROYECTO FINAL - ESCÁNER DE RED
# ==============================================================================
# Instrucciones:
# Sigue la 'GUIA_CONSTRUCCION.md' para ir desbloqueando y completando cada
# bloque con lo aprendido en el curso. Al terminar, tendrás tu propio sondeo.sh
# construido con tus propias manos.
#
# Para ejecutar tus pruebas conforme avances:
#   sudo ./esqueleto_starter.sh
# ==============================================================================

# ==============================================================================
# BLOQUE 1: MODO ESTRICTO, CONFIGURACIÓN Y CHEQUEOS INICIALES
# ==============================================================================
# TODO 1.1: Activa el modo estricto de Bash (nounset y pipefail)
# Pista (Módulo 8): set -uo pipefail
set -uo pipefail

# TODO 1.2: Variables de configuración
SUBNET=""
VULNERS_API_KEY=""
OUTBASE="$HOME/escaneos"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUTDIR="$OUTBASE/scan_$STAMP"

# TODO 1.3: Paleta de colores ANSI y funciones de logging (Módulo 7)
C_OK="\033[1;32m"; C_INFO="\033[1;34m"; C_WARN="\033[1;33m"; C_ERR="\033[1;31m"; C_RST="\033[0m"
log()  { echo -e "${C_INFO}[*]${C_RST} $*"; }
ok()   { echo -e "${C_OK}[+]${C_RST} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RST} $*"; }
err()  { echo -e "${C_ERR}[x]${C_RST} $*"; }

# TODO 1.4: Verificar privilegios de root ($EUID) (Módulo 3 y 5)
if [[ $EUID -ne 0 ]]; then
  err "Ejecuta como root: sudo $0"
  exit 1
fi

# TODO 1.5: Comprobar binarios necesarios (nmap, arp-scan, xsltproc, python3) (Módulo 3 y 6)
for bin in nmap arp-scan xsltproc python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    err "Falta la herramienta '$bin'. Instala con: sudo apt install -y nmap arp-scan xsltproc python3"
    exit 1
  fi
done

# TODO 1.6: Crear carpeta de salida
mkdir -p "$OUTDIR" || { err "No pude crear el directorio $OUTDIR"; exit 1; }
ok "Directorio de trabajo preparado: $OUTDIR"


# ==============================================================================
# BLOQUE 2: AUTODETECCIÓN DE SUBRED (BASH + PYTHON)
# ==============================================================================
log "Detectando interfaz y subred..."

if [[ -z "$SUBNET" ]]; then
  # TODO 2.1: Detectar interfaz activa con 'ip route' y 'awk' (Módulo 2)
  IFACE="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "${IFACE:-}" ]]; then
    err "No detecté interfaz de red por defecto. Fija SUBNET manualmente."
    exit 1
  fi

  # TODO 2.2: Obtener IP con máscara CIDR
  IP_CIDR="$(ip -4 -o addr show dev "$IFACE" | awk '{print $4; exit}')"

  # TODO 2.3: Calcular subred base con Python embebido mediante Here-Doc (Módulo 4)
  SUBNET="$(python3 - <<PY
import ipaddress
print(ipaddress.ip_interface("$IP_CIDR").network)
PY
)"
  ok "Interfaz: $IFACE  ->  Subred detectada: $SUBNET"
else
  ok "Subred configurada manualmente: $SUBNET"
fi


# ==============================================================================
# BLOQUE 3: DESCUBRIMIENTO DE HOSTS Y TUBERÍAS DE FILTRADO
# ==============================================================================
log "Fase 1/3 - Descubriendo dispositivos activos en $SUBNET ..."
DISCOVERY="$OUTDIR/01_descubrimiento.txt"

# TODO 3.1: Descubrimiento Capa 2 (arp-scan) y Capa 3 (nmap -sn) (Módulo 5)
arp-scan --localnet > "$DISCOVERY" 2>/dev/null || true
nmap -sn "$SUBNET" -oG "$OUTDIR/.ping.gnmap" >/dev/null 2>&1 || true

# TODO 3.2: Tubería UNIX para extraer IPs, deduplicar y ordenar por octetos
{
  awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' "$DISCOVERY" 2>/dev/null
  awk '/Status: Up/ {print $2}' "$OUTDIR/.ping.gnmap" 2>/dev/null
} | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n > "$OUTDIR/.hosts.txt"

# TODO 3.3: Contar hosts descubiertos con redirección de entrada '<'
HOSTCOUNT=$(wc -l < "$OUTDIR/.hosts.txt")
if [[ "$HOSTCOUNT" -eq 0 ]]; then
  warn "No se encontraron hosts activos. ¿Estás conectado a la red?"
  exit 0
fi
ok "Dispositivos activos encontrados: $HOSTCOUNT"


# ==============================================================================
# BLOQUE 4: ESCANEO DE PUERTOS, SERVICIOS Y SISTEMA OPERATIVO
# ==============================================================================
log "Fase 2/3 - Escaneando puertos y servicios (esto puede tardar)..."
PORTS_SCAN="$OUTDIR/02_puertos_servicios"

# TODO 4.1: Ejecutar escaneo exhaustivo de Nmap leyendo de -iL .hosts.txt
nmap -Pn -sS -sV -O --osscan-guess \
     -p- --min-rate 1000 \
     --script=banner \
     -iL "$OUTDIR/.hosts.txt" \
     -oA "$PORTS_SCAN" \
     --host-timeout 20m >/dev/null 2>&1

ok "Escaneo de puertos completado."


# ==============================================================================
# BLOQUE 5: AUDITORÍA DE VULNERABILIDADES CON NSE
# ==============================================================================
log "Fase 3/3 - Analizando vulnerabilidades con Nmap Scripting Engine (vuln)..."
VULN_SCAN="$OUTDIR/03_vulnerabilidades"
NSE="vuln"

if [[ -n "$VULNERS_API_KEY" ]]; then
  NSE="vuln,vulners"
  ok "Incluyendo Vulners con API key."
else
  warn "Sin API key de Vulners (se omite ese set)."
fi

# TODO 5.1: Ejecutar auditoría NSE con Nmap
nmap -Pn -sV \
     --script="$NSE" \
     -p- --min-rate 1000 \
     -iL "$OUTDIR/.hosts.txt" \
     -oA "$VULN_SCAN" \
     --host-timeout 25m >/dev/null 2>&1

ok "Análisis de vulnerabilidades completado."


# ==============================================================================
# BLOQUE 6: PARSING DE XML Y GENERACIÓN DE REPORTES (TXT Y HTML)
# ==============================================================================
log "Generando reportes consolidados..."
REPORT_TXT="$OUTDIR/REPORTE.txt"
REPORT_HTML="$OUTDIR/REPORTE.html"

# TODO 6.1: Parsear los XML con Python embebido (ElementTree) (Módulo 7)
python3 - "$PORTS_SCAN.xml" "$VULN_SCAN.xml" "$REPORT_TXT" "$SUBNET" "$HOSTCOUNT" <<'PY'
import sys, xml.etree.ElementTree as ET
from datetime import datetime

ports_xml, vuln_xml, out_txt, subnet, hostcount = sys.argv[1:6]

def parse(xmlfile):
    tree = ET.parse(xmlfile)
    root = tree.getroot()
    hosts = []
    for h in root.findall("host"):
        if h.find("status").get("state") != "up":
            continue
        addr = h.find("address").get("addr")
        hostname = ""
        hn = h.find("hostnames/hostname")
        if hn is not None:
            hostname = hn.get("name","")
        ports = []
        for p in h.findall("ports/port"):
            state = p.find("state").get("state")
            if state != "open":
                continue
            svc = p.find("service")
            name = svc.get("name","?") if svc is not None else "?"
            prod = (svc.get("product","") if svc is not None else "")
            ver  = (svc.get("version","") if svc is not None else "")
            scripts = []
            for s in p.findall("script"):
                scripts.append((s.get("id"), s.get("output","")))
            ports.append((p.get("portid"), p.get("protocol"), name, prod, ver, scripts))
        hosts.append((addr, hostname, ports))
    return hosts

try:
    hosts = parse(ports_xml)
except Exception:
    hosts = []

vulns = {}
try:
    vroot = ET.parse(vuln_xml).getroot()
    for h in vroot.findall("host"):
        addr = h.find("address").get("addr")
        for p in h.findall("ports/port"):
            pid = p.get("portid")
            for s in p.findall("script"):
                if s.get("id") in ("vuln","vulners"):
                    vulns.setdefault((addr,pid), []).append(s.get("output",""))
except Exception:
    pass

lines = []
w = lines.append
w("="*70)
w("  REPORTE DE ESCANEO DE RED Y VULNERABILIDADES")
w("="*70)
w(f"Fecha       : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
w(f"Subred      : {subnet}")
w(f"Dispositivos: {hostcount}")
w("="*70)
w("")

total_open = sum(len(h[2]) for h in hosts)
total_vulns = sum(len(v) for v in vulns.values())
w(f"RESUMEN: {len(hosts)} hosts analizados | {total_open} puertos abiertos | {total_vulns} vulnerabilidades detectadas")
w("")

for addr, hostname, ports in hosts:
    w("-"*70)
    title = f"HOST: {addr}"
    if hostname:
        title += f"  ({hostname})"
    w(title)
    w("-"*70)
    if not ports:
        w("  Sin puertos abiertos detectados.")
    for pid, proto, name, prod, ver, scripts in ports:
        w(f"  [{proto}/{pid}] {name} {prod} {ver}".rstrip())
        for sid, sout in scripts:
            if sid in ("vuln","vulners"):
                w("      >>> VULNERABILIDADES:")
                for line in sout.splitlines():
                    if line.strip():
                        w("          " + line.strip())
    w("")

w("="*70)
w("FIN DEL REPORTE")
w("="*70)

open(out_txt,"w").write("\n".join(lines))
PY

# TODO 6.2: Generar reporte HTML oscuro con Here-Doc y sanitización con sed
cat > "$REPORT_HTML" <<HTML
<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<title>Reporte de escaneo $STAMP</title>
<style>
body{font-family:monospace;background:#111;color:#ddd;padding:20px}
h1{color:#4fc3f7} h2{color:#81c784;border-bottom:1px solid #333}
pre{background:#1a1a1a;padding:10px;border-radius:6px;overflow-x:auto}
</style></head><body>
<h1>Reporte de escaneo de red</h1>
<p>Subred: <b>$SUBNET</b> | Fecha: $STAMP | Hosts: $HOSTCOUNT</p>
<h2>Detalle completo</h2>
<pre>$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$REPORT_TXT")</pre>
</body></html>
HTML

# Limpiar archivos temporales intermedios
rm -f "$OUTDIR/.ping.gnmap"

ok "¡Escaneo completado exitosamente!"
echo ""
echo -e "${C_OK}Reporte de texto :${C_RST} $REPORT_TXT"
echo -e "${C_OK}Reporte HTML     :${C_RST} $REPORT_HTML"
echo ""
echo "Visualiza el reporte con: xdg-open \"$REPORT_HTML\""
