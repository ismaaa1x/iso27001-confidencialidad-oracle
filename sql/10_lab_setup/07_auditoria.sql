-- =====================================================================
-- 07_auditoria.sql  -  Auditoría unificada y Fine-Grained Auditing
-- ---------------------------------------------------------------------
-- Propósito      : Registrar QUIÉN, CUÁNDO, DESDE DÓNDE y QUÉ hizo sobre
--                  los datos confidenciales y sobre la gestión de accesos
--                  (A.8.15, A.8.2, A.8.12; tarea T10; riesgo R-CONF-05).
--                  Es la "Struct {día, hora, usuario, sesión, SQL text}"
--                  de la pizarra, implementada con UNIFIED_AUDIT_TRAIL.
-- Por qué no SYS.AUD$: el diagnóstico E-00 mostró Unified Auditing = TRUE
--                  y audit_trail = NONE. SYS.AUD$ pertenece a la auditoría
--                  tradicional (obsoleta desde 21c, retirada en 23ai/26ai).
-- Compatibilidad : 12.1+ (auditoría unificada). Probado en 26ai Free.
-- Privilegios    : SYSTEM (AUDIT SYSTEM; EXECUTE sobre DBMS_FGA).
-- Contenedor     : FREEPDB1 (las políticas son locales al PDB).
-- MODIFICA       : SÍ (crea y habilita políticas de auditoría).
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/07_auditoria.sql E-07_auditoria
-- Limitaciones   : - La auditoría DETECTA y permite investigar; no impide
--                    el acceso.
--                  - Un usuario con AUDIT_ADMIN podría desactivar políticas;
--                    esa acción también queda auditada (ORA_SECURECONFIG).
--                  - Auditar todos los SELECT genera volumen: en producción
--                    se limita a objetos sensibles, como aquí.
-- =====================================================================

PROMPT === 1. Acceso a los datos confidenciales (éxito y fallo) ===
CREATE AUDIT POLICY pol_conf_acceso_datos
  ACTIONS SELECT  ON ventas_lab.clientes,
          INSERT  ON ventas_lab.clientes,
          UPDATE  ON ventas_lab.clientes,
          DELETE  ON ventas_lab.clientes,
          SELECT  ON ventas_lab.ventas,
          INSERT  ON ventas_lab.ventas,
          UPDATE  ON ventas_lab.ventas,
          DELETE  ON ventas_lab.ventas,
          EXECUTE ON ventas_lab.registrar_venta;
AUDIT POLICY pol_conf_acceso_datos;

PROMPT === 2. Gestión de identidades y privilegios ===
CREATE AUDIT POLICY pol_conf_gestion_accesos
  ACTIONS CREATE USER, ALTER USER, DROP USER,
          CREATE ROLE, DROP ROLE, GRANT, REVOKE,
          CREATE PROFILE, ALTER PROFILE, DROP PROFILE;
AUDIT POLICY pol_conf_gestion_accesos;

PROMPT === 3. Uso de privilegios amplios (SELECT ANY TABLE) ===
-- Registra cada vez que alguien usa realmente ese privilegio: detecta
-- tanto a APP_RIESGO como a un DBA consultando datos de negocio.
CREATE AUDIT POLICY pol_conf_privilegios_amplios
  PRIVILEGES SELECT ANY TABLE, UPDATE ANY TABLE, DELETE ANY TABLE, EXPORT FULL DATABASE;
AUDIT POLICY pol_conf_privilegios_amplios;

PROMPT === 4. Cambios en los controles de confidencialidad (VPD, Redaction, FGA) ===
CREATE AUDIT POLICY pol_conf_cambios_controles
  ACTIONS EXECUTE ON sys.dbms_rls,
          EXECUTE ON sys.dbms_redact,
          EXECUTE ON sys.dbms_fga;
AUDIT POLICY pol_conf_cambios_controles;

PROMPT === 5. Fine-Grained Auditing: solo cuando se consulta la columna TARJETA ===
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema     => 'VENTAS_LAB',
    object_name       => 'CLIENTES',
    policy_name       => 'FGA_CONSULTA_TARJETA',
    audit_column      => 'TARJETA',
    statement_types   => 'SELECT',
    audit_column_opts => DBMS_FGA.ANY_COLUMNS,
    enable            => TRUE);
END;
/

PROMPT === Verificación: políticas habilitadas ===
SELECT policy_name, enabled_option, entity_name, success, failure
  FROM audit_unified_enabled_policies
 ORDER BY policy_name;
SELECT object_schema, object_name, policy_name, enabled FROM dba_audit_policies;
