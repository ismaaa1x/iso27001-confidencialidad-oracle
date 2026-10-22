-- =====================================================================
-- 09_copia_dev_enmascarada.sql  -  Copia para desarrollo con enmascaramiento ESTÁTICO
-- ---------------------------------------------------------------------
-- Propósito      : Entregar a desarrollo/pruebas una copia SIN datos reales
--                  (A.8.11, A.5.12; tarea T15; riesgo R-CONF-04).
--                  A diferencia de Data Redaction (dinámico), aquí los
--                  datos se REEMPLAZAN físicamente en la copia: aunque
--                  alguien tenga acceso total a VENTAS_DEV, no hay nada
--                  real que filtrar.
-- Alternativa    : Oracle ofrece "Data Masking and Subsetting" (paquete de
--                  Enterprise Manager). No se usa porque requiere OEM; este
--                  script implementa el mismo principio con SQL y conserva
--                  el formato de los datos.
-- Compatibilidad : Cualquier versión.
-- Privilegios    : SYSDBA en el PDB. Se usa SYS porque debe leer los datos
--                  reales sin VPD ni Redaction (SYS no se ve afectado). En
--                  una organización real lo hace una cuenta de servicio con
--                  EXEMPT ACCESS POLICY, auditada y usada solo en esta tarea.
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (crea tablas en VENTAS_DEV).
-- Ejecución      : herramientas/ejecutar.sh sysdba-pdb sql/10_lab_setup/09_copia_dev_enmascarada.sql E-09_copia_dev
-- Limitación     : Simula el resultado de un clon (no clona el PDB completo,
--                  por los límites de recursos de Free). El proceso sería el
--                  mismo tras un CREATE PLUGGABLE DATABASE ... FROM.
-- =====================================================================

PROMPT === 1. Copia enmascarada de CLIENTES (formato preservado, valores falsos) ===
CREATE TABLE ventas_dev.clientes TABLESPACE ts_sin_cifrar AS
SELECT id_cliente,
       'Cliente DEV ' || LPAD(id_cliente, 3, '0')                       AS nombre,
       '0-' || LPAD(MOD(id_cliente * 811, 10000), 4, '0')
            || '-' || LPAD(MOD(id_cliente * 449, 10000), 4, '0')        AS cedula,
       'dev' || LPAD(id_cliente, 3, '0') || '@ejemplo.invalid'          AS correo,
       '0000-' || LPAD(id_cliente, 4, '0')                              AS telefono,
       '0000-0000-0000-' || LPAD(id_cliente, 4, '0')                    AS tarjeta,
       vendedor,
       fecha_registro
  FROM ventas_lab.clientes;

PROMPT === 2. Copia de VENTAS (no contiene datos personales directos) ===
CREATE TABLE ventas_dev.ventas TABLESPACE ts_sin_cifrar AS
SELECT id_venta, id_cliente, vendedor, monto, fecha FROM ventas_lab.ventas;

COMMENT ON TABLE ventas_dev.clientes IS '[INTERNO] Copia enmascarada para desarrollo: no contiene datos reales';

PROMPT === Verificación: ningún valor sensible de producción aparece en la copia ===
SELECT COUNT(*) AS filas_copiadas FROM ventas_dev.clientes;
SELECT COUNT(*) AS coincidencias_reales
  FROM ventas_dev.clientes d
  JOIN ventas_lab.clientes p ON p.id_cliente = d.id_cliente
 WHERE d.cedula = p.cedula OR d.tarjeta = p.tarjeta
    OR d.correo = p.correo OR d.telefono = p.telefono OR d.nombre = p.nombre;
SELECT id_cliente, nombre, cedula, correo, tarjeta FROM ventas_dev.clientes WHERE id_cliente <= 3;
