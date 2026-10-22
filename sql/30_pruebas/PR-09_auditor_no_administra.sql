-- =====================================================================
-- PR-09 | Negativa | El auditor no puede desactivar ni crear auditoría
-- ---------------------------------------------------------------------
-- Control        : A.5.33, A.8.2 (protección del rastro)  Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: AUDITOR_LAB (sin AUDIT_ADMIN).
-- Esperado       : NOAUDIT POLICY -> ORA-01031; CREATE AUDIT POLICY -> rechazo
--                  (26ai responde ORA-41732; versiones anteriores ORA-01031).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-09_auditor_no_administra.sql PR-09_auditor_no_administra
-- =====================================================================
CONNECT auditor_lab/"&&pwd_auditor"@&&srv

PROMPT >>> PR-09.1 Esperado: ORA-01031 (no puede apagar la auditoría)
NOAUDIT POLICY pol_conf_acceso_datos;

PROMPT >>> PR-09.2 Esperado: rechazo ORA-41732 en 26ai (ORA-01031 en versiones anteriores)
CREATE AUDIT POLICY pol_auditor_intento ACTIONS LOGON;
