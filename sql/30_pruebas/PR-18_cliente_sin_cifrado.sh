#!/usr/bin/env bash
# =====================================================================
# PR-18 | Negativa | Un cliente que rechaza el cifrado no puede conectarse
# ---------------------------------------------------------------------
# Control        : A.8.20, A.8.5 (riesgo R-CONF-06)
# Herramienta    : SQL*Plus con un sqlnet.ora de cliente propio (TNS_ADMIN)
# Requisitos     : herramientas/aplicar_cifrado_red.sh ejecutado (servidor con
#                  SQLNET.ENCRYPTION_SERVER = REQUIRED). Usuario: JUAN.
# Esperado       : (1) cliente normal: conecta y el banner muestra AES256;
#                  (2) cliente con SQLNET.ENCRYPTION_CLIENT = REJECTED: la
#                      conexión falla con ORA-12660 (los requisitos de
#                      cifrado del cliente y del servidor no son compatibles).
# Ejecución      : bash sql/30_pruebas/PR-18_cliente_sin_cifrado.sh > evidencias/PR-18_cliente_sin_cifrado.txt
# =====================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
C="${CONTENEDOR:-iso27001-oracle}"
DEF="$RAIZ/.secrets/lab_defines.sql"
leer() { sed -n "s/^DEFINE $1 = \"\(.*\)\"$/\1/p" "$DEF"; }
PWD_JUAN="$(leer pwd_juan)"
PWD_SYS="$(leer pwd_system)"

echo "== Evidencia: PR-18_cliente_sin_cifrado   Fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"

echo
echo ">>> PR-18.1 Cliente normal (acepta cifrado). Esperado: conexión exitosa con AES256"
printf 'CONNECT juan/"%s"@localhost:1521/FREEPDB1\nSELECT USER AS usuario, SYS_CONTEXT(%s) AS protocolo FROM dual;\nEXIT\n' \
  "$PWD_JUAN" "'USERENV','NETWORK_PROTOCOL'" | docker exec -i "$C" sqlplus -S -L /nolog
printf 'CONNECT system/"%s"@localhost:1521/FREEPDB1\nSET LINESIZE 150\nCOLUMN network_service_banner FORMAT A100\nSELECT network_service_banner FROM v$session_connect_info WHERE sid IN (SELECT sid FROM v$session WHERE username = %s) AND (network_service_banner LIKE %s OR network_service_banner LIKE %s);\nEXIT\n' \
  "$PWD_SYS" "'SYSTEM'" "'%%Encryption%%'" "'%%Crypto%%'" | docker exec -i "$C" sqlplus -S -L /nolog

echo
echo ">>> PR-18.2 Cliente que RECHAZA el cifrado. Esperado: ORA-12660"
docker exec "$C" bash -c "mkdir -p /tmp/cliente_sin_cifrado && printf 'SQLNET.ENCRYPTION_CLIENT = REJECTED\nSQLNET.CRYPTO_CHECKSUM_CLIENT = REJECTED\n' > /tmp/cliente_sin_cifrado/sqlnet.ora && cat /tmp/cliente_sin_cifrado/sqlnet.ora"
printf 'CONNECT juan/"%s"@localhost:1521/FREEPDB1\nEXIT\n' "$PWD_JUAN" \
  | docker exec -i -e TNS_ADMIN=/tmp/cliente_sin_cifrado "$C" sqlplus -S -L /nolog
docker exec "$C" rm -rf /tmp/cliente_sin_cifrado
