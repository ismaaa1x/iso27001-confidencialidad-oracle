-- =====================================================================
-- A-01 | Actuar | Corregir el hallazgo de VC-07 (cuenta con SELECT ANY TABLE)
-- ---------------------------------------------------------------------
-- Hallazgo       : VC-07 = NO CUMPLE: APP_RIESGO tiene SELECT ANY TABLE.
--                  PR-10 demostró que, aunque VPD y el enmascaramiento
--                  limitaron el daño, la cuenta pudo leer la copia DEV y la
--                  tabla de reglas de seguridad.
-- Corrección     : En el escenario ficticio, la cuenta pertenecía a una
--                  integración que ya no tiene justificación de negocio:
--                  se revoca el privilegio amplio y se bloquea la cuenta
--                  (no se borra, para conservar la trazabilidad de auditoría).
-- Controles      : A.8.2, A.5.18.   Privilegios: SYSTEM.   Contenedor: FREEPDB1.
-- MODIFICA       : SÍ (revoca privilegios y bloquea APP_RIESGO).
-- Ejecución      : herramientas/ejecutar.sh system sql/40_actuar/A-01_revocar_privilegio_amplio.sql A-01_revocar_privilegio
-- Verificación   : volver a ejecutar VC-07 -> esperado CUMPLE.
-- =====================================================================

PROMPT >>> Antes
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'APP_RIESGO' ORDER BY 2;

REVOKE SELECT ANY TABLE FROM app_riesgo;
REVOKE CREATE SESSION FROM app_riesgo;
ALTER USER app_riesgo ACCOUNT LOCK;

PROMPT >>> Después
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'APP_RIESGO' ORDER BY 2;
SELECT username, account_status FROM dba_users WHERE username = 'APP_RIESGO';

PROMPT >>> Comprobación: la cuenta ya no puede conectarse (esperado ORA-28000)
CONNECT app_riesgo/"&&pwd_app_riesgo"@&&srv
