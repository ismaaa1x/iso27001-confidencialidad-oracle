-- =====================================================================
-- VC-02 | Control ISO: A.5.15 Control de acceso
-- ---------------------------------------------------------------------
-- Comprobación   : El acceso a los datos de negocio se concede SOLO mediante
--                  roles por función: ningún privilegio a PUBLIC y ningún
--                  privilegio de objeto directo a cuentas de personas.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : Cualquier versión.  Privilegios: SYSTEM.
-- Contenedor     : FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-02_control_acceso_roles.sql VC-02_control_acceso
-- Interpretación : CUMPLE si 0 concesiones a PUBLIC y 0 concesiones directas
--                  a usuarios sobre VENTAS_LAB/SEGURIDAD_LAB.
-- Limitación     : No evalúa privilegios de sistema (*ANY*): eso lo hace VC-07.
-- =====================================================================

PROMPT === Privilegios de objeto sobre los esquemas de negocio ===
SELECT p.grantee,
       CASE WHEN r.role IS NOT NULL THEN 'ROL'
            WHEN p.grantee = 'PUBLIC' THEN 'PUBLIC'
            ELSE 'USUARIO' END AS tipo,
       p.owner, p.table_name, p.privilege
  FROM dba_tab_privs p
  LEFT JOIN dba_roles r ON r.role = p.grantee
 WHERE p.owner IN ('VENTAS_LAB', 'SEGURIDAD_LAB')
 ORDER BY tipo, p.grantee, p.table_name, p.privilege;

PROMPT === Miembros de cada rol de negocio ===
SELECT granted_role AS role, grantee FROM dba_role_privs
 WHERE granted_role IN ('VENDEDORES', 'SOPORTE_CONSULTA') ORDER BY 1, 2;

PROMPT === Resultado ===
SELECT SUM(CASE WHEN p.grantee = 'PUBLIC' THEN 1 ELSE 0 END)                         AS a_public,
       SUM(CASE WHEN r.role IS NULL AND p.grantee <> 'PUBLIC' THEN 1 ELSE 0 END)     AS directos_a_usuarios,
       CASE WHEN COUNT(*) > 0
             AND SUM(CASE WHEN r.role IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END                                       AS resultado
  FROM dba_tab_privs p
  LEFT JOIN dba_roles r ON r.role = p.grantee
 WHERE p.owner IN ('VENTAS_LAB', 'SEGURIDAD_LAB');
