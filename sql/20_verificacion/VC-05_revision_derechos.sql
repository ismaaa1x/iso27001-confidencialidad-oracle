-- =====================================================================
-- VC-05 | Control ISO: A.5.18 Derechos de acceso
-- ---------------------------------------------------------------------
-- Comprobación   : Existe una revisión objetiva de derechos: Privilege
--                  Analysis registró qué privilegios USARON realmente las
--                  cuentas del laboratorio y cuáles NO usaron (candidatos a
--                  revocar).
-- Tipo           : SOLO LECTURA (lee el resultado de la captura CAP_LAB_CONF,
--                  creada y cerrada por sql/30_pruebas/PR-00 y PR-99).
-- Compatibilidad : 12.1+ (DBMS_PRIVILEGE_CAPTURE). Incluido en Free/XE.
-- Privilegios    : rol CAPTURE_ADMIN (SYSTEM lo tiene).  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-05_revision_derechos.sql VC-05_revision_derechos
-- Interpretación : CUMPLE   = captura generada y 0 privilegios sin uso.
--                  PARCIAL  = captura generada con privilegios sin uso que
--                             deben revisarse (se listan).
--                  NO CUMPLE= no existe captura con resultados.
-- Limitación     : Refleja solo el período capturado (las pruebas). Un
--                  privilegio "sin uso" en ese período puede ser necesario en
--                  otro momento (por ejemplo, un cierre mensual): la decisión
--                  final la toma el responsable del sistema.
-- =====================================================================

PROMPT === Capturas registradas ===
SELECT name AS capture, type, enabled, TO_CHAR(run_name) AS run_name FROM dba_priv_captures;

PROMPT === Privilegios USADOS durante la captura ===
SELECT username, sys_priv, obj_priv, object_owner, object_name, used_role
  FROM dba_used_privs
 WHERE capture = 'CAP_LAB_CONF'
 ORDER BY username, sys_priv, obj_priv, object_name;

PROMPT === Privilegios NO usados (candidatos a revocar) ===
SELECT username, rolename AS role, sys_priv, obj_priv, object_owner, object_name
  FROM dba_unused_privs
 WHERE capture = 'CAP_LAB_CONF'
   AND username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')
 ORDER BY username, sys_priv, obj_priv, object_name;

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM dba_used_privs WHERE capture = 'CAP_LAB_CONF') AS usados,
       (SELECT COUNT(*) FROM dba_unused_privs WHERE capture = 'CAP_LAB_CONF'
           AND username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')) AS sin_uso,
       CASE WHEN (SELECT COUNT(*) FROM dba_used_privs WHERE capture = 'CAP_LAB_CONF') = 0 THEN 'NO CUMPLE'
            WHEN (SELECT COUNT(*) FROM dba_unused_privs WHERE capture = 'CAP_LAB_CONF'
                     AND username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')) = 0 THEN 'CUMPLE'
            ELSE 'PARCIAL' END AS resultado
  FROM dual;
