#!/usr/bin/env bash
# =====================================================================
# ejecutar_todo.sh - Ejecuta el ciclo PHVA completo del laboratorio y
#                    guarda todas las evidencias en evidencias/.
#
#   PLANIFICAR : 00_diagnostico
#   HACER      : (limpieza) + 10_lab_setup + cifrado de red
#   VERIFICAR  : 30_pruebas (PR-00..PR-19, PR-99) y 20_verificacion (VC-01..VC-15)
#   ACTUAR     : 40_actuar (A-01, A-02) y re-verificación (VC-07, PR-19, VC-14)
#
# Uso  : bash herramientas/ejecutar_todo.sh
# Tarda: ~6 minutos (PR-13 espera 3 minutos de inactividad a propósito).
# Requisitos: Docker Desktop abierto y contenedor iso27001-oracle en marcha.
#             El keystore TDE (01_tde_keystore.sql) se crea una sola vez; si
#             ya existe, se omite.
# =====================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"
E=herramientas/ejecutar.sh
C="${CONTENEDOR:-iso27001-oracle}"

paso() { echo; echo "######## $*"; }
correr() { bash "$E" "$@" | tail -1; }

paso "PLANIFICAR - diagnóstico del entorno"
correr system sql/00_diagnostico/00_entorno.sql E-00_diagnostico_entorno

paso "HACER - keystore TDE (solo si no existe)"
ESTADO=$(echo "SET HEADING OFF FEEDBACK OFF
SELECT status FROM v\$encryption_wallet WHERE con_id = 1;" | docker exec -i "$C" sqlplus -S / as sysdba | tr -d '[:space:]')
if [ "$ESTADO" = "OPEN" ]; then echo "Keystore ya abierto: se conserva E-01 existente"
else correr sysdba-root sql/10_lab_setup/01_tde_keystore.sql E-01_tde_keystore; fi

paso "HACER - limpieza previa para empezar desde cero"
correr sysdba-pdb sql/90_limpieza/99_eliminar_laboratorio.sql E-99_limpieza_previa

paso "HACER - laboratorio"
correr system     sql/10_lab_setup/02_esquema_datos.sql          E-02_esquema_datos
correr system     sql/10_lab_setup/03_usuarios_roles_perfil.sql  E-03_usuarios_roles_perfil
correr system     sql/10_lab_setup/04_clasificacion.sql          E-04_clasificacion
correr system     sql/10_lab_setup/05_vpd.sql                    E-05_vpd
correr system     sql/10_lab_setup/06_redaction.sql              E-06_redaction
correr system     sql/10_lab_setup/07_auditoria.sql              E-07_auditoria
correr sysdba-pdb sql/10_lab_setup/08_retencion_auditoria.sql    E-08_retencion_auditoria
correr sysdba-pdb sql/10_lab_setup/09_copia_dev_enmascarada.sql  E-09_copia_dev

paso "HACER - respaldos RMAN cifrados por defecto"
bash sql/10_lab_setup/10_rman_cifrado.sh > evidencias/E-11_rman_cifrado.txt 2>&1 && echo "Evidencia guardada en evidencias/E-11_rman_cifrado.txt"

paso "HACER - cifrado de red y exposición del puerto"
{ echo "== Evidencia: E-10_red   Fecha: $(date '+%Y-%m-%d %H:%M:%S %z')"
  bash herramientas/aplicar_cifrado_red.sh
  echo "--- Puertos publicados por el contenedor (docker port) ---"
  docker port "$C"
} > evidencias/E-10_red.txt 2>&1 && echo "Evidencia guardada en evidencias/E-10_red.txt"

paso "VERIFICAR - batería de pruebas"
correr system  sql/30_pruebas/PR-00_iniciar_captura_privilegios.sql PR-00_captura_inicio
correr ninguno sql/30_pruebas/PR-01_vpd_vendedor_juan.sql        PR-01_vpd_juan
correr ninguno sql/30_pruebas/PR-02_vpd_aislamiento_ana.sql      PR-02_vpd_ana
correr ninguno sql/30_pruebas/PR-03_redaction_vendedor.sql       PR-03_redaction_vendedor
correr ninguno sql/30_pruebas/PR-04_redaction_soporte.sql        PR-04_redaction_soporte
correr ninguno sql/30_pruebas/PR-05_borrado_denegado.sql         PR-05_borrado_denegado
correr ninguno sql/30_pruebas/PR-06_procedimiento_vs_insert.sql  PR-06_procedimiento
correr ninguno sql/30_pruebas/PR-07_soporte_sin_ventas.sql       PR-07_soporte_sin_ventas
correr ninguno sql/30_pruebas/PR-08_auditor_separacion.sql       PR-08_auditor_separacion
correr ninguno sql/30_pruebas/PR-09_auditor_no_administra.sql    PR-09_auditor_no_administra
correr ninguno sql/30_pruebas/PR-10_cuenta_sobreprivilegiada.sql PR-10_sobreprivilegiada
correr ninguno sql/30_pruebas/PR-11_contrasena_debil.sql         PR-11_contrasena_debil
correr ninguno sql/30_pruebas/PR-12_bloqueo_intentos.sql         PR-12_bloqueo
echo "PR-13 espera 3 minutos de inactividad a propósito..."
correr ninguno sql/30_pruebas/PR-13_idle_time.sql                PR-13_idle_time
correr ninguno sql/30_pruebas/PR-14_auditoria_registra.sql       PR-14_auditoria
correr ninguno sql/30_pruebas/PR-15_tde_archivos.sql             PR-15_tde_archivos
bash sql/30_pruebas/PR-16_export_cifrado.sh     > evidencias/PR-16_respaldos_cifrados.txt 2>&1 && echo "Evidencia guardada en evidencias/PR-16_respaldos_cifrados.txt"
correr ninguno sql/30_pruebas/PR-17_papelera_purge.sql           PR-17_papelera
bash sql/30_pruebas/PR-18_cliente_sin_cifrado.sh > evidencias/PR-18_cliente_sin_cifrado.txt 2>&1 && echo "Evidencia guardada en evidencias/PR-18_cliente_sin_cifrado.txt"
correr ninguno sql/30_pruebas/PR-19_dba_altera_reglas.sql        PR-19_dba_reglas_antes
correr system  sql/30_pruebas/PR-99_cerrar_captura_privilegios.sql PR-99_captura_cierre

paso "VERIFICAR - controles observables (estado ANTES de Actuar)"
for f in sql/20_verificacion/VC-*.sql; do
  base=$(basename "$f" .sql)
  modo=system; [ "${base%%_*}" = "VC-11" ] && modo=sysdba-pdb
  correr "$modo" "$f" "$base"
done

paso "ACTUAR - correcciones y re-verificación"
correr system  sql/40_actuar/A-01_revocar_privilegio_amplio.sql A-01_revocar_privilegio
correr system  sql/40_actuar/A-02_auditar_reglas_seguridad.sql   A-02_auditar_reglas
correr system  sql/20_verificacion/VC-07_acceso_privilegiado.sql VC-07_acceso_privilegiado_DESPUES
correr ninguno sql/30_pruebas/PR-19_dba_altera_reglas.sql        PR-19_dba_reglas_despues
correr system  sql/20_verificacion/VC-14_registro_eventos.sql    VC-14_registro_eventos_DESPUES

paso "RESUMEN de resultados de los controles observables"
for f in evidencias/VC-*.txt; do
  r=$(grep -oE "(NO CUMPLE|CUMPLE|PARCIAL) *$" "$f" | tail -1 | sed 's/ *$//')
  printf '%-48s %s\n' "$(basename "$f" .txt)" "${r:-(revisar manualmente)}"
done
