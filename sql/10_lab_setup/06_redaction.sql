-- =====================================================================
-- 06_redaction.sql  -  Oracle Data Redaction (enmascaramiento dinámico)
-- ---------------------------------------------------------------------
-- Propósito      : Enmascarar datos en el momento de la consulta, sin
--                  modificar lo almacenado (A.8.11, A.8.3; tarea T07;
--                  riesgos R-CONF-01 y R-CONF-04). Equivale a lo que SQL
--                  Server llama "Dynamic Data Masking".
-- Reglas         : TARJETA -> todos ven solo los últimos 4 dígitos
--                  CEDULA  -> los vendedores la ven completa (la necesitan
--                             para facturar); los demás la ven enmascarada
--                  CORREO  -> los vendedores lo ven; los demás ven xxxx@dominio
-- Compatibilidad : 12.2+ (expresiones por columna). Incluido en Free/XE;
--                  en EE requiere la opción Advanced Security.
-- Privilegios    : SYSTEM (EXECUTE sobre DBMS_REDACT / ADMINISTER REDACTION POLICY).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (crea la política de redacción).
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/06_redaction.sql E-06_redaction
-- Limitaciones   : - No aplica a quien tenga EXEMPT REDACTION POLICY
--                    (por ejemplo el rol DBA, y por tanto SYSTEM).
--                  - Protege la presentación del dato, no su almacenamiento
--                    (eso lo hace TDE). Un usuario que conozca el dato puede
--                    inferirlo con consultas repetidas usando WHERE; Oracle
--                    lo advierte en su documentación. Por eso se combina con
--                    VPD y auditoría.
-- =====================================================================

PROMPT === 1. Política base: tarjeta enmascarada para todos (expresión 1=1) ===
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema       => 'VENTAS_LAB',
    object_name         => 'CLIENTES',
    policy_name         => 'RED_CLIENTES_DATOS_PERSONALES',
    column_name         => 'TARJETA',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => DBMS_REDACT.REDACT_CCN16_F12,   -- ****-****-****-1234
    expression          => '1=1',
    policy_description  => 'Enmascaramiento de datos personales y financieros (A.8.11)',
    column_description  => 'Tarjeta: solo últimos 4 dígitos');
END;
/

PROMPT === 2. Expresión con nombre: "la sesión NO tiene el rol VENDEDORES" ===
BEGIN
  DBMS_REDACT.CREATE_POLICY_EXPRESSION(
    policy_expression_name        => 'EXPR_NO_VENDEDOR',
    expression                    => 'SYS_CONTEXT(''SYS_SESSION_ROLES'', ''VENDEDORES'') = ''FALSE''',
    policy_expression_description => 'Se enmascara cuando la sesión no tiene el rol VENDEDORES');
END;
/

PROMPT === 3. Cédula: enmascarada salvo para vendedores (formato 1-2345-6789) ===
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema       => 'VENTAS_LAB',
    object_name         => 'CLIENTES',
    policy_name         => 'RED_CLIENTES_DATOS_PERSONALES',
    action              => DBMS_REDACT.ADD_COLUMN,
    column_name         => 'CEDULA',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => 'VFVVVVFVVVV,V-VVVV-VVVV,*,1,5',  -- *-****-6789
    column_description  => 'Cédula: últimos 4 dígitos para no vendedores');

  DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
    object_schema          => 'VENTAS_LAB',
    object_name            => 'CLIENTES',
    column_name            => 'CEDULA',
    policy_expression_name => 'EXPR_NO_VENDEDOR');
END;
/

PROMPT === 4. Correo: se oculta el nombre de usuario salvo para vendedores ===
BEGIN
  DBMS_REDACT.ALTER_POLICY(
    object_schema          => 'VENTAS_LAB',
    object_name            => 'CLIENTES',
    policy_name            => 'RED_CLIENTES_DATOS_PERSONALES',
    action                 => DBMS_REDACT.ADD_COLUMN,
    column_name            => 'CORREO',
    function_type          => DBMS_REDACT.REGEXP,
    regexp_pattern         => DBMS_REDACT.RE_PATTERN_EMAIL_ADDRESS,
    regexp_replace_string  => DBMS_REDACT.RE_REDACT_EMAIL_NAME,
    regexp_position        => DBMS_REDACT.RE_BEGINNING,
    regexp_occurrence      => DBMS_REDACT.RE_ALL,
    column_description     => 'Correo: nombre de usuario oculto para no vendedores');

  DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
    object_schema          => 'VENTAS_LAB',
    object_name            => 'CLIENTES',
    column_name            => 'CORREO',
    policy_expression_name => 'EXPR_NO_VENDEDOR');
END;
/

PROMPT === Verificación ===
SELECT object_owner, object_name, policy_name, expression, enable FROM redaction_policies;
SELECT object_owner, object_name, column_name, function_type, function_parameters FROM redaction_columns ORDER BY column_name;
SELECT policy_expression_name, expression FROM redaction_expressions;
