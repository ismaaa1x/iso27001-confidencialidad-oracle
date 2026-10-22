-- =====================================================================
-- PR-10 | Negativa (defensa en profundidad) | Cuenta con SELECT ANY TABLE
-- ---------------------------------------------------------------------
-- Control        : A.8.2, A.8.3, A.8.11 (riesgo R-CONF-01)  Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: APP_RIESGO (mal configurada a propósito).
-- Esperado       : (1) CLIENTES -> 0 filas: VPD deniega por defecto aunque la
--                      cuenta tenga SELECT ANY TABLE.
--                  (2) La copia DEV sí es legible (el privilegio es real),
--                      pero solo contiene datos falsos (enmascaramiento estático).
--                  (3) HALLAZGO: la tabla de reglas de VPD es legible por esta
--                      cuenta: el privilegio *ANY* expone la configuración de
--                      seguridad. Se corrige en sql/40_actuar.
--                  (4) Cada uso de SELECT ANY TABLE queda auditado
--                      (POL_CONF_PRIVILEGIOS_AMPLIOS), ver PR-14.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-10_cuenta_sobreprivilegiada.sql PR-10_sobreprivilegiada
-- =====================================================================
CONNECT app_riesgo/"&&pwd_app_riesgo"@&&srv

PROMPT >>> PR-10.1 Esperado: 0 filas (VPD)
SELECT COUNT(*) AS filas_clientes FROM ventas_lab.clientes;

PROMPT >>> PR-10.2 Esperado: 20 filas, todas con datos FALSOS (copia DEV)
SELECT COUNT(*) AS filas_dev FROM ventas_dev.clientes;
SELECT id_cliente, nombre, cedula, tarjeta FROM ventas_dev.clientes WHERE id_cliente <= 2;

PROMPT >>> PR-10.3 HALLAZGO esperado: la cuenta puede leer las reglas de seguridad
SELECT usuario, alcance FROM seguridad_lab.reglas_acceso;
