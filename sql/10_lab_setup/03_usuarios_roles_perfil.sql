-- =====================================================================
-- 03_usuarios_roles_perfil.sql  -  Identidades, perfiles y roles
-- ---------------------------------------------------------------------
-- Propósito      : Implementar el ejemplo de la pizarra (CREATE USER,
--                  GRANT, CREATE ROLE, perfiles con IDLE_TIME) aplicando
--                  mínimo privilegio. Controles A.5.15, A.5.16, A.5.17,
--                  A.5.18, A.8.2, A.8.5. Tareas T01, T02, T04.
-- Compatibilidad : 12.2+ (ORA12C_STRONG_VERIFY_FUNCTION). Probado en 26ai Free.
-- Privilegios    : SYSTEM (CREATE USER, CREATE ROLE, CREATE PROFILE, GRANT ANY).
-- Contenedor     : FREEPDB1.
-- MODIFICA       : SÍ (crea perfiles, roles y usuarios del laboratorio).
--                  No toca el perfil DEFAULT ni las cuentas existentes.
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/03_usuarios_roles_perfil.sql E-03_usuarios_roles_perfil
--
-- Usuarios del laboratorio (personas o sistemas ficticios):
--   JUAN, ANA       vendedores: ven solo sus clientes (VPD, script 05)
--   SOPORTE_LAB     mesa de ayuda: ve los clientes con datos enmascarados
--   AUDITOR_LAB     auditor: lee el rastro de auditoría, no los datos
--   APP_RIESGO      cuenta MAL configurada A PROPÓSITO (SELECT ANY TABLE)
--                   para que la verificación VC-07 detecte el hallazgo y
--                   se corrija en la fase Actuar (sql/40_actuar)
--   PRUEBA_BLOQUEO  solo para la prueba de bloqueo por intentos fallidos
--   PRUEBA_IDLE     solo para la prueba de IDLE_TIME
-- =====================================================================

PROMPT === 1. Perfil de seguridad para cuentas con acceso a datos confidenciales ===
-- Valores elegidos para el laboratorio; una organización real los
-- define en su política de contraseñas.
CREATE PROFILE perfil_confidencial LIMIT
  FAILED_LOGIN_ATTEMPTS     3          -- bloqueo tras 3 intentos fallidos
  PASSWORD_LOCK_TIME        1/24       -- bloqueo de 1 hora
  PASSWORD_LIFE_TIME        90         -- cambio cada 90 días
  PASSWORD_GRACE_TIME       7
  PASSWORD_REUSE_TIME       365        -- no reutilizar en un año
  PASSWORD_REUSE_MAX        5
  PASSWORD_VERIFY_FUNCTION  ora12c_strong_verify_function
  INACTIVE_ACCOUNT_TIME     90         -- bloquear cuentas sin uso
  IDLE_TIME                 15         -- minutos de inactividad (pizarra)
  SESSIONS_PER_USER         3;

PROMPT === 2. Perfil exclusivo para demostrar IDLE_TIME en pocos minutos ===
CREATE PROFILE perfil_prueba_idle LIMIT
  IDLE_TIME                 1
  FAILED_LOGIN_ATTEMPTS     3
  PASSWORD_VERIFY_FUNCTION  ora12c_strong_verify_function;

PROMPT === 3. Usuarios (una cuenta por persona; ninguna con el nombre como contraseña) ===
-- La pizarra usaba "identified by JUAN": la función de verificación del
-- perfil ahora rechaza ese tipo de contraseña (prueba PR-11).
CREATE USER juan           IDENTIFIED BY "&&pwd_juan"       PROFILE perfil_confidencial DEFAULT TABLESPACE users QUOTA 0 ON users;
CREATE USER ana            IDENTIFIED BY "&&pwd_ana"        PROFILE perfil_confidencial DEFAULT TABLESPACE users QUOTA 0 ON users;
CREATE USER soporte_lab    IDENTIFIED BY "&&pwd_soporte"    PROFILE perfil_confidencial;
CREATE USER auditor_lab    IDENTIFIED BY "&&pwd_auditor"    PROFILE perfil_confidencial;
CREATE USER app_riesgo     IDENTIFIED BY "&&pwd_app_riesgo" PROFILE perfil_confidencial;
CREATE USER prueba_bloqueo IDENTIFIED BY "&&pwd_bloqueo"    PROFILE perfil_confidencial;
CREATE USER prueba_idle    IDENTIFIED BY "&&pwd_idle"       PROFILE perfil_prueba_idle;

PROMPT === 4. Roles por función (no se otorgan privilegios directos a personas) ===
CREATE ROLE conexion_lab;
GRANT CREATE SESSION TO conexion_lab;

CREATE ROLE vendedores;
GRANT SELECT  ON ventas_lab.clientes        TO vendedores;
GRANT SELECT  ON ventas_lab.ventas          TO vendedores;
-- Equivale a "GRANT EXECUTE ON sp01" de la pizarra:
GRANT EXECUTE ON ventas_lab.registrar_venta TO vendedores;
-- Nota: NO se otorga INSERT/UPDATE/DELETE; los cambios pasan por el procedimiento.

CREATE ROLE soporte_consulta;
GRANT SELECT ON ventas_lab.clientes TO soporte_consulta;

PROMPT === 5. Asignación de roles ===
GRANT conexion_lab, vendedores       TO juan, ana;
GRANT conexion_lab, soporte_consulta TO soporte_lab;
-- El auditor lee la auditoría (AUDIT_VIEWER) pero no la administra (sin AUDIT_ADMIN):
GRANT conexion_lab, audit_viewer     TO auditor_lab;
GRANT conexion_lab                   TO prueba_bloqueo, prueba_idle;

PROMPT === 6. Cuenta mal configurada A PROPÓSITO (hallazgo a detectar en VC-07) ===
GRANT CREATE SESSION, SELECT ANY TABLE TO app_riesgo;

PROMPT === Verificación ===
SELECT username, account_status, profile, authentication_type
  FROM dba_users
 WHERE username IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','APP_RIESGO',
                    'PRUEBA_BLOQUEO','PRUEBA_IDLE','VENTAS_LAB','SEGURIDAD_LAB','VENTAS_DEV')
 ORDER BY username;
SELECT grantee, granted_role FROM dba_role_privs
 WHERE grantee IN ('JUAN','ANA','SOPORTE_LAB','AUDITOR_LAB','PRUEBA_BLOQUEO','PRUEBA_IDLE')
 ORDER BY grantee, granted_role;
SELECT grantee, owner, table_name, privilege FROM dba_tab_privs
 WHERE owner = 'VENTAS_LAB' ORDER BY grantee, table_name, privilege;
