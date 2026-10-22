-- =====================================================================
-- VC-06 | Control ISO: A.5.33 Protección de registros
-- ---------------------------------------------------------------------
-- Comprobación   : El rastro de auditoría está protegido y tiene retención:
--                  (a) AUDSYS (dueño del rastro) no permite iniciar sesión;
--                  (b) ninguna cuenta del laboratorio puede administrar la
--                      auditoría (AUDIT_ADMIN); el auditor solo la lee;
--                  (c) existe un job de purga habilitado que respeta la fecha
--                      de último archivado.
-- Tipo           : SOLO LECTURA.
-- Compatibilidad : 12.1+.  Privilegios: SYSTEM.  Contenedor: FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-06_proteccion_registros.sql VC-06_proteccion_registros
-- Interpretación : CUMPLE si (a) AUDSYS bloqueada o sin autenticación,
--                  (b) 0 cuentas de laboratorio con AUDIT_ADMIN y
--                  (c) job de purga ENABLED.
-- Limitación     : SYS (y quien tenga SYSDBA) puede seguir actuando sobre el
--                  rastro. En una organización real los registros se envían
--                  además a un sistema externo (SIEM) fuera del alcance del DBA.
-- =====================================================================

PROMPT === (a) Cuenta dueña del rastro ===
SELECT username, account_status, authentication_type FROM dba_users WHERE username = 'AUDSYS';

PROMPT === (b) Quién puede administrar o leer la auditoría ===
SELECT granted_role AS role, grantee FROM dba_role_privs
 WHERE granted_role IN ('AUDIT_ADMIN', 'AUDIT_VIEWER') ORDER BY 1, 2;

PROMPT === (c) Retención: último archivado y job de purga ===
SELECT audit_trail, last_archive_ts FROM dba_audit_mgmt_last_arch_ts;
SELECT job_name, job_status, audit_trail, job_frequency FROM dba_audit_mgmt_cleanup_jobs;

PROMPT === Volumen actual del rastro unificado ===
SELECT COUNT(*) AS registros, MIN(event_timestamp) AS desde, MAX(event_timestamp) AS hasta
  FROM unified_audit_trail;

PROMPT === Resultado ===
SELECT (SELECT COUNT(*) FROM dba_users WHERE username = 'AUDSYS'
           AND (account_status LIKE '%LOCKED%' OR authentication_type = 'NONE'))      AS a_audsys_protegido,
       (SELECT COUNT(*) FROM dba_role_privs WHERE granted_role = 'AUDIT_ADMIN'
           AND grantee IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO'))    AS b_lab_con_audit_admin,
       (SELECT COUNT(*) FROM dba_audit_mgmt_cleanup_jobs WHERE job_status = 'ENABLED') AS c_jobs_purga,
       CASE WHEN (SELECT COUNT(*) FROM dba_users WHERE username = 'AUDSYS'
                     AND (account_status LIKE '%LOCKED%' OR authentication_type = 'NONE')) = 1
             AND (SELECT COUNT(*) FROM dba_role_privs WHERE granted_role = 'AUDIT_ADMIN'
                     AND grantee IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO')) = 0
             AND (SELECT COUNT(*) FROM dba_audit_mgmt_cleanup_jobs WHERE job_status = 'ENABLED') >= 1
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM dual;
