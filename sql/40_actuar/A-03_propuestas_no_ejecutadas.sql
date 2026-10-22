-- =====================================================================
-- A-03 | Actuar | PROPUESTAS DE MEJORA - NO EJECUTADAS
-- ---------------------------------------------------------------------
-- Este archivo documenta mejoras que reducirían el riesgo residual pero que
-- NO se aplicaron en el laboratorio, por una de estas razones: afectan
-- políticas globales de la base, requieren infraestructura adicional
-- (certificados, HSM, SIEM) o cambian el funcionamiento del motor.
-- Todas las sentencias están COMENTADAS a propósito. No es una simulación:
-- son trabajo pendiente y así se reporta en la matriz.
-- =====================================================================

-- P-01 (A.5.17, A.8.5) Endurecer el perfil DEFAULT (VC-04 = PARCIAL).
--      Afecta a TODAS las cuentas que no tengan otro perfil (incluida SYSTEM):
--      requiere aprobación y comunicar el cambio.
-- ALTER PROFILE DEFAULT LIMIT
--   PASSWORD_VERIFY_FUNCTION ora12c_strong_verify_function
--   PASSWORD_LIFE_TIME 90 PASSWORD_REUSE_MAX 5 PASSWORD_REUSE_TIME 365
--   FAILED_LOGIN_ATTEMPTS 5;

-- P-02 (A.8.2) Database Vault (incluido en Free/XE): crear un "realm" sobre
--      VENTAS_LAB para que ni siquiera un DBA con privilegios ANY lea los
--      datos (corrige el riesgo residual de PR-19). Requiere configurar y
--      habilitar Database Vault (DVSYS/DVF), cuentas de propietario y
--      administrador de cuentas separadas, y reiniciar la base.
-- BEGIN
--   DVSYS.DBMS_MACADM.CREATE_REALM(realm_name => 'REALM_VENTAS', description => 'Datos personales',
--     enabled => DBMS_MACUTL.G_YES, audit_options => DBMS_MACUTL.G_REALM_AUDIT_FAIL);
--   DVSYS.DBMS_MACADM.ADD_OBJECT_TO_REALM('REALM_VENTAS', 'VENTAS_LAB', '%', '%');
-- END;

-- P-03 (A.8.20) Migrar de Native Network Encryption a TLS (TCPS) con
--      certificados: autentica al servidor y es la recomendación de Oracle.
--      Requiere: wallet con certificado (orapki), listener TCPS y clientes
--      configurados. Ver Oracle AI Database Security Guide, "Configuring
--      Transport Layer Security Encryption".

-- P-04 (A.8.12, A.8.13) Guardar el keystore TDE fuera del servidor de datos
--      (Oracle Key Vault o HSM) y eliminar el AUTO_LOGIN local.

-- P-05 (A.8.15, A.5.33) Enviar UNIFIED_AUDIT_TRAIL a un SIEM (por ejemplo
--      mediante syslog: parámetro UNIFIED_AUDIT_SYSTEMLOG) para que los
--      registros queden fuera del alcance del DBA.
-- ALTER SYSTEM SET UNIFIED_AUDIT_SYSTEMLOG = 'LOCAL0.INFO' SCOPE = SPFILE;

-- P-06 (A.8.2) Cuenta de respaldo dedicada con EXEMPT ACCESS POLICY, usada
--      solo por el proceso de respaldo y auditada (PR-16 mostró que VPD
--      filtra también los exports de SYSTEM: ORA-39181).

-- P-07 (Parcheo, T12) Aplicar el último Release Update de 26ai: en Free se
--      hace descargando la imagen/instalador más reciente. Comparar
--      V$VERSION con la página oficial de Release Updates.
