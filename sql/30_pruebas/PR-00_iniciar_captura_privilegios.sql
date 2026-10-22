-- =====================================================================
-- PR-00 | Preparación: iniciar Privilege Analysis antes de las pruebas
-- ---------------------------------------------------------------------
-- Propósito      : Registrar qué privilegios usan realmente las cuentas del
--                  laboratorio durante PR-01..PR-19 (evidencia para VC-05,
--                  control A.5.18).
-- Compatibilidad : 12.1+.  Privilegios: CAPTURE_ADMIN (SYSTEM).  Contenedor: FREEPDB1.
-- MODIFICA       : Crea y habilita la captura CAP_LAB_CONF (no cambia permisos).
-- Ejecución      : herramientas/ejecutar.sh system sql/30_pruebas/PR-00_iniciar_captura_privilegios.sql PR-00_captura_inicio
-- =====================================================================
BEGIN
  DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(
    name        => 'CAP_LAB_CONF',
    description => 'Uso real de privilegios de las cuentas del laboratorio',
    type        => DBMS_PRIVILEGE_CAPTURE.G_CONTEXT,
    condition   => q'[SYS_CONTEXT('USERENV','SESSION_USER') IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')]');
  DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE(name => 'CAP_LAB_CONF', run_name => 'PRUEBAS_LAB');
END;
/
SELECT name AS capture, type, enabled FROM dba_priv_captures WHERE name = 'CAP_LAB_CONF';
