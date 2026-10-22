-- =====================================================================
-- VC-14 | Control ISO: A.8.15 Registro (logging)
-- ---------------------------------------------------------------------
-- Comprobación   : (a) las 4 políticas de auditoría del laboratorio y la
--                      política FGA están habilitadas;
--                  (b) el rastro contiene registros REALES de las pruebas, con
--                      quién, cuándo, desde dónde, qué objeto, qué sentencia y
--                      si tuvo éxito (RETURN_CODE = 0) o fue rechazada.
-- Tipo           : SOLO LECTURA.
-- Fuente         : UNIFIED_AUDIT_TRAIL (no SYS.AUD$: ver E-00, auditoría
--                  unificada pura).
-- Compatibilidad : 12.1+.  Privilegios: SYSTEM o AUDIT_VIEWER.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-14_registro_eventos.sql VC-14_registro_eventos
-- Interpretación : CUMPLE si (a) >= 4 políticas POL_CONF (5 tras la fase
--                  Actuar) + FGA habilitadas y (b) hay
--                  registros de las últimas 24 h para JUAN, ANA y SOPORTE_LAB
--                  y al menos un intento rechazado (RETURN_CODE <> 0).
-- Limitaciones   : - Registra lo que cubren las políticas; lo que no se audita
--                    no aparece.
--                  - LogMiner / redo logs NO sustituyen esta auditoría: el
--                    redo guarda cambios (INSERT/UPDATE/DELETE), no las
--                    consultas SELECT, que son el riesgo principal de
--                    confidencialidad.
-- =====================================================================

PROMPT === (a) Políticas habilitadas ===
SELECT policy_name, enabled_option, entity_name, success, failure
  FROM audit_unified_enabled_policies WHERE policy_name LIKE 'POL_CONF%' ORDER BY 1;
SELECT object_schema, object_name, policy_name, enabled FROM dba_audit_policies;

PROMPT === (b) Eventos del laboratorio de las últimas 24 horas (resumen) ===
SELECT dbusername, action_name, object_name, return_code, COUNT(*) AS eventos
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
   AND dbusername IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO')
 GROUP BY dbusername, action_name, object_name, return_code
 ORDER BY dbusername, action_name, object_name, return_code;

PROMPT === (b) Detalle: la "estructura" de la pizarra (día, hora, usuario, sesión, SQL) ===
SELECT TO_CHAR(event_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS event_timestamp,
       dbusername, sessionid, userhost, action_name, object_name, return_code,
       SUBSTR(sql_text, 1, 60) AS sql_text
  FROM unified_audit_trail
 WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
   AND dbusername IN ('JUAN','SOPORTE_LAB','APP_RIESGO')
   AND object_name IN ('CLIENTES', 'VENTAS')
 ORDER BY event_timestamp
 FETCH FIRST 15 ROWS ONLY;

PROMPT === (b) Registros de Fine-Grained Auditing (consultas a TARJETA) ===
SELECT dbusername, fga_policy_name, COUNT(*) AS eventos
  FROM unified_audit_trail
 WHERE audit_type = 'FineGrainedAudit' AND event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
 GROUP BY dbusername, fga_policy_name ORDER BY 1;

PROMPT === Resultado ===
SELECT (SELECT COUNT(DISTINCT policy_name) FROM audit_unified_enabled_policies
         WHERE policy_name LIKE 'POL_CONF%')                                                  AS a_politicas,
       (SELECT COUNT(*) FROM dba_audit_policies WHERE enabled = 'YES')                        AS a_fga,
       (SELECT COUNT(DISTINCT dbusername) FROM unified_audit_trail
         WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
           AND dbusername IN ('JUAN','ANA','SOPORTE_LAB'))                                    AS b_usuarios_con_registros,
       (SELECT COUNT(*) FROM unified_audit_trail
         WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY AND return_code <> 0
           AND dbusername IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO')) AS b_rechazos,
       CASE WHEN (SELECT COUNT(DISTINCT policy_name) FROM audit_unified_enabled_policies
                   WHERE policy_name LIKE 'POL_CONF%') >= 4
             AND (SELECT COUNT(*) FROM dba_audit_policies WHERE enabled = 'YES') >= 1
             AND (SELECT COUNT(DISTINCT dbusername) FROM unified_audit_trail
                   WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY
                     AND dbusername IN ('JUAN','ANA','SOPORTE_LAB')) = 3
             AND (SELECT COUNT(*) FROM unified_audit_trail
                   WHERE event_timestamp > SYSTIMESTAMP - INTERVAL '1' DAY AND return_code <> 0
                     AND dbusername IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO')) > 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
