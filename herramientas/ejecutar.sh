#!/usr/bin/env bash
# =====================================================================
# ejecutar.sh - Ejecuta un script .sql dentro del contenedor Oracle y
#               guarda la salida como evidencia.
#
# Uso:  herramientas/ejecutar.sh <modo> <script.sql> [nombre-evidencia]
#
#   modo:
#     system       SYSTEM conectado por TCP al PDB FREEPDB1
#     sysdba-pdb   SYS AS SYSDBA (autenticación del SO) dentro de FREEPDB1
#     sysdba-root  SYS AS SYSDBA en CDB$ROOT (solo para el keystore TDE)
#     ninguno      el script hace sus propios CONNECT (pruebas por usuario)
#
# Las contraseñas se leen de .secrets/lab_defines.sql (no versionado) y
# nunca se imprimen: los scripts usan variables de sustitución
# (&&pwd_juan, ...) con SET VERIFY OFF.
# =====================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
CONTENEDOR="${CONTENEDOR:-iso27001-oracle}"
MODO="${1:?Falta el modo (system|sysdba-pdb|sysdba-root|ninguno)}"
SCRIPT="${2:?Falta la ruta del script .sql}"
EVIDENCIA="${3:-}"

[ -f "$RAIZ/.secrets/lab_defines.sql" ] || { echo "No existe .secrets/lab_defines.sql"; exit 1; }
[ -f "$SCRIPT" ] || { echo "No existe $SCRIPT"; exit 1; }

# Copiar la carpeta sql/ al contenedor (permite @@ relativos)
# (en Git Bash de Windows, docker cp necesita rutas de Windows)
if command -v cygpath >/dev/null 2>&1; then RAIZ_HOST="$(cygpath -w "$RAIZ")"; else RAIZ_HOST="$RAIZ"; fi
docker exec -u root "$CONTENEDOR" rm -rf /tmp/lab
docker cp "$RAIZ_HOST/sql" "$CONTENEDOR:/tmp/lab" >/dev/null
docker cp "$RAIZ_HOST/.secrets/lab_defines.sql" "$CONTENEDOR:/tmp/lab/defines.sql" >/dev/null
REL="${SCRIPT#*sql/}"

case "$MODO" in
  system)      CONEXION='CONNECT system/"&&pwd_system"@&&srv' ;;
  sysdba-pdb)  CONEXION=$'CONNECT / AS SYSDBA\nALTER SESSION SET CONTAINER = FREEPDB1;' ;;
  sysdba-root) CONEXION='CONNECT / AS SYSDBA' ;;
  ninguno)     CONEXION='' ;;
  *) echo "Modo desconocido: $MODO"; exit 1 ;;
esac

ENTRADA=$(printf '@/tmp/lab/defines.sql\n%s\n@/tmp/lab/formato.sql\nSET ECHO ON FEEDBACK ON\n@/tmp/lab/%s\nEXIT\n' "$CONEXION" "$REL")

# NLS_LANG en UTF-8 para que las tildes de comentarios y textos no se conviertan en "?"
ejecutar() { printf '%s\n' "$ENTRADA" | docker exec -i -e NLS_LANG=AMERICAN_AMERICA.AL32UTF8 "$CONTENEDOR" sqlplus -S -L /nolog; }

if [ -n "$EVIDENCIA" ]; then
  mkdir -p "$RAIZ/evidencias"
  SALIDA="$RAIZ/evidencias/$EVIDENCIA.txt"
  {
    echo "== Evidencia: $EVIDENCIA"
    echo "== Script   : sql/$REL"
    echo "== Modo     : $MODO"
    echo "== Fecha    : $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "== Motor    : contenedor $CONTENEDOR"
    echo "====================================================================="
    ejecutar
  } > "$SALIDA" 2>&1
  # Defensa: verificar que ninguna contraseña quedó en la evidencia
  if grep -qF -f <(sed -n 's/^DEFINE pwd_[a-z_]* = "\(.*\)"$/\1/p' "$RAIZ/.secrets/lab_defines.sql") "$SALIDA"; then
    echo "ALERTA: la evidencia contiene una contraseña; se elimina $SALIDA"; rm -f "$SALIDA"; exit 2
  fi
  echo "Evidencia guardada en evidencias/$EVIDENCIA.txt"
else
  ejecutar
fi
