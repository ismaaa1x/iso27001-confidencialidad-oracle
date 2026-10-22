-- =====================================================================
-- VC-10 | Control ISO: A.8.10 Eliminación de información
-- ---------------------------------------------------------------------
-- Comprobación   : No quedan copias "borradas pero recuperables" de datos
--                  confidenciales en la papelera de reciclaje (un DROP TABLE
--                  sin PURGE deja la tabla completa y legible como BIN$...).
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 10g+.  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-10_eliminacion.sql VC-10_eliminacion
-- Interpretación : CUMPLE si 0 objetos de VENTAS_LAB/VENTAS_DEV en la papelera.
-- Limitaciones   : - Solo cubre lo que está dentro de la base. Los datos
--                    también pueden quedar en respaldos, exports, archived logs
--                    y bloques libres del disco: su eliminación depende de la
--                    política de retención y del borrado del medio (PR-16
--                    muestra el borrado del export con shred).
--                  - En discos SSD o sistemas de archivos en capas (Docker),
--                    shred no garantiza el borrado físico; por eso es clave
--                    que esos archivos estén CIFRADOS (borrar la clave equivale
--                    a destruir el dato: "crypto-shredding").
-- =====================================================================

PROMPT === Parámetro de papelera ===
SELECT name AS parameter_name, value AS parameter_value FROM v$parameter WHERE name = 'recyclebin';

PROMPT === Objetos en la papelera de los esquemas con datos ===
SELECT owner, object_name, original_name AS original, type, droptime
  FROM dba_recyclebin
 WHERE owner IN ('VENTAS_LAB', 'VENTAS_DEV')
 ORDER BY droptime;

PROMPT === Resultado ===
SELECT COUNT(*) AS objetos_en_papelera,
       CASE WHEN COUNT(*) = 0 THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dba_recyclebin
 WHERE owner IN ('VENTAS_LAB', 'VENTAS_DEV');
