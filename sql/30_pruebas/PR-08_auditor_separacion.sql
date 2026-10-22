-- =====================================================================
-- PR-08 | Positiva y negativa | El auditor ve la auditoría, NO los datos
-- ---------------------------------------------------------------------
-- Control        : A.8.2, A.8.15 (separación de funciones)  Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: AUDITOR_LAB (rol AUDIT_VIEWER).
-- Esperado       : (1) SELECT sobre CLIENTES -> ORA-00942 (negativa).
--                  (2) SELECT sobre UNIFIED_AUDIT_TRAIL -> devuelve registros (positiva).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-08_auditor_separacion.sql PR-08_auditor_separacion
-- =====================================================================
CONNECT auditor_lab/"&&pwd_auditor"@&&srv

PROMPT >>> PR-08.1 Esperado: ORA-00942 (el auditor no lee datos de clientes)
SELECT COUNT(*) FROM ventas_lab.clientes;

PROMPT >>> PR-08.2 Esperado: conteo de registros de auditoría > 0
SELECT COUNT(*) AS registros_auditoria FROM unified_audit_trail;
