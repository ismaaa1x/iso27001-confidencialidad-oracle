#!/usr/bin/env bash
# =====================================================================
# aplicar_cifrado_red.sh - Agrega config/sqlnet_cifrado_servidor.ora al
#                          sqlnet.ora del servidor dentro del contenedor.
# MODIFICA : SÍ (sqlnet.ora del contenedor del laboratorio). Guarda una
#            copia sqlnet.ora.original antes del primer cambio.
# Efecto   : Las conexiones NUEVAS quedan cifradas; no requiere reiniciar
#            la base ni el listener.
# Revertir : herramientas/aplicar_cifrado_red.sh --revertir
# =====================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
CONTENEDOR="${CONTENEDOR:-iso27001-oracle}"
DESTINO='$ORACLE_HOME/network/admin/sqlnet.ora'

if [ "${1:-}" = "--revertir" ]; then
  docker exec "$CONTENEDOR" bash -c "cp $DESTINO.original $DESTINO && cat $DESTINO"
  echo "sqlnet.ora restaurado"; exit 0
fi

docker exec "$CONTENEDOR" bash -c "[ -f $DESTINO.original ] || cp $DESTINO $DESTINO.original"
if docker exec "$CONTENEDOR" bash -c "grep -q SQLNET.ENCRYPTION_SERVER $DESTINO"; then
  echo "El cifrado ya estaba configurado"
else
  grep -v '^#' "$RAIZ/config/sqlnet_cifrado_servidor.ora" | grep -v '^$' \
    | docker exec -i "$CONTENEDOR" bash -c "cat >> $DESTINO"
  echo "Cifrado de red agregado"
fi
echo "--- sqlnet.ora actual del servidor ---"
docker exec "$CONTENEDOR" bash -c "cat $DESTINO"
