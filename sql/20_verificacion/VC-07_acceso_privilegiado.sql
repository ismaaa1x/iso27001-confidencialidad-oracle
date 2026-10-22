-- =====================================================================
-- VC-07 | Control ISO: A.8.2 Derechos de acceso privilegiado
-- ---------------------------------------------------------------------
-- Comprobación   : Ninguna cuenta que no sea de administración de Oracle tiene
--                  el rol DBA, privilegios de sistema "ANY", ni privilegios de
--                  exención (EXEMPT ACCESS/REDACTION POLICY).
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+ (columna ORACLE_MAINTAINED).
-- Privilegios    : SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-07_acceso_privilegiado.sql VC-07_acceso_privilegiado
-- Interpretación : CUMPLE si 0 hallazgos. NO CUMPLE si aparece alguna cuenta.
--                  En el laboratorio se espera que APP_RIESGO aparezca ANTES de
--                  la corrección (sql/40_actuar) y desaparezca DESPUÉS.
-- Limitación     : Las cuentas mantenidas por Oracle (SYS, SYSTEM) se listan
--                  aparte como información: su control es la auditoría (VC-14)
--                  y la separación de funciones, no la revocación.
-- =====================================================================

PROMPT === Hallazgos: cuentas no administrativas con privilegios amplios ===
SELECT u.username AS grantee, 'ROL DBA' AS privilege
  FROM dba_users u JOIN dba_role_privs r ON r.grantee = u.username
 WHERE u.oracle_maintained = 'N' AND r.granted_role = 'DBA'
UNION ALL
SELECT u.username, p.privilege
  FROM dba_users u JOIN dba_sys_privs p ON p.grantee = u.username
 WHERE u.oracle_maintained = 'N'
   AND (p.privilege LIKE '% ANY %' OR p.privilege LIKE 'EXEMPT%'
        OR p.privilege IN ('GRANT ANY PRIVILEGE', 'GRANT ANY ROLE', 'ALTER SYSTEM'))
UNION ALL
SELECT r.role, p.privilege
  FROM dba_roles r JOIN dba_sys_privs p ON p.grantee = r.role
 WHERE r.role IN ('VENDEDORES', 'SOPORTE_CONSULTA', 'CONEXION_LAB')
   AND (p.privilege LIKE '% ANY %' OR p.privilege LIKE 'EXEMPT%')
 ORDER BY 1, 2;

PROMPT === Información: cuentas administrativas de Oracle con rol DBA ===
SELECT grantee FROM dba_role_privs r JOIN dba_users u ON u.username = r.grantee
 WHERE r.granted_role = 'DBA' AND u.oracle_maintained = 'Y' ORDER BY 1;

PROMPT === Información: usuarios exentos de Redaction, directo o HEREDADO por roles ===
PROMPT (SYSTEM aparece porque el rol DBA incluye EXP_FULL_DATABASE, que tiene EXEMPT REDACTION POLICY)
SELECT DISTINCT u.username, u.oracle_maintained AS interna
  FROM dba_users u
 WHERE u.username IN (SELECT grantee FROM dba_sys_privs WHERE privilege = 'EXEMPT REDACTION POLICY'
                      UNION
                      SELECT grantee FROM dba_role_privs
                       START WITH granted_role IN (SELECT grantee FROM dba_sys_privs
                                                    WHERE privilege = 'EXEMPT REDACTION POLICY')
                       CONNECT BY NOCYCLE PRIOR grantee = granted_role)
 ORDER BY 1;

PROMPT === Resultado ===
SELECT COUNT(*) AS hallazgos,
       CASE WHEN COUNT(*) = 0 THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM (SELECT u.username FROM dba_users u JOIN dba_role_privs r ON r.grantee = u.username
         WHERE u.oracle_maintained = 'N' AND r.granted_role = 'DBA'
        UNION ALL
        SELECT u.username FROM dba_users u JOIN dba_sys_privs p ON p.grantee = u.username
         WHERE u.oracle_maintained = 'N'
           AND (p.privilege LIKE '% ANY %' OR p.privilege LIKE 'EXEMPT%'
                OR p.privilege IN ('GRANT ANY PRIVILEGE', 'GRANT ANY ROLE', 'ALTER SYSTEM'))
        UNION ALL
        SELECT r.role FROM dba_roles r JOIN dba_sys_privs p ON p.grantee = r.role
         WHERE r.role IN ('VENDEDORES', 'SOPORTE_CONSULTA', 'CONEXION_LAB')
           AND (p.privilege LIKE '% ANY %' OR p.privilege LIKE 'EXEMPT%'));
