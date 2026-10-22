-- =====================================================================
-- VC-01 | Control ISO: A.5.12 Clasificación de la información
-- ---------------------------------------------------------------------
-- Comprobación   : Toda columna de las tablas de negocio tiene una etiqueta
--                  de clasificación ([INTERNO], [CONFIDENCIAL], [RESTRINGIDO])
--                  registrada en el diccionario.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : Cualquier versión.  Privilegios: SELECT sobre DBA_* (SYSTEM).
-- Contenedor     : FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-01_clasificacion.sql VC-01_clasificacion
-- Interpretación : CUMPLE si 0 columnas sin etiqueta. NO CUMPLE en caso contrario.
-- Limitación     : Verifica que la clasificación está documentada, no que sea
--                  correcta: eso lo valida el propietario de la información.
-- =====================================================================

PROMPT === Inventario de clasificación ===
SELECT c.table_name, c.column_name, NVL(m.comments, '(SIN CLASIFICAR)') AS comments
  FROM dba_tab_columns c
  LEFT JOIN dba_col_comments m
         ON m.owner = c.owner AND m.table_name = c.table_name AND m.column_name = c.column_name
 WHERE c.owner = 'VENTAS_LAB' AND c.table_name IN ('CLIENTES', 'VENTAS')
 ORDER BY c.table_name, c.column_id;

PROMPT === Resultado ===
SELECT COUNT(*) AS columnas_sin_etiqueta,
       CASE WHEN COUNT(*) = 0 THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dba_tab_columns c
  LEFT JOIN dba_col_comments m
         ON m.owner = c.owner AND m.table_name = c.table_name AND m.column_name = c.column_name
 WHERE c.owner = 'VENTAS_LAB' AND c.table_name IN ('CLIENTES', 'VENTAS')
   AND (m.comments IS NULL OR NOT REGEXP_LIKE(m.comments, '^\[(PUBLICO|INTERNO|CONFIDENCIAL|RESTRINGIDO)\]'));
