#!/usr/bin/env bash
#
# escaner_red.sh - Escaneo de red + vulnerabilidades con reporte
# Para Linux Mint / Debian. Ejecutar como root: sudo ./escaner_red.sh
#

set -uo pipefail

# ============ CONFIGURACIÓN ============
# Deja SUBNET vacío para autodetectarla, o fíjala: "192.168.1.0/24"
SUBNET=""
# API key de Vulners (opcional pero recomendada). Vacío = se omite vulners.
VULNERS_API_KEY=""
# Directorio base de salida
OUTBASE="$HOME/escaneos"
# Timestamp para esta corrida
STAMP="$(date +%Y%m%d_%H%M%S)"
OUTDIR="$OUTBASE/scan_$STAMP"
# ======================================

# ---- Colores ----
C_OK="\033[1;32m"; C_INFO="\033[1;34m"; C_WARN="\033[1;33m"; C_ERR="\033[1;31m"; C_RST="\033[0m"
log()  { echo -e "${C_INFO}[*]${C_RST} $*"; }
ok()   { echo -e "${C_OK}[+]${C_RST} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RST} $*"; }
err()  { echo -e "${C_ERR}[x]${C_RST} $*"; }

# ---- Chequeos iniciales ----
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

# ---- Autodetección de subred ----
if [[ -z "$SUBNET" ]]; then
  IFACE="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "${IFACE:-}" ]]; then
    err "No detecté interfaz de red por defecto. Fija SUBNET manualmente."
    exit 1
  fi
  IP_CIDR="$(ip -4 -o addr show dev "$IFACE" | awk '{print $4; exit}')"
  SUBNET="$(python3 - <<PY
import ipaddress
print(ipaddress.ip_interface("$IP_CIDR").network)
PY
)"
  ok "Interfaz: $IFACE  ->  Subred detectada: $SUBNET"
else
  ok "Subred fijada manualmente: $SUBNET"
fi

# ---- Fase 1: Descubrimiento de hosts ----
log "Fase 1/3 - Descubriendo dispositivos activos en $SUBNET ..."
DISCOVERY="$OUTDIR/01_descubrimiento.txt"
# arp-scan es fiable en LAN; nmap -sn como respaldo
arp-scan --localnet > "$DISCOVERY" 2>/dev/null || true
nmap -sn "$SUBNET" -oG "$OUTDIR/.ping.gnmap" >/dev/null 2>&1 || true

# Extraer IPs activas (unión de arp-scan + nmap)
{
  awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' "$DISCOVERY" 2>/dev/null
  awk '/Status: Up/ {print $2}' "$OUTDIR/.ping.gnmap" 2>/dev/null
} | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n > "$OUTDIR/.hosts.txt"

HOSTCOUNT=$(wc -l < "$OUTDIR/.hosts.txt")
if [[ "$HOSTCOUNT" -eq 0 ]]; then
  warn "No se encontraron hosts activos. ¿Estás conectado a la red?"
  exit 0
fi
ok "Dispositivos activos encontrados: $HOSTCOUNT"

# ---- Fase 2: Escaneo de puertos y servicios ----
log "Fase 2/3 - Escaneando puertos y servicios (esto tarda)..."
PORTS_SCAN="$OUTDIR/02_puertos_servicios"
nmap -Pn -sS -sV -O --osscan-guess \
     -p- --min-rate 1000 \
     --script=banner \
     -iL "$OUTDIR/.hosts.txt" \
     -oA "$PORTS_SCAN" \
     --host-timeout 20m >/dev/null 2>&1

ok "Escaneo de puertos completado."

# ---- Fase 3: Escaneo de vulnerabilidades ----
log "Fase 3/3 - Analizando vulnerabilidades con NSE (vuln)..."
VULN_SCAN="$OUTDIR/03_vulnerabilidades"
NSE="vuln"
if [[ -n "$VULNERS_API_KEY" ]]; then
  NSE="vuln,vulners"
  ok "Incluyendo Vulners con API key."
else
  warn "Sin API key de Vulners (se omite ese set)."
fi

nmap -Pn -sV \
     --script="$NSE" \
     -p- --min-rate 1000 \
     -iL "$OUTDIR/.hosts.txt" \
     -oA "$VULN_SCAN" \
     --host-timeout 25m >/dev/null 2>&1

ok "Análisis de vulnerabilidades completado."

# ---- Reporte: parseo del XML ----
log "Generando reporte..."
REPORT_TXT="$OUTDIR/REPORTE.txt"
REPORT_HTML="$OUTDIR/REPORTE.html"

# Generar HTML con xsltproc desde el XML de puertos
xsltproc "$(command -v nmap | xargs dirname)/../share/nmap/nmap.xsl" \
  "$PORTS_SCAN.xml" > "$REPORT_HTML" 2>/dev/null || \
  nmap --stylesheet nmap.xsl -oX /dev/null "$PORTS_SCAN.xml" >/dev/null 2>&1 || true

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
except Exception as e:
    hosts = []

# Mapa de vulnerabilidades por IP:puerto
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
w(f"RESUMEN: {len(hosts)} hosts analizados | {total_open} puertos abiertos | {total_vulns} bloques de vulnerabilidades")
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
    # Vulnerabilidades asociadas a este host aunque no vinieran en el xml de puertos
    for (vaddr, vpid), outs in vulns.items():
        if vaddr == addr:
            already = any(p[0]==vpid for p in ports)
            if not already:
                w(f"  [{vpid}] (vuln) ")
                for o in outs:
                    for line in o.splitlines():
                        if line.strip():
                            w("          " + line.strip())
    w("")

w("="*70)
w("FIN DEL REPORTE")
w("="*70)

open(out_txt,"w").write("\n".join(lines))
print("\n".join(lines[:12]))
PY

# HTML de vulnerabilidades (además del de puertos)
cat > "$OUTDIR/REPORTE.html" <<HTML
<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<title>Reporte de escaneo $STAMP</title>
<style>
body{font-family:monospace;background:#111;color:#ddd;padding:20px}
h1{color:#4fc3f7} h2{color:#81c784;border-bottom:1px solid #333}
.port{color:#ffb74d} .vuln{color:#e57373;white-space:pre-wrap}
pre{background:#1a1a1a;padding:10px;border-radius:6px;overflow-x:auto}
</style></head><body>
<h1>Reporte de escaneo de red</h1>
<p>Subred: <b>$SUBNET</b> | Fecha: $STAMP | Hosts: $HOSTCOUNT</p>
<h2>Detalle completo</h2>
<pre>$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$REPORT_TXT")</pre>
</body></html>
HTML

# ---- Limpieza y salida ----
rm -f "$OUTDIR/.ping.gnmap"

ok "Listo."
echo
echo -e "${C_OK}Reporte de texto :${C_RST} $REPORT_TXT"
echo -e "${C_OK}Reporte HTML     :${C_RST} $REPORT_HTML"
echo -e "${C_OK}Artefactos nmap  :${C_RST} $PORTS_SCAN.{xml,nmap,gnmap}"
echo -e "                   $VULN_SCAN.{xml,nmap,gnmap}"
echo
echo "Abre el HTML con:  xdg-open \"$REPORT_HTML\""
