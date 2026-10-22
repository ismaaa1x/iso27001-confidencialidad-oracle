-- =====================================================================
-- 00_entorno.sql  -  Diagnóstico del entorno Oracle (SOLO LECTURA)
-- ---------------------------------------------------------------------
-- Propósito      : Registrar versión, edición, arquitectura CDB/PDB,
--                  modo de auditoría, keystore TDE y privilegios de la
--                  sesión. Es la línea base (Planificar) del PHVA.
-- Compatibilidad : Oracle AI Database 26ai Free (23.26). Funciona también
--                  en 19c/21c; en 21c la fila 'Unified Auditing' de
--                  V$OPTION distingue modo mixto (FALSE) de puro (TRUE).
-- Privilegios    : SYSTEM o un usuario con SELECT_CATALOG_ROLE
--                  (las vistas V$ requieren acceso al diccionario).
-- Contenedor     : Ejecutar en el PDB de trabajo (FREEPDB1). Algunas
--                  columnas cambian si se ejecuta en CDB$ROOT.
-- Modifica algo  : NO. Solo consultas SELECT.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100
COLUMN banner_full FORMAT A80
COLUMN name FORMAT A30
COLUMN value FORMAT A60
COLUMN parameter FORMAT A30
COLUMN wrl_parameter FORMAT A40

PROMPT === 1. Contenedor actual (debe ser el PDB de trabajo) ===
SHOW CON_NAME

PROMPT === 2. Versión y edición ===
SELECT banner_full FROM v$version;

PROMPT === 2b. Parches aplicados (tarea T12: comparar con el último Release Update publicado) ===
COLUMN description FORMAT A60
SELECT patch_id, action, status, TO_CHAR(action_time, 'YYYY-MM-DD') AS fecha, description
  FROM dba_registry_sqlpatch ORDER BY action_time;

PROMPT === 3. Base de datos: ¿es CDB?, modo de apertura y de log ===
-- LOG_MODE = NOARCHIVELOG implica que no hay archived logs (relevante
-- para LogMiner y para la recuperación, no para la confidencialidad).
SELECT name, cdb, open_mode, log_mode FROM v$database;

PROMPT === 4. PDBs visibles desde este contenedor ===
SELECT con_id, name, open_mode FROM v$pdbs ORDER BY con_id;

PROMPT === 5. Mecanismo de auditoría ===
-- TRUE  = auditoría unificada pura  -> fuente: UNIFIED_AUDIT_TRAIL
-- FALSE = modo mixto (unificada + tradicional) -> fuente principal sigue
--         siendo UNIFIED_AUDIT_TRAIL; SYS.AUD$ solo si AUDIT_TRAIL=DB.
SELECT parameter, value FROM v$option WHERE parameter = 'Unified Auditing';

PROMPT === 5b. Opciones de seguridad habilitadas en ESTE motor ===
-- La guía de licencias dice qué se PUEDE usar; V$OPTION dice qué está
-- realmente habilitado en el binario instalado.
COLUMN parameter FORMAT A40
COLUMN value FORMAT A10
SELECT parameter, value FROM v$option
 WHERE parameter IN ('Transparent Data Encryption', 'Backup Encryption', 'Data Redaction',
                     'Fine-grained access control', 'Fine-grained Auditing', 'Privilege Analysis',
                     'Unified Auditing', 'Oracle Database Vault', 'Oracle Label Security',
                     'Real Application Security')
 ORDER BY parameter;

PROMPT === 6. Parámetros de seguridad relevantes ===
SELECT name, value
  FROM v$parameter
 WHERE name IN ('audit_trail', 'audit_sys_operations', 'wallet_root',
                'tde_configuration', 'remote_login_passwordfile',
                'sec_max_failed_login_attempts', 'sec_protocol_error_trace_action')
 ORDER BY name;

PROMPT === 7. Estado del keystore (wallet) TDE ===
-- STATUS = NOT_AVAILABLE / CLOSED indica que TDE aún no está configurado.
SELECT wrl_type, wrl_parameter, status, wallet_type, con_id
  FROM v$encryption_wallet;

PROMPT === 8. Roles y privilegios de la sesión que ejecuta el diagnóstico ===
SELECT role FROM session_roles ORDER BY role;
SELECT privilege FROM session_privs ORDER BY privilege;

-- Interpretación: guardar esta salida (SPOOL) como evidencia E-00.
-- Limitación: describe la configuración en el momento de la ejecución;
-- no demuestra que la configuración se haya mantenido en el tiempo.
