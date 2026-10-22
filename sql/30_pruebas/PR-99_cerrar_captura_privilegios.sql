-- =====================================================================
-- PR-99 | Cierre: detener Privilege Analysis y generar resultados
-- ---------------------------------------------------------------------
-- Propósito      : Cerrar la captura iniciada en PR-00 para que VC-05 pueda
--                  leer DBA_USED_PRIVS / DBA_UNUSED_PRIVS.
-- Privilegios    : CAPTURE_ADMIN (SYSTEM).  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/30_pruebas/PR-99_cerrar_captura_privilegios.sql PR-99_captura_cierre
-- =====================================================================
BEGIN
  DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE(name => 'CAP_LAB_CONF');
  DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT(name => 'CAP_LAB_CONF', run_name => 'PRUEBAS_LAB');
END;
/
SELECT name AS capture, enabled FROM dba_priv_captures WHERE name = 'CAP_LAB_CONF';
SELECT COUNT(*) AS privilegios_usados FROM dba_used_privs WHERE capture = 'CAP_LAB_CONF';
