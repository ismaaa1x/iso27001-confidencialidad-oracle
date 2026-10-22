-- =====================================================================
-- PR-14 | Positiva | La auditoría registró las pruebas anteriores
-- ---------------------------------------------------------------------
-- Control        : A.8.15, A.5.33 (riesgo R-CONF-05)   Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : PR-01..PR-12 ejecutadas.  Usuario: AUDITOR_LAB (AUDIT_VIEWER).
-- Esperado       : Registros de JUAN, ANA, SOPORTE_LAB y APP_RIESGO con
--                  usuario, hora, sesión, acción, objeto, SQL y código de
--                  retorno: 0 = permitido; 1031/942/20002 = rechazado.
--                  Registros FGA cuando se consultó la columna TARJETA y
--                  uso de SELECT ANY TABLE por APP_RIESGO.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-14_auditoria_registra.sql PR-14_auditoria
-- Limitación     : El SELECT del propio auditor sobre la vista no se audita
--                  aquí (no hay política para ello); podría añadirse.
-- =====================================================================
CONNECT auditor_lab/"&&pwd_auditor"@&&srv

PROMPT >>> PR-14.1 Resumen por usuario, acción, objeto y resultado (última hora)
SELECT dbusername, action_name, object_name, return_code, COUNT(*) AS eventos
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR
   AND dbusername IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO')
 GROUP BY dbusername, action_name, object_name, return_code
 ORDER BY dbusername, action_name, object_name, return_code;

PROMPT >>> PR-14.2 Intentos RECHAZADOS (return_code distinto de 0)
SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') AS event_timestamp, dbusername, action_name,
       object_name, return_code, SUBSTR(sql_text, 1, 60) AS sql_text
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR AND return_code <> 0
   AND dbusername IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO')
 ORDER BY event_timestamp;

PROMPT >>> PR-14.3 Uso de SELECT ANY TABLE y consultas a la columna TARJETA (FGA)
SELECT dbusername, audit_type, NVL(fga_policy_name, unified_audit_policies) AS policy_name,
       object_name, COUNT(*) AS eventos
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR
   AND (audit_type = 'FineGrainedAudit' OR unified_audit_policies LIKE '%PRIVILEGIOS_AMPLIOS%')
 GROUP BY dbusername, audit_type, NVL(fga_policy_name, unified_audit_policies), object_name
 ORDER BY 1, 2;
