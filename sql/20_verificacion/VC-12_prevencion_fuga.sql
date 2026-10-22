-- =====================================================================
-- VC-12 | Control ISO: A.8.12 Prevención de fuga de datos
-- ---------------------------------------------------------------------
-- Comprobación   : Defensa en capas contra la fuga de datos desde la base:
--                  (a) prevención: las tablas con datos personales están en un
--                      tablespace cifrado con TDE y el keystore está abierto;
--                  (b) detección: hay auditoría habilitada sobre las lecturas de
--                      esas tablas y sobre el uso de SELECT ANY TABLE.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 19c+ (WALLET_ROOT). TDE incluido en Free/XE.
-- Privilegios    : SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-12_prevencion_fuga.sql VC-12_prevencion_fuga
-- Interpretación : CUMPLE si (a) 100 % de las tablas de VENTAS_LAB en
--                  tablespaces cifrados y keystore OPEN, y (b) políticas de
--                  acceso y de privilegios amplios habilitadas.
-- Limitación     : Un DLP completo también vigila correo, USB, nube, etc.
--                  (fuera de la base). Este control cubre la parte que
--                  corresponde al DBA. TDE protege los ARCHIVOS: un usuario
--                  autorizado que consulta la tabla ve los datos en claro.
-- =====================================================================

PROMPT === (a) Ubicación de las tablas y cifrado del tablespace ===
SELECT t.table_name, t.tablespace_name, ts.encrypted
  FROM dba_tables t JOIN dba_tablespaces ts ON ts.tablespace_name = t.tablespace_name
 WHERE t.owner = 'VENTAS_LAB'
 ORDER BY t.table_name;

SELECT ts.name AS tablespace_name, e.encryptionalg, e.encryptedts, e.status
  FROM v$encrypted_tablespaces e JOIN v$tablespace ts ON ts.ts# = e.ts# AND ts.con_id = e.con_id;

SELECT wrl_type, status, wallet_type FROM v$encryption_wallet;

PROMPT === (b) Políticas de detección habilitadas ===
SELECT policy_name, enabled_option, entity_name FROM audit_unified_enabled_policies
 WHERE policy_name IN ('POL_CONF_ACCESO_DATOS', 'POL_CONF_PRIVILEGIOS_AMPLIOS');

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM dba_tables t JOIN dba_tablespaces ts ON ts.tablespace_name = t.tablespace_name
         WHERE t.owner = 'VENTAS_LAB' AND t.table_name IN ('CLIENTES', 'VENTAS') AND ts.encrypted = 'YES') AS a_tablas_cifradas,
       (SELECT status FROM v$encryption_wallet)                                                            AS a_keystore,
       (SELECT COUNT(DISTINCT policy_name) FROM audit_unified_enabled_policies
         WHERE policy_name IN ('POL_CONF_ACCESO_DATOS', 'POL_CONF_PRIVILEGIOS_AMPLIOS'))                    AS b_politicas,
       CASE WHEN (SELECT COUNT(*) FROM dba_tables t JOIN dba_tablespaces ts ON ts.tablespace_name = t.tablespace_name
                   WHERE t.owner = 'VENTAS_LAB' AND t.table_name IN ('CLIENTES', 'VENTAS') AND ts.encrypted = 'YES') = 2
             AND (SELECT status FROM v$encryption_wallet) = 'OPEN'
             AND (SELECT COUNT(DISTINCT policy_name) FROM audit_unified_enabled_policies
                   WHERE policy_name IN ('POL_CONF_ACCESO_DATOS', 'POL_CONF_PRIVILEGIOS_AMPLIOS')) = 2
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
