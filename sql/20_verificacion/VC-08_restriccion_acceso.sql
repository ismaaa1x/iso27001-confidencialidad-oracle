-- =====================================================================
-- VC-08 | Control ISO: A.8.3 Restricción del acceso a la información
-- ---------------------------------------------------------------------
-- Comprobación   : (a) las tablas con datos personales tienen políticas VPD
--                      habilitadas para SELECT/INSERT/UPDATE/DELETE;
--                  (b) ninguna cuenta común (no mantenida por Oracle) está
--                      exenta de VPD, ni directamente ni HEREDANDO el privilegio
--                      EXEMPT ACCESS POLICY a través de roles.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+ (ORACLE_MAINTAINED).  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-08_restriccion_acceso.sql VC-08_restriccion_acceso
-- Interpretación : CUMPLE si (a) 2 tablas protegidas y (b) 0 cuentas comunes exentas.
--                  Las cuentas internas de Oracle con la exención (SYS, GoldenGate,
--                  GSM) se listan como información: no se usan en el laboratorio.
-- Limitación     : Confirma que la política existe; que FILTRE correctamente
--                  se demuestra con las pruebas PR-01, PR-02 y PR-10.
-- =====================================================================

PROMPT === (a) Políticas VPD ===
SELECT object_owner, object_name, policy_name, pf_owner, function,
       sel, ins, upd, del, chk_option, enable, policy_type
  FROM dba_policies
 WHERE object_owner = 'VENTAS_LAB'
 ORDER BY object_name;

PROMPT === Reglas de acceso configuradas ===
SELECT usuario, alcance FROM seguridad_lab.reglas_acceso ORDER BY usuario;

PROMPT === (b) Información: titulares directos de EXEMPT ACCESS POLICY ===
SELECT grantee, privilege FROM dba_sys_privs WHERE privilege = 'EXEMPT ACCESS POLICY' ORDER BY 1;

PROMPT === (b) Cuentas COMUNES exentas de VPD (directo o por roles) - se espera ninguna ===
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N'
   AND u.username IN (SELECT grantee FROM dba_sys_privs WHERE privilege = 'EXEMPT ACCESS POLICY'
                      UNION
                      SELECT grantee FROM dba_role_privs
                       START WITH granted_role IN (SELECT grantee FROM dba_sys_privs
                                                    WHERE privilege = 'EXEMPT ACCESS POLICY')
                       CONNECT BY NOCYCLE PRIOR grantee = granted_role);

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM dba_policies
         WHERE object_owner = 'VENTAS_LAB' AND object_name IN ('CLIENTES', 'VENTAS')
           AND enable = 'YES' AND sel = 'YES' AND ins = 'YES' AND upd = 'YES' AND del = 'YES') AS a_tablas_protegidas,
       (SELECT COUNT(*) FROM dba_users u
         WHERE u.oracle_maintained = 'N'
           AND u.username IN (SELECT grantee FROM dba_sys_privs WHERE privilege = 'EXEMPT ACCESS POLICY'
                              UNION
                              SELECT grantee FROM dba_role_privs
                               START WITH granted_role IN (SELECT grantee FROM dba_sys_privs
                                                            WHERE privilege = 'EXEMPT ACCESS POLICY')
                               CONNECT BY NOCYCLE PRIOR grantee = granted_role))           AS b_comunes_exentas,
       CASE WHEN (SELECT COUNT(*) FROM dba_policies
                   WHERE object_owner = 'VENTAS_LAB' AND object_name IN ('CLIENTES', 'VENTAS')
                     AND enable = 'YES' AND sel = 'YES' AND ins = 'YES' AND upd = 'YES' AND del = 'YES') = 2
             AND (SELECT COUNT(*) FROM dba_users u
                   WHERE u.oracle_maintained = 'N'
                     AND u.username IN (SELECT grantee FROM dba_sys_privs WHERE privilege = 'EXEMPT ACCESS POLICY'
                                        UNION
                                        SELECT grantee FROM dba_role_privs
                                         START WITH granted_role IN (SELECT grantee FROM dba_sys_privs
                                                                      WHERE privilege = 'EXEMPT ACCESS POLICY')
                                         CONNECT BY NOCYCLE PRIOR grantee = granted_role)) = 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
