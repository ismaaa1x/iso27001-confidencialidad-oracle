-- =====================================================================
-- VC-09 | Control ISO: A.8.5 Autenticación segura
-- ---------------------------------------------------------------------
-- Comprobación   : (a) bloqueo tras <= 5 intentos fallidos con tiempo de bloqueo;
--                  (b) cierre de sesiones inactivas (IDLE_TIME, de la pizarra);
--                  (c) las cuentas usan solo verificadores de contraseña
--                      modernos (12C), sin el antiguo 10G;
--                  (d) RESOURCE_LIMIT = TRUE (necesario para que IDLE_TIME aplique).
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+.  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-09_autenticacion_segura.sql VC-09_autenticacion_segura
-- Interpretación : CUMPLE si se cumplen (a), (b), (c) y (d) para las cuentas
--                  del laboratorio.
-- Limitación     : No hay segundo factor (MFA). Oracle lo ofrece con
--                  autenticación externa (Kerberos, RADIUS, IAM) o MFA nativo
--                  en versiones recientes; queda como mejora.
-- =====================================================================

PROMPT === Límites de sesión y bloqueo del perfil ===
SELECT profile, resource_name, limit FROM dba_profiles
 WHERE profile = 'PERFIL_CONFIDENCIAL'
   AND resource_name IN ('FAILED_LOGIN_ATTEMPTS', 'PASSWORD_LOCK_TIME', 'IDLE_TIME',
                         'SESSIONS_PER_USER', 'INACTIVE_ACCOUNT_TIME')
 ORDER BY resource_name;

PROMPT === Verificadores de contraseña de las cuentas del laboratorio ===
SELECT username, password_versions, profile FROM dba_users
 WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO') ORDER BY 1;

PROMPT === Parámetros relacionados ===
SELECT name AS parameter_name, value AS parameter_value FROM v$parameter
 WHERE name IN ('resource_limit', 'sec_max_failed_login_attempts') ORDER BY 1;

PROMPT === Resultado ===
SELECT CASE WHEN TO_NUMBER((SELECT limit FROM dba_profiles WHERE profile = 'PERFIL_CONFIDENCIAL'
                             AND resource_name = 'FAILED_LOGIN_ATTEMPTS') DEFAULT 99 ON CONVERSION ERROR) <= 5
             AND (SELECT limit FROM dba_profiles WHERE profile = 'PERFIL_CONFIDENCIAL'
                   AND resource_name = 'PASSWORD_LOCK_TIME') NOT IN ('UNLIMITED', 'DEFAULT')
             AND (SELECT limit FROM dba_profiles WHERE profile = 'PERFIL_CONFIDENCIAL'
                   AND resource_name = 'IDLE_TIME') NOT IN ('UNLIMITED', 'DEFAULT')
             AND (SELECT COUNT(*) FROM dba_users
                   WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')
                     AND password_versions LIKE '%10G%') = 0
             AND (SELECT UPPER(value) FROM v$parameter WHERE name = 'resource_limit') = 'TRUE'
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
