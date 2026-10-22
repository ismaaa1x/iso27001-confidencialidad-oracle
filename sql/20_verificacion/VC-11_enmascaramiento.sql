-- =====================================================================
-- VC-11 | Control ISO: A.8.11 Enmascaramiento de datos
-- ---------------------------------------------------------------------
-- Comprobación   : (a) enmascaramiento DINÁMICO: política de Data Redaction
--                      habilitada sobre TARJETA, CEDULA y CORREO;
--                  (b) enmascaramiento ESTÁTICO: la copia de desarrollo
--                      (VENTAS_DEV) no contiene ningún valor real.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.2+.
-- Privilegios    : SYSDBA en el PDB. Para comparar con los datos reales hay
--                  que leerlos sin VPD ni Redaction; SYSTEM no puede (VPD le
--                  devuelve 0 filas, lo cual daría un falso "CUMPLE").
-- Contenedor     : FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh sysdba-pdb sql/20_verificacion/VC-11_enmascaramiento.sql VC-11_enmascaramiento
-- Interpretación : CUMPLE si (a) 3 columnas con política habilitada y
--                  (b) 0 coincidencias entre la copia y producción.
-- Limitación     : Que lo enmascarado se VEA así para cada usuario se
--                  demuestra en las pruebas PR-03, PR-04 y PR-10.
-- =====================================================================

PROMPT === (a) Política de redacción y columnas ===
SELECT object_owner, object_name, policy_name, expression, enable FROM redaction_policies;
SELECT column_name, function_type, function_parameters FROM redaction_columns
 WHERE object_owner = 'VENTAS_LAB' ORDER BY column_name;

PROMPT === (b) Comparación copia DEV contra producción ===
SELECT COUNT(*) AS filas_dev FROM ventas_dev.clientes;

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM redaction_columns c JOIN redaction_policies p
           ON p.object_owner = c.object_owner AND p.object_name = c.object_name
         WHERE c.object_owner = 'VENTAS_LAB' AND c.object_name = 'CLIENTES'
           AND c.column_name IN ('TARJETA', 'CEDULA', 'CORREO') AND p.enable = 'YES') AS a_columnas_redactadas,
       (SELECT COUNT(*) FROM ventas_dev.clientes d
          JOIN ventas_lab.clientes p ON p.id_cliente = d.id_cliente
         WHERE d.cedula = p.cedula OR d.tarjeta = p.tarjeta OR d.correo = p.correo
            OR d.telefono = p.telefono OR d.nombre = p.nombre)                       AS b_coincidencias_reales,
       CASE WHEN (SELECT COUNT(*) FROM redaction_columns c JOIN redaction_policies p
                     ON p.object_owner = c.object_owner AND p.object_name = c.object_name
                   WHERE c.object_owner = 'VENTAS_LAB' AND c.object_name = 'CLIENTES'
                     AND c.column_name IN ('TARJETA', 'CEDULA', 'CORREO') AND p.enable = 'YES') = 3
             AND (SELECT COUNT(*) FROM ventas_dev.clientes d
                    JOIN ventas_lab.clientes p ON p.id_cliente = d.id_cliente
                   WHERE d.cedula = p.cedula OR d.tarjeta = p.tarjeta OR d.correo = p.correo
                      OR d.telefono = p.telefono OR d.nombre = p.nombre) = 0
             AND (SELECT COUNT(*) FROM ventas_dev.clientes) > 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
