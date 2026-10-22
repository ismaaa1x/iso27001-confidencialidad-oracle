-- =====================================================================
-- PR-15 | Positiva | TDE: una copia del datafile no revela los datos
-- ---------------------------------------------------------------------
-- Control        : A.8.12, A.8.13 (riesgo R-CONF-03: copia no autorizada)
-- Herramienta    : SQL*Plus + comando "strings" del sistema operativo
-- Requisitos     : Laboratorio creado.  Usuario: SYSDBA (debe leer los
--                  archivos del servidor: simula a alguien que copió los
--                  datafiles sin pasar por la base).
-- Esperado       : El texto 'MARCADOR-CONFIDENCIAL-ISO27001-2026' y el dominio
--                  de los correos aparecen en el datafile SIN cifrar y NO
--                  aparecen (0 coincidencias) en el datafile cifrado.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-15_tde_archivos.sql PR-15_tde_archivos
-- Limitaciones   : - TDE no impide que un usuario AUTORIZADO lea los datos por
--                    SQL; protege los archivos (datafiles, redo, respaldos).
--                  - Con el keystore AUTO_LOGIN, quien robe datafiles Y el
--                    archivo cwallet.sso podría descifrarlos: el keystore
--                    debe guardarse aparte (ver VC-13).
-- =====================================================================
CONNECT / AS SYSDBA

PROMPT >>> Escribir a disco los bloques modificados (checkpoint)
ALTER SYSTEM CHECKPOINT;

PROMPT >>> PR-15.1 Datafile SIN cifrar (ts_sin_cifrar01.dbf): se espera ver el marcador
HOST strings /opt/oracle/oradata/FREE/FREEPDB1/ts_sin_cifrar01.dbf | grep -m 3 "MARCADOR-CONFIDENCIAL"

PROMPT >>> PR-15.2 Datafile CIFRADO (ts_confidencial01.dbf): se espera 0 coincidencias
HOST echo "coincidencias MARCADOR = $(strings /opt/oracle/oradata/FREE/FREEPDB1/ts_confidencial01.dbf | grep -c MARCADOR-CONFIDENCIAL)"
HOST echo "coincidencias correo-ficticio.test = $(strings /opt/oracle/oradata/FREE/FREEPDB1/ts_confidencial01.dbf | grep -c correo-ficticio.test)"

PROMPT >>> Control: la base SÍ lee los datos cifrados (descifrado transparente)
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT texto FROM ventas_lab.prueba_tde_cifrado;
