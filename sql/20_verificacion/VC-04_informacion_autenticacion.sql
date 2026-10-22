-- =====================================================================
-- VC-04 | Control ISO: A.5.17 Información de autenticación
-- ---------------------------------------------------------------------
-- Comprobación   : Las contraseñas de las cuentas con acceso a datos
--                  confidenciales están sujetas a: función de complejidad,
--                  vigencia máxima y no reutilización.
--                  Se revisa también el perfil DEFAULT, que usan las demás
--                  cuentas de la base (incluida SYSTEM).
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+.  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-04_informacion_autenticacion.sql VC-04_autenticacion_info
-- Interpretación : CUMPLE   = ambos perfiles con función de verificación,
--                             vida <= 90 días y REUSE_MAX definido.
--                  PARCIAL  = solo PERFIL_CONFIDENCIAL cumple (DEFAULT no).
--                  NO CUMPLE= PERFIL_CONFIDENCIAL tampoco cumple.
-- Limitación     : El perfil DEFAULT NO se modificó en el laboratorio porque es
--                  una política global de la base (afecta cuentas que no son
--                  del laboratorio). Su cambio se propone en la fase Actuar.
-- =====================================================================

PROMPT === Parámetros de contraseña por perfil ===
SELECT profile, resource_name, limit
  FROM dba_profiles
 WHERE profile IN ('PERFIL_CONFIDENCIAL', 'DEFAULT')
   AND resource_type = 'PASSWORD'
 ORDER BY profile, resource_name;

PROMPT === Resultado ===
WITH evaluacion AS (
  SELECT profile,
         CASE WHEN MAX(CASE WHEN resource_name = 'PASSWORD_VERIFY_FUNCTION' THEN limit END) NOT IN ('NULL', 'DEFAULT')
               AND MAX(CASE WHEN resource_name = 'PASSWORD_LIFE_TIME' THEN limit END) NOT IN ('UNLIMITED', 'DEFAULT')
               AND TO_NUMBER(MAX(CASE WHEN resource_name = 'PASSWORD_LIFE_TIME' THEN limit END)
                             DEFAULT 9999 ON CONVERSION ERROR) <= 90
               AND MAX(CASE WHEN resource_name = 'PASSWORD_REUSE_MAX' THEN limit END) NOT IN ('UNLIMITED', 'DEFAULT')
              THEN 1 ELSE 0 END AS ok
    FROM dba_profiles
   WHERE profile IN ('PERFIL_CONFIDENCIAL', 'DEFAULT')
   GROUP BY profile)
SELECT MAX(CASE WHEN profile = 'PERFIL_CONFIDENCIAL' THEN ok END) AS perfil_confidencial_ok,
       MAX(CASE WHEN profile = 'DEFAULT' THEN ok END)             AS perfil_default_ok,
       CASE WHEN MIN(ok) = 1 THEN 'CUMPLE'
            WHEN MAX(CASE WHEN profile = 'PERFIL_CONFIDENCIAL' THEN ok END) = 1 THEN 'PARCIAL'
            ELSE 'NO CUMPLE' END                                  AS resultado
  FROM evaluacion;
