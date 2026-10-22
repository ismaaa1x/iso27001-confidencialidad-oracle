-- =====================================================================
-- 01_tde_keystore.sql  -  Configura el keystore (wallet) de TDE
-- ---------------------------------------------------------------------
-- Propósito      : Habilitar Transparent Data Encryption creando un
--                  keystore de software y la clave maestra (A.8.12,
--                  A.8.13; tarea T06; riesgo R-CONF-03).
-- Compatibilidad : Oracle 19c o posterior (WALLET_ROOT y
--                  TDE_CONFIGURATION). Probado en 26ai Free 23.26.1.
-- Privilegios    : SYSDBA (o SYSKM para ADMINISTER KEY MANAGEMENT).
-- Contenedor     : CDB$ROOT (modo unido: una clave por contenedor,
--                  creada para todos con CONTAINER = ALL).
-- MODIFICA       : SÍ. Cambia WALLET_ROOT (requiere REINICIAR la base)
--                  y TDE_CONFIGURATION; crea el keystore. Solo para el
--                  laboratorio aislado; nunca ejecutar en producción
--                  sin una ventana de mantenimiento.
-- Ejecución      : herramientas/ejecutar.sh sysdba-root sql/10_lab_setup/01_tde_keystore.sql E-01_tde_keystore
-- Limitaciones   : - El keystore AUTO_LOGIN se abre solo al iniciar la
--                    base. Es cómodo para el laboratorio, pero en
--                    producción se prefiere un keystore con contraseña
--                    o un HSM/OKV, porque quien copie el archivo
--                    cwallet.sso junto con los datafiles podría
--                    descifrarlos.
--                  - Si se pierde el keystore, los datos cifrados no se
--                    pueden recuperar: hay que respaldarlo por separado.
-- =====================================================================

PROMPT === Estado previo del keystore ===
SELECT con_id, wrl_type, status, wallet_type FROM v$encryption_wallet ORDER BY con_id;

PROMPT === 1. Crear el directorio del keystore (dentro del contenedor) ===
HOST mkdir -p /opt/oracle/oradata/FREE/wallet/tde

PROMPT === 2. Definir WALLET_ROOT (parámetro estático: requiere reinicio) ===
ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/oradata/FREE/wallet' SCOPE = SPFILE;

SHUTDOWN IMMEDIATE
STARTUP
ALTER PLUGGABLE DATABASE ALL OPEN;

PROMPT === 3. Indicar que el keystore es un archivo (software keystore) ===
ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;

PROMPT === 4. Crear el keystore protegido por contraseña ===
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "&&pwd_keystore";

PROMPT === 5. Abrir el keystore en todos los contenedores ===
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "&&pwd_keystore" CONTAINER = ALL;

PROMPT === 6. Crear la clave maestra (con respaldo del keystore) ===
ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'ISO27001_LAB'
  IDENTIFIED BY "&&pwd_keystore" WITH BACKUP USING 'antes_clave_maestra' CONTAINER = ALL;

PROMPT === 7. Keystore de apertura automática (solo laboratorio) ===
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE
  '/opt/oracle/oradata/FREE/wallet/tde' IDENTIFIED BY "&&pwd_keystore";

PROMPT === Estado final del keystore (esperado: OPEN en todos los contenedores) ===
SELECT con_id, wrl_type, status, wallet_type, keystore_mode FROM v$encryption_wallet ORDER BY con_id;
SELECT con_id, tag, activation_time FROM v$encryption_keys ORDER BY con_id;
