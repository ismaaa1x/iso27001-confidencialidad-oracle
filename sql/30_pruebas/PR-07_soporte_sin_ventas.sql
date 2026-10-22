-- =====================================================================
-- PR-07 | Negativa | Soporte no tiene acceso a la información comercial
-- ---------------------------------------------------------------------
-- Control        : A.5.15, A.8.3 (necesidad de conocer)  Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: SOPORTE_LAB.
-- Esperado       : SELECT sobre VENTAS -> ORA-00942 (para soporte la tabla
--                  "no existe": Oracle no revela objetos sin privilegio).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-07_soporte_sin_ventas.sql PR-07_soporte_sin_ventas
-- =====================================================================
CONNECT soporte_lab/"&&pwd_soporte"@&&srv

PROMPT >>> PR-07 Esperado: ORA-00942 table or view does not exist
SELECT COUNT(*) FROM ventas_lab.ventas;
