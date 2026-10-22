-- =====================================================================
-- 99_eliminar_laboratorio.sql  -  Elimina TODOS los objetos del laboratorio
-- ---------------------------------------------------------------------
-- Propósito      : Dejar el PDB como estaba antes del laboratorio para
--                  repetir la demostración desde cero. También ilustra la
--                  eliminación de información (A.8.10): DROP ... PURGE y
--                  tablespaces borrados INCLUDING CONTENTS AND DATAFILES.
-- Compatibilidad : 12.2+. Probado en 26ai Free.
-- Privilegios    : SYSDBA (necesario para el job de purga de auditoría y la
--                  captura de privilegios).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ. BORRA usuarios, roles, perfiles, políticas y
--                  tablespaces del laboratorio. NO toca el keystore TDE
--                  (se conserva: borrarlo dejaría ilegibles los respaldos
--                  hechos con esa clave) ni los registros de auditoría ya
--                  generados (son evidencia).
-- Ejecución      : herramientas/ejecutar.sh sysdba-pdb sql/90_limpieza/99_eliminar_laboratorio.sql E-99_limpieza
-- =====================================================================
SET SERVEROUTPUT ON

DECLARE
  PROCEDURE intentar(p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
    DBMS_OUTPUT.PUT_LINE('OK      ' || p_sql);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('OMITIDO ' || p_sql || '  -> ' || SQLERRM);
  END;
BEGIN
  -- Políticas de auditoría unificada
  FOR p IN (SELECT DISTINCT policy_name FROM audit_unified_enabled_policies
             WHERE policy_name LIKE 'POL_CONF%') LOOP
    intentar('NOAUDIT POLICY ' || p.policy_name);
  END LOOP;
  FOR p IN (SELECT DISTINCT policy_name FROM audit_unified_policies
             WHERE policy_name LIKE 'POL_CONF%') LOOP
    intentar('DROP AUDIT POLICY ' || p.policy_name);
  END LOOP;

  -- FGA, Redaction y VPD
  intentar(q'[BEGIN DBMS_FGA.DROP_POLICY('VENTAS_LAB','CLIENTES','FGA_CONSULTA_TARJETA'); END;]');
  intentar(q'[BEGIN DBMS_REDACT.DROP_POLICY('VENTAS_LAB','CLIENTES','RED_CLIENTES_DATOS_PERSONALES'); END;]');
  intentar(q'[BEGIN DBMS_REDACT.DROP_POLICY_EXPRESSION('EXPR_NO_VENDEDOR'); END;]');
  intentar(q'[BEGIN DBMS_RLS.DROP_POLICY('VENTAS_LAB','CLIENTES','VPD_CLIENTES_VENDEDOR'); END;]');
  intentar(q'[BEGIN DBMS_RLS.DROP_POLICY('VENTAS_LAB','VENTAS','VPD_VENTAS_VENDEDOR'); END;]');

  -- Retención de auditoría y captura de privilegios
  intentar(q'[BEGIN DBMS_AUDIT_MGMT.DROP_PURGE_JOB('PURGA_AUDITORIA_CONF_90D'); END;]');
  intentar(q'[BEGIN DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED); END;]');
  intentar(q'[BEGIN DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('CAP_LAB_CONF'); END;]');
  intentar(q'[BEGIN DBMS_PRIVILEGE_CAPTURE.DROP_CAPTURE('CAP_LAB_CONF'); END;]');

  -- Usuarios (CASCADE borra sus objetos)
  FOR u IN (SELECT username FROM dba_users
             WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO',
                                'PRUEBA_BLOQUEO','PRUEBA_IDLE','VENTAS_DEV','VENTAS_LAB','SEGURIDAD_LAB')) LOOP
    intentar('DROP USER ' || u.username || ' CASCADE');
  END LOOP;

  -- Roles y perfiles
  intentar('DROP ROLE vendedores');
  intentar('DROP ROLE soporte_consulta');
  intentar('DROP ROLE conexion_lab');
  intentar('DROP PROFILE perfil_confidencial CASCADE');
  intentar('DROP PROFILE perfil_prueba_idle CASCADE');

  -- Papelera y tablespaces (borra también los datafiles)
  intentar('PURGE DBA_RECYCLEBIN');
  intentar('DROP TABLESPACE ts_confidencial INCLUDING CONTENTS AND DATAFILES');
  intentar('DROP TABLESPACE ts_sin_cifrar INCLUDING CONTENTS AND DATAFILES');
END;
/

PROMPT === Verificación: no deben quedar objetos del laboratorio ===
SELECT COUNT(*) AS usuarios_lab FROM dba_users
 WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO','PRUEBA_BLOQUEO',
                    'PRUEBA_IDLE','VENTAS_DEV','VENTAS_LAB','SEGURIDAD_LAB');
SELECT COUNT(*) AS tablespaces_lab FROM dba_tablespaces
 WHERE tablespace_name IN ('TS_CONFIDENCIAL','TS_SIN_CIFRAR');
SELECT COUNT(*) AS politicas_lab FROM audit_unified_policies WHERE policy_name LIKE 'POL_CONF%';
