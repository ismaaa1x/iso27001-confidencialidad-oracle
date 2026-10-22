-- =====================================================================
-- 04_clasificacion.sql  -  Clasificación de la información en el diccionario
-- ---------------------------------------------------------------------
-- Propósito      : Dejar registrada la clasificación de cada columna
--                  (A.5.12; tareas T07 y T15). Así un auditor puede ver
--                  qué es confidencial sin depender de documentos externos.
-- Esquema usado  : PÚBLICO < INTERNO < CONFIDENCIAL < RESTRINGIDO
--                  (CONFIDENCIAL = dato personal, Ley 8968;
--                   RESTRINGIDO  = dato financiero/sensible).
-- Compatibilidad : Cualquier versión (COMMENT ON). En 23ai+ también
--                  podrían usarse ANNOTATIONS, pero no existen en 21c.
-- Privilegios    : SYSTEM (COMMENT ANY TABLE).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (solo comentarios del diccionario).
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/04_clasificacion.sql E-04_clasificacion
-- Limitación     : El comentario documenta la clasificación; no protege
--                  por sí mismo. La protección la dan VPD, Redaction y TDE.
-- =====================================================================

COMMENT ON TABLE ventas_lab.clientes IS '[CONFIDENCIAL] Clientes: contiene datos personales (Ley 8968). Propietario: Gerencia Comercial (ficticio)';
COMMENT ON COLUMN ventas_lab.clientes.id_cliente     IS '[INTERNO] Identificador técnico';
COMMENT ON COLUMN ventas_lab.clientes.nombre         IS '[CONFIDENCIAL] Dato personal';
COMMENT ON COLUMN ventas_lab.clientes.cedula         IS '[CONFIDENCIAL] Dato personal identificativo (Ley 8968)';
COMMENT ON COLUMN ventas_lab.clientes.correo         IS '[CONFIDENCIAL] Dato personal de contacto';
COMMENT ON COLUMN ventas_lab.clientes.telefono       IS '[CONFIDENCIAL] Dato personal de contacto';
COMMENT ON COLUMN ventas_lab.clientes.tarjeta        IS '[RESTRINGIDO] Dato financiero: enmascarado para todos salvo cuentas exentas';
COMMENT ON COLUMN ventas_lab.clientes.vendedor       IS '[INTERNO] Vendedor asignado (usado por VPD)';
COMMENT ON COLUMN ventas_lab.clientes.fecha_registro IS '[INTERNO] Fecha de alta';

COMMENT ON TABLE ventas_lab.ventas IS '[INTERNO] Ventas por cliente';
COMMENT ON COLUMN ventas_lab.ventas.id_venta   IS '[INTERNO] Identificador técnico';
COMMENT ON COLUMN ventas_lab.ventas.id_cliente IS '[INTERNO] Referencia al cliente (permite vincular con datos personales)';
COMMENT ON COLUMN ventas_lab.ventas.vendedor   IS '[INTERNO] Vendedor (usado por VPD)';
COMMENT ON COLUMN ventas_lab.ventas.monto      IS '[CONFIDENCIAL] Información comercial';
COMMENT ON COLUMN ventas_lab.ventas.fecha      IS '[INTERNO] Fecha de la venta';

PROMPT === Verificación: inventario de columnas clasificadas ===
SELECT table_name, column_name, comments
  FROM dba_col_comments
 WHERE owner = 'VENTAS_LAB' AND table_name IN ('CLIENTES', 'VENTAS')
 ORDER BY table_name, column_name;
