-- =====================================================================
-- VC-03 | Control ISO: A.5.16 Gestión de identidades
-- ---------------------------------------------------------------------
-- Comprobación   : (a) ninguna cuenta conserva contraseñas por defecto de Oracle;
--                  (b) los esquemas dueños de datos no permiten iniciar sesión
--                      (NO AUTHENTICATION);
--                  (c) cada persona del laboratorio tiene su propia cuenta con
--                      el perfil de seguridad.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+ (DBA_USERS_WITH_DEFPWD, ORACLE_MAINTAINED).
-- Privilegios    : SYSTEM.   Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-03_identidades.sql VC-03_identidades
-- Interpretación : CUMPLE si (a)=0, (b)=3 esquemas sin autenticación y (c)=0
--                  cuentas de personas fuera del perfil.
-- Limitación     : No puede saber si una cuenta es compartida por varias
--                  personas: eso requiere revisar el procedimiento de altas.
-- =====================================================================

PROMPT === Cuentas no mantenidas por Oracle ===
SELECT username, account_status, profile, authentication_type,
       TO_CHAR(last_login, 'YYYY-MM-DD HH24:MI') AS ultimo_login
  FROM dba_users
 WHERE oracle_maintained = 'N'
 ORDER BY username;

PROMPT === (a) Cuentas con contraseña por defecto de Oracle ===
SELECT username FROM dba_users_with_defpwd ORDER BY 1;

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM dba_users_with_defpwd)                                   AS a_defpwd,
       (SELECT COUNT(*) FROM dba_users
         WHERE username IN ('VENTAS_LAB','SEGURIDAD_LAB','VENTAS_DEV')
           AND authentication_type = 'NONE')                                          AS b_esquemas_sin_login,
       (SELECT COUNT(*) FROM dba_users
         WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB')
           AND profile <> 'PERFIL_CONFIDENCIAL')                                      AS c_fuera_de_perfil,
       CASE WHEN (SELECT COUNT(*) FROM dba_users_with_defpwd) = 0
             AND (SELECT COUNT(*) FROM dba_users
                   WHERE username IN ('VENTAS_LAB','SEGURIDAD_LAB','VENTAS_DEV')
                     AND authentication_type = 'NONE') = 3
             AND (SELECT COUNT(*) FROM dba_users
                   WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB')
                     AND profile <> 'PERFIL_CONFIDENCIAL') = 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END                                        AS resultado
  FROM dual;
