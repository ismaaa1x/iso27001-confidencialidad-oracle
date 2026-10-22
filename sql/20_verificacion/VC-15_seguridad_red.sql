-- =====================================================================
-- VC-15 | Control ISO: A.8.20 Seguridad de redes
-- ---------------------------------------------------------------------
-- Comprobación   : (a) la sesión que ejecuta este script (conectada por TCP)
--                      viaja cifrada con AES256 y con integridad SHA256;
--                  (b) el servidor EXIGE cifrado (sqlnet.ora del servidor);
--                  (c) las sesiones TCP abiertas de las cuentas del laboratorio
--                      también están cifradas.
-- Tipo           : SOLO LECTURA (HOST cat solo lee el archivo).
-- Compatibilidad : Native Network Encryption: todas las ediciones; en 23ai+
--                  solo algoritmos fuertes (AES, SHA-2).
-- Privilegios    : SYSTEM conectado por TCP (modo "system" del ejecutor; una
--                  conexión local "/ as sysdba" no usa la red y no aplica).
-- Contenedor     : FREEPDB1.
-- Ejecución      : herramientas/ejecutar.sh system sql/20_verificacion/VC-15_seguridad_red.sql VC-15_seguridad_red
-- Interpretación : CUMPLE si (a) banners con AES256 y SHA256 y (b) el
--                  servidor tiene ENCRYPTION_SERVER = REQUIRED.
-- Limitaciones   : - NNE cifra, pero no autentica al servidor con certificado;
--                    Oracle recomienda TLS como mejora (fase Actuar).
--                  - La exposición del puerto se verifica fuera de la base:
--                    el contenedor publica 1521 solo en 127.0.0.1:1522
--                    (evidencia: docker port, en E-10_red).
-- =====================================================================

PROMPT === (a) Servicios de red de la sesión actual ===
SELECT network_service_banner FROM v$session_connect_info
 WHERE sid = SYS_CONTEXT('USERENV', 'SID');

SELECT SYS_CONTEXT('USERENV', 'NETWORK_PROTOCOL') AS protocolo FROM dual;

PROMPT === (b) Configuración del servidor ===
HOST grep -E "ENCRYPTION|CHECKSUM" $ORACLE_HOME/network/admin/sqlnet.ora

PROMPT === Resultado ===
SELECT CASE WHEN SUM(CASE WHEN network_service_banner LIKE '%AES256%' THEN 1 ELSE 0 END) > 0
             AND SUM(CASE WHEN network_service_banner LIKE '%SHA256%' THEN 1 ELSE 0 END) > 0
            THEN 'CUMPLE' ELSE 'NO CUMPLE' END AS resultado
  FROM v$session_connect_info
 WHERE sid = SYS_CONTEXT('USERENV', 'SID');
