-- =====================================================================
-- A-02 | Actuar | Auditar los cambios a la configuración de seguridad (VPD)
-- ---------------------------------------------------------------------
-- Hallazgo       : PR-19 mostró que un DBA puede insertarse en la tabla de
--                  reglas de VPD y ver todos los datos, y que ese cambio no
--                  tenía una política de auditoría específica.
-- Evidencia      : En PR-19 (antes) el INSERT de SYSTEM en la tabla de reglas
--                  NO quedó registrado: la política de privilegios amplios
--                  cubre SELECT/UPDATE/DELETE ANY TABLE, pero no INSERT.
-- Corrección     : Auditar toda lectura o modificación de
--                  SEGURIDAD_LAB.REGLAS_ACCESO, la use quien la use. Los
--                  cambios a las políticas VPD ya se auditan (EXECUTE sobre
--                  DBMS_RLS en POL_CONF_CAMBIOS_CONTROLES). No IMPIDE el abuso
--                  (para eso se propone Database Vault, A-03), pero lo hace
--                  DETECTABLE.
-- Nota técnica   : Oracle no permite auditar ALTER sobre una función
--                  (ORA-46359); por eso la política cubre solo la tabla.
-- Controles      : A.8.15, A.8.2, A.5.33.   Privilegios: SYSTEM.   Contenedor: FREEPDB1.
-- MODIFICA       : SÍ (nueva política de auditoría).
-- Ejecución      : herramientas/ejecutar.sh system sql/40_actuar/A-02_auditar_reglas_seguridad.sql A-02_auditar_reglas
-- Verificación   : volver a ejecutar PR-19 -> el cambio aparece con la
--                  política POL_CONF_CAMBIOS_REGLAS.
-- =====================================================================
CREATE AUDIT POLICY pol_conf_cambios_reglas
  ACTIONS INSERT ON seguridad_lab.reglas_acceso,
          UPDATE ON seguridad_lab.reglas_acceso,
          DELETE ON seguridad_lab.reglas_acceso,
          SELECT ON seguridad_lab.reglas_acceso;
AUDIT POLICY pol_conf_cambios_reglas;

SELECT policy_name, enabled_option, entity_name FROM audit_unified_enabled_policies
 WHERE policy_name = 'POL_CONF_CAMBIOS_REGLAS';
