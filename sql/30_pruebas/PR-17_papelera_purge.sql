-- =====================================================================
-- PR-17 | Negativa y corrección | Un DROP sin PURGE deja el dato recuperable
-- ---------------------------------------------------------------------
-- Control        : A.8.10 (riesgo R-CONF-03)          Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: SYSTEM.
-- Esperado       : (1) tras DROP TABLE la tabla sigue en DBA_RECYCLEBIN y su
--                      contenido se puede LEER con el nombre BIN$...;
--                  (2) tras PURGE desaparece de la papelera (VC-10 = CUMPLE).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-17_papelera_purge.sql PR-17_papelera
-- =====================================================================
CONNECT system/"&&pwd_system"@&&srv

PROMPT >>> Crear una copia temporal con un dato confidencial (marcador)
CREATE TABLE ventas_lab.copia_temporal TABLESPACE ts_confidencial AS
  SELECT texto FROM ventas_lab.prueba_tde_cifrado;

PROMPT >>> PR-17.1 DROP sin PURGE
DROP TABLE ventas_lab.copia_temporal;

PROMPT >>> Esperado: la tabla sigue en la papelera
SELECT owner, object_name, original_name AS original, droptime FROM dba_recyclebin
 WHERE owner = 'VENTAS_LAB' AND original_name = 'COPIA_TEMPORAL';

PROMPT >>> Esperado: el contenido "borrado" todavía se puede leer
COLUMN bin_name NEW_VALUE v_bin NOPRINT
SELECT object_name AS bin_name FROM dba_recyclebin
 WHERE owner = 'VENTAS_LAB' AND original_name = 'COPIA_TEMPORAL' FETCH FIRST 1 ROW ONLY;
SELECT texto FROM ventas_lab."&&v_bin";

PROMPT >>> PR-17.2 Eliminación definitiva
PURGE TABLE ventas_lab.copia_temporal;

PROMPT >>> Esperado: 0 objetos en la papelera
SELECT COUNT(*) AS en_papelera FROM dba_recyclebin WHERE owner = 'VENTAS_LAB';
