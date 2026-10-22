-- =====================================================================
-- 08_retencion_auditoria.sql  -  Protección y retención del rastro de auditoría
-- ---------------------------------------------------------------------
-- Propósito      : Definir una purga controlada de la auditoría: solo se
--                  borran registros más antiguos que la última fecha de
--                  "archivado" (exportación al SIEM o a un almacenamiento
--                  externo). Así el rastro no crece sin límite y nadie lo
--                  borra a mano (A.5.33, A.8.15; tarea T11).
-- Compatibilidad : 12.1+ (DBMS_AUDIT_MGMT con AUDIT_TRAIL_UNIFIED).
-- Privilegios    : SYSTEM con AUDIT_ADMIN, o SYS. Aquí se usa SYSDBA en el
--                  PDB porque SYSTEM no tiene el rol AUDIT_ADMIN (ver E-00).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (fecha de último archivado y job de purga).
-- Ejecución      : herramientas/ejecutar.sh sysdba-pdb sql/10_lab_setup/08_retencion_auditoria.sql E-08_retencion_auditoria
-- Limitaciones   : En el laboratorio NO hay un SIEM real. La fecha de
--                  archivado se fija en "hace 90 días" para simular una
--                  política de retención de 90 días; en una organización
--                  real la fija el proceso que exporta los registros.
-- =====================================================================

PROMPT === 1. Marcar como archivado todo lo anterior a 90 días ===
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_time => SYSTIMESTAMP - INTERVAL '90' DAY);
END;
/

PROMPT === 2. Job de purga diaria que respeta la fecha de archivado ===
BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_purge_interval => 24,
    audit_trail_purge_name     => 'PURGA_AUDITORIA_CONF_90D',
    use_last_arch_timestamp    => TRUE);
END;
/

PROMPT === Verificación ===
SELECT audit_trail, last_archive_ts FROM dba_audit_mgmt_last_arch_ts;
SELECT job_name, job_status, audit_trail, job_frequency FROM dba_audit_mgmt_cleanup_jobs;
