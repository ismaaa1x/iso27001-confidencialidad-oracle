-- =====================================================================
-- VC-13 | Control ISO: A.8.13 Respaldo de la información
--         (enfoque: confidencialidad de los respaldos, no su disponibilidad)
-- ---------------------------------------------------------------------
-- Comprobación   : (a) RMAN cifra por defecto todos los respaldos (AES256 con
--                      el keystore de TDE) y la opción está habilitada en el motor;
--                  (b) la clave maestra de TDE tiene respaldo del keystore
--                      (sin él, los respaldos cifrados serían irrecuperables);
--                  (c) el directorio de exportación (DATA_PUMP_DIR) no es
--                      accesible para PUBLIC ni para cuentas de negocio.
-- Tipo           : SOLO LECTURA (HOST ls solo lista archivos).
-- Compatibilidad : 19c+.  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-13_respaldo.sql VC-13_respaldo
-- Interpretación : CUMPLE si (a) ENCRYPTION FOR DATABASE = ON y Backup
--                  Encryption = TRUE, y (c) 0 concesiones indebidas del
--                  directorio. (b) se revisa en el listado (ewallet_*.p12).
-- Limitaciones   : - En Oracle Free NO se pueden cifrar exports de Data Pump
--                    (ORA-00439, ver PR-16): un export lógico guarda en claro
--                    incluso los datos de tablas TDE (ORA-39173). Mientras se
--                    use Free, los exports deben cifrarse fuera de Oracle o
--                    evitarse para datos confidenciales.
--                  - El respaldo del keystore está en el MISMO servidor que los
--                    datos: en producción se guarda aparte (o en un HSM).
--                  - No se evalúa la disponibilidad (restauración): es otro
--                    pilar y otro proyecto del curso.
-- =====================================================================

PROMPT === (a) Opción habilitada y configuración de RMAN ===
SELECT parameter, value FROM v$option WHERE parameter = 'Backup Encryption';
SELECT name, value FROM v$rman_configuration WHERE name LIKE 'ENCRYPTION%' ORDER BY name;

PROMPT === (b) Archivos del keystore (incluye respaldos ewallet_*_antes_clave_maestra.p12) ===
HOST ls -l /opt/oracle/oradata/FREE/wallet/tde

PROMPT === (c) Directorio de exportación y quién puede usarlo ===
SELECT directory_name AS object_name, directory_path AS description FROM dba_directories
 WHERE directory_name = 'DATA_PUMP_DIR';
SELECT grantee, privilege FROM dba_tab_privs
 WHERE table_name = 'DATA_PUMP_DIR' ORDER BY grantee, privilege;

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM v$rman_configuration
         WHERE name = 'ENCRYPTION FOR DATABASE' AND value = 'ON')                         AS a_rman_cifrado,
       (SELECT value FROM v$option WHERE parameter = 'Backup Encryption')                 AS a_opcion,
       (SELECT COUNT(*) FROM dba_tab_privs
         WHERE table_name = 'DATA_PUMP_DIR'
           AND grantee IN ('PUBLIC','JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO',
                           'VENDEDORES','SOPORTE_CONSULTA','CONEXION_LAB'))               AS c_concesiones_indebidas,
       CASE WHEN (SELECT COUNT(*) FROM v$rman_configuration
                   WHERE name = 'ENCRYPTION FOR DATABASE' AND value = 'ON') = 1
             AND (SELECT value FROM v$option WHERE parameter = 'Backup Encryption') = 'TRUE'
             AND (SELECT COUNT(*) FROM dba_tab_privs
                   WHERE table_name = 'DATA_PUMP_DIR'
                     AND grantee IN ('PUBLIC','JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO',
                                     'VENDEDORES','SOPORTE_CONSULTA','CONEXION_LAB')) = 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
