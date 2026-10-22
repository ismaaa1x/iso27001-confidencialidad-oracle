#!/usr/bin/env bash
# =====================================================================
# PR-16 | Positiva y negativa | Confidencialidad de los RESPALDOS
# ---------------------------------------------------------------------
# Control        : A.8.13, A.8.12, A.8.10 (riesgo R-CONF-03)
# Herramienta    : Data Pump (expdp), RMAN, strings, openssl y shred, dentro del contenedor
# Requisitos     : Laboratorio creado; keystore TDE abierto; 10_rman_cifrado.sh aplicado.
#                  Usuarios: SYSTEM (Data Pump) y SYSDBA por SO (RMAN).
# Esperado       :
#   16.1 HALLAZGO: un export normal de Data Pump guarda en CLARO los datos de
#        tablas cifradas con TDE (aviso ORA-39173) -> el marcador se lee en el .dmp.
#        Además, VPD filtra el export de SYSTEM (ORA-39181: CLIENTES y VENTAS
#        salen con 0 filas): un respaldo lógico completo exige una cuenta de
#        respaldo con EXEMPT ACCESS POLICY o usar RMAN.
#   16.2 LIMITACIÓN de Free: el export cifrado falla con ORA-00439
#        (feature not enabled: Dump File Encryption).
#   16.3 Alternativa de la base: respaldo RMAN SIN cifrar de TS_SIN_CIFRAR ->
#        marcador visible; respaldo RMAN CIFRADO (configuración por defecto,
#        AES256 con el keystore) -> 0 coincidencias.
#   16.4 Respaldo RMAN de TS_CONFIDENCIAL aun con SET ENCRYPTION OFF -> 0
#        coincidencias: los bloques de un tablespace TDE ya van cifrados.
#   16.5 Alternativa para exports en Free: cifrar el .dmp en el sistema
#        operativo (openssl AES-256). Protección DISTINTA: la clave se gestiona
#        fuera de Oracle y la base no la controla ni la audita.
#   16.6 Eliminación: los respaldos de prueba se borran con RMAN DELETE y shred.
# Ejecución      : bash sql/30_pruebas/PR-16_export_cifrado.sh > evidencias/PR-16_respaldos_cifrados.txt
# Seguridad      : contraseñas en parfiles temporales (permisos 600) que se
#                  borran con shred; nunca se imprimen.
# Limitación     : shred no garantiza borrado físico en SSD ni en sistemas de
#                  archivos en capas; por eso lo importante es que la copia
#                  esté cifrada (destruir la clave = destruir el dato).
# =====================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
C="${CONTENEDOR:-iso27001-oracle}"
DEF="$RAIZ/.secrets/lab_defines.sql"
leer() { sed -n "s/^DEFINE $1 = \"\(.*\)\"$/\1/p" "$DEF"; }
PWD_SYS="$(leer pwd_system)"
PWD_EXP="$(leer pwd_export)"   # alfanumérica: en un parfile "#" inicia un comentario
MARCA=MARCADOR-CONFIDENCIAL
cuenta() { docker exec "$C" bash -c "strings $1 2>/dev/null | grep -c $MARCA"; }

echo "== Evidencia: PR-16_respaldos_cifrados   Fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
# En un PDB, DATA_PUMP_DIR apunta a <ruta>/<GUID del PDB>: se consulta desde FREEPDB1
DIR=$(printf "ALTER SESSION SET CONTAINER=FREEPDB1;\nSET HEADING OFF FEEDBACK OFF\nSELECT directory_path FROM dba_directories WHERE directory_name = 'DATA_PUMP_DIR';\n" \
      | docker exec -i "$C" sqlplus -S / as sysdba | grep '/' | head -1 | tr -d '[:space:]')
echo "DATA_PUMP_DIR (FREEPDB1): $DIR"

parfile() {  # $1 = nombre, $2.. = líneas adicionales
  local nombre="$1"; shift
  { echo "userid=system/$PWD_SYS@localhost:1521/FREEPDB1"; printf '%s\n' "$@"; } \
    | docker exec -i "$C" bash -c "umask 077; cat > /tmp/$nombre.par"
}

echo
echo ">>> PR-16.1 Export de Data Pump SIN cifrar del esquema VENTAS_LAB"
echo "    Esperado: ORA-39173 (datos TDE guardados en claro), ORA-39181 (VPD) y marcador visible"
parfile plano "schemas=VENTAS_LAB" "directory=DATA_PUMP_DIR" "dumpfile=pr16_plano.dmp" "logfile=pr16_plano.log" "reuse_dumpfiles=y"
docker exec "$C" bash -c "expdp parfile=/tmp/plano.par 2>&1 | grep -E 'exported|ORA-|completed'"
echo "    coincidencias del marcador en pr16_plano.dmp: $(cuenta "$DIR/pr16_plano.dmp")"

echo
echo ">>> PR-16.2 Export de Data Pump CIFRADO (ENCRYPTION=ALL, AES256)"
echo "    Esperado en Oracle Free: ORA-00439 feature not enabled: Dump File Encryption"
parfile cifrado "schemas=VENTAS_LAB" "directory=DATA_PUMP_DIR" "dumpfile=pr16_cifrado.dmp" "logfile=pr16_cifrado.log" "reuse_dumpfiles=y" \
        "encryption=ALL" "encryption_algorithm=AES256" "encryption_mode=PASSWORD" "encryption_password=$PWD_EXP"
docker exec "$C" bash -c "expdp parfile=/tmp/cifrado.par 2>&1 | grep -E 'ORA-|completed'"

echo
echo ">>> PR-16.3 / 16.4 Respaldos RMAN (configuración: ENCRYPTION FOR DATABASE ON, AES256)"
docker exec -i "$C" rman target / <<'EOF' 2>&1 | grep -E "^RMAN-|^ORA-|piece handle|Finished backup|ENCRYPTION" | sed 's/^/    /'
SHOW ENCRYPTION FOR DATABASE;
BACKUP TABLESPACE FREEPDB1:TS_SIN_CIFRAR FORMAT '/tmp/pr16_rman_cifrado_%U' TAG 'PR16_CIFRADO';
SET ENCRYPTION OFF;
BACKUP TABLESPACE FREEPDB1:TS_SIN_CIFRAR   FORMAT '/tmp/pr16_rman_plano_%U'      TAG 'PR16_PLANO';
BACKUP TABLESPACE FREEPDB1:TS_CONFIDENCIAL FORMAT '/tmp/pr16_rman_tde_sincif_%U' TAG 'PR16_TDE_SIN_CIFRADO_RMAN';
EOF
echo "    16.3a respaldo RMAN SIN cifrar de TS_SIN_CIFRAR   -> coincidencias: $(docker exec "$C" bash -c "cat /tmp/pr16_rman_plano_* | strings | grep -c $MARCA")"
echo "    16.3b respaldo RMAN CIFRADO de TS_SIN_CIFRAR      -> coincidencias: $(docker exec "$C" bash -c "cat /tmp/pr16_rman_cifrado_* | strings | grep -c $MARCA")"
echo "    16.4  respaldo RMAN de TS_CONFIDENCIAL (sin cifrado RMAN, bloques TDE) -> coincidencias: $(docker exec "$C" bash -c "cat /tmp/pr16_rman_tde_sincif_* | strings | grep -c $MARCA")"

echo
echo ">>> PR-16.5 Alternativa para exports en Free: cifrado del .dmp con openssl (AES-256, PBKDF2)"
docker exec -i "$C" bash -c "umask 077; cat > /tmp/clave_dmp.txt" <<< "$PWD_EXP"
docker exec "$C" bash -c "openssl enc -aes-256-cbc -pbkdf2 -salt -in $DIR/pr16_plano.dmp -out /tmp/pr16_plano.dmp.enc -pass file:/tmp/clave_dmp.txt && echo '    archivo cifrado generado: pr16_plano.dmp.enc'"
echo "    coincidencias del marcador en pr16_plano.dmp.enc: $(cuenta /tmp/pr16_plano.dmp.enc)"

echo
echo ">>> PR-16.6 Eliminación de los respaldos de prueba"
docker exec -i "$C" rman target / <<'EOF' 2>&1 | grep -E "Deleted [0-9]+ objects|RMAN-|ORA-" | sed 's/^/    /'
DELETE NOPROMPT BACKUP TAG 'PR16_PLANO';
DELETE NOPROMPT BACKUP TAG 'PR16_CIFRADO';
DELETE NOPROMPT BACKUP TAG 'PR16_TDE_SIN_CIFRADO_RMAN';
EOF
docker exec "$C" bash -c "shred -u $DIR/pr16_plano.dmp /tmp/pr16_plano.dmp.enc /tmp/clave_dmp.txt /tmp/plano.par /tmp/cifrado.par 2>/dev/null; rm -f $DIR/pr16_*.log"
echo "    archivos de prueba restantes: $(docker exec "$C" bash -c "ls $DIR/pr16_* /tmp/pr16_* 2>/dev/null | wc -l")"
