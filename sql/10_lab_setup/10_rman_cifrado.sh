#!/usr/bin/env bash
# =====================================================================
# 10_rman_cifrado.sh  -  Respaldos RMAN cifrados por defecto
# ---------------------------------------------------------------------
# Propósito      : Que todo respaldo físico de la base quede cifrado con
#                  AES256 usando el keystore de TDE (cifrado transparente),
#                  para que una copia robada del respaldo no sea legible
#                  (A.8.13, A.8.12; tarea T09; riesgo R-CONF-03).
# Por qué RMAN   : En Oracle Free el cifrado de exports de Data Pump NO está
#                  habilitado (ORA-00439: feature not enabled: Dump File
#                  Encryption, ver PR-16), pero V$OPTION muestra
#                  "Backup Encryption = TRUE": el respaldo cifrado se hace con RMAN.
# Compatibilidad : 10g+. Probado en 26ai Free.  Privilegios: SYSDBA/SYSBACKUP.
# Contenedor     : CDB (la configuración de RMAN es de toda la base).
# MODIFICA       : SÍ (configuración persistente de RMAN en el controlfile del
#                  contenedor del laboratorio; no afecta a otros contenedores).
# Revertir       : rman target / -> CONFIGURE ENCRYPTION FOR DATABASE CLEAR;
#                                   CONFIGURE ENCRYPTION ALGORITHM CLEAR;
# Ejecución      : bash sql/10_lab_setup/10_rman_cifrado.sh > evidencias/E-11_rman_cifrado.txt
# Verificación   : VC-13 consulta V$RMAN_CONFIGURATION.
# =====================================================================
export MSYS_NO_PATHCONV=1
C="${CONTENEDOR:-iso27001-oracle}"
echo "== Evidencia: E-11_rman_cifrado   Fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
docker exec -i "$C" rman target / <<'EOF' 2>&1 | grep -vE "^\s*$|^Copyright|^Recovery Manager: Release"
CONFIGURE ENCRYPTION FOR DATABASE ON;
CONFIGURE ENCRYPTION ALGORITHM 'AES256';
SHOW ENCRYPTION FOR DATABASE;
SHOW ENCRYPTION ALGORITHM;
EOF
