-- =====================================================================
-- PR-13 | Negativa | Una sesión inactiva se cierra (IDLE_TIME de la pizarra)
-- ---------------------------------------------------------------------
-- Control        : A.8.5 (riesgo R-CONF-02: sesión desatendida)  Herramienta: SQL*Plus
-- Requisitos     : Laboratorio creado; RESOURCE_LIMIT = TRUE.
--                  Usuario: PRUEBA_IDLE (perfil con IDLE_TIME = 1 minuto, solo
--                  para que la prueba dure poco; el perfil real usa 15).
-- Esperado       : Primera consulta OK; tras ~3 minutos sin actividad la
--                  siguiente consulta falla con ORA-02396 (tiempo de
--                  inactividad excedido). Oracle revisa la inactividad de
--                  forma periódica: puede tardar algo más que el límite.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-13_idle_time.sql PR-13_idle_time
-- =====================================================================
CONNECT prueba_idle/"&&pwd_idle"@&&srv

PROMPT >>> PR-13.1 Esperado: consulta exitosa
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') AS hora_inicio FROM dual;

PROMPT >>> Esperando 180 segundos SIN actividad en la sesión...
HOST sleep 180

PROMPT >>> PR-13.2 Esperado: ORA-02396 exceeded maximum idle time
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') AS hora_fin FROM dual;
