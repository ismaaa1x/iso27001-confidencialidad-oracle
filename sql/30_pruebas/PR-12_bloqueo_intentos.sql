-- =====================================================================
-- PR-12 | Negativa | Bloqueo de cuenta tras intentos fallidos
-- ---------------------------------------------------------------------
-- Control        : A.8.5 (riesgo R-CONF-02)           Herramienta: SQL*Plus
-- Requisitos     : Laboratorio creado.  Usuario: PRUEBA_BLOQUEO (perfil con
--                  FAILED_LOGIN_ATTEMPTS = 3). Al final SYSTEM la desbloquea.
-- Esperado       : 3 x ORA-01017 (contraseña incorrecta) y luego ORA-28000
--                  (cuenta bloqueada) AUNQUE se use la contraseña correcta.
--                  DBA_USERS muestra LOCKED(TIMED). Los intentos fallidos
--                  quedan en UNIFIED_AUDIT_TRAIL (política ORA_LOGIN_LOGOUT).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-12_bloqueo_intentos.sql PR-12_bloqueo
-- =====================================================================
PROMPT >>> PR-12.1-3 Esperado: ORA-01017 tres veces
CONNECT prueba_bloqueo/"Incorrecta#1x"@&&srv
CONNECT prueba_bloqueo/"Incorrecta#2x"@&&srv
CONNECT prueba_bloqueo/"Incorrecta#3x"@&&srv

PROMPT >>> PR-12.4 Esperado: ORA-28000 con la contraseña CORRECTA (cuenta bloqueada)
CONNECT prueba_bloqueo/"&&pwd_bloqueo"@&&srv

PROMPT >>> Estado de la cuenta y registros de auditoría (como SYSTEM)
CONNECT system/"&&pwd_system"@&&srv
SELECT username, account_status, TO_CHAR(lock_date, 'YYYY-MM-DD HH24:MI:SS') AS bloqueada_desde
  FROM dba_users WHERE username = 'PRUEBA_BLOQUEO';
SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') AS event_timestamp, dbusername, action_name, return_code
  FROM unified_audit_trail
 WHERE dbusername = 'PRUEBA_BLOQUEO' AND event_timestamp > SYSTIMESTAMP - INTERVAL '10' MINUTE
 ORDER BY event_timestamp;

PROMPT >>> Restaurar: desbloquear la cuenta de prueba
ALTER USER prueba_bloqueo ACCOUNT UNLOCK;
