-- =====================================================================
-- 05_vpd.sql  -  Virtual Private Database (restricción por filas)
-- ---------------------------------------------------------------------
-- Propósito      : Cada vendedor ve y opera SOLO sus clientes y ventas
--                  (A.8.3; tarea T08; riesgos R-CONF-01 y R-CONF-04).
--                  Equivale a lo que otros motores llaman "Row Level Security".
-- Diseño         : La función de política vive en SEGURIDAD_LAB, separada
--                  del esquema de negocio. Las reglas están en una tabla:
--                    PROPIOS -> solo filas con vendedor = usuario de la sesión
--                    TODOS   -> todas las filas (soporte; columnas enmascaradas)
--                    sin regla -> ninguna fila ("denegar por defecto")
--                  Por eso incluso SYSTEM y APP_RIESGO (SELECT ANY TABLE)
--                  ven 0 filas: VPD solo lo saltan SYS y quien tenga
--                  EXEMPT ACCESS POLICY.
-- Compatibilidad : Oracle 8i+ (DBMS_RLS). Incluido en EE, XE y Free.
-- Privilegios    : SYSTEM (EXECUTE sobre DBMS_RLS, CREATE ANY TABLE/PROCEDURE).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (tabla de reglas, función y políticas VPD).
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/05_vpd.sql E-05_vpd
-- Limitaciones   : SYS y las cuentas con EXEMPT ACCESS POLICY no se ven
--                  afectados: ese riesgo se cubre con la auditoría (A.8.15).
-- =====================================================================

PROMPT === 1. Tabla de reglas de acceso ===
CREATE TABLE seguridad_lab.reglas_acceso (
  usuario  VARCHAR2(128) CONSTRAINT pk_reglas_acceso PRIMARY KEY,
  alcance  VARCHAR2(10)  NOT NULL CONSTRAINT ck_reglas_alcance CHECK (alcance IN ('PROPIOS', 'TODOS'))
);
INSERT INTO seguridad_lab.reglas_acceso VALUES ('JUAN', 'PROPIOS');
INSERT INTO seguridad_lab.reglas_acceso VALUES ('ANA', 'PROPIOS');
INSERT INTO seguridad_lab.reglas_acceso VALUES ('SOPORTE_LAB', 'TODOS');
COMMIT;

PROMPT === 2. Función de política (devuelve el predicado WHERE) ===
CREATE OR REPLACE FUNCTION seguridad_lab.fn_vpd_vendedor (
  p_esquema IN VARCHAR2,
  p_objeto  IN VARCHAR2
) RETURN VARCHAR2 AS
  v_alcance seguridad_lab.reglas_acceso.alcance%TYPE;
BEGIN
  SELECT alcance INTO v_alcance
    FROM seguridad_lab.reglas_acceso
   WHERE usuario = SYS_CONTEXT('USERENV', 'SESSION_USER');

  IF v_alcance = 'TODOS' THEN
    RETURN NULL;                                         -- sin filtro
  END IF;
  RETURN 'vendedor = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '1 = 0';                                      -- denegar por defecto
END;
/

PROMPT === 3. Políticas sobre CLIENTES y VENTAS ===
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'VENTAS_LAB',
    object_name     => 'CLIENTES',
    policy_name     => 'VPD_CLIENTES_VENDEDOR',
    function_schema => 'SEGURIDAD_LAB',
    policy_function => 'FN_VPD_VENDEDOR',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE,
    policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);

  DBMS_RLS.ADD_POLICY(
    object_schema   => 'VENTAS_LAB',
    object_name     => 'VENTAS',
    policy_name     => 'VPD_VENTAS_VENDEDOR',
    function_schema => 'SEGURIDAD_LAB',
    policy_function => 'FN_VPD_VENDEDOR',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE,
    policy_type     => DBMS_RLS.CONTEXT_SENSITIVE);
END;
/

PROMPT === Verificación ===
SELECT object_owner, object_name, policy_name, pf_owner, function, sel, ins, upd, del, enable
  FROM dba_policies
 WHERE object_owner = 'VENTAS_LAB'
 ORDER BY object_name;

PROMPT Consulta como SYSTEM (DBA sin EXEMPT ACCESS POLICY): se espera 0 filas
SELECT COUNT(*) AS filas_visibles_para_system FROM ventas_lab.clientes;
