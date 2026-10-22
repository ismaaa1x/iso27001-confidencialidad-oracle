-- =====================================================================
-- PR-04 | Positiva | Soporte ve todos los clientes, pero enmascarados
-- ---------------------------------------------------------------------
-- Control        : A.8.11, A.8.3 (riesgo R-CONF-04)   Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: SOPORTE_LAB (rol SOPORTE_CONSULTA).
-- Esperado       : 20 filas (VPD alcance TODOS); CEDULA *-****-NNNN,
--                  CORREO xxxx@dominio y TARJETA ****-****-****-NNNN.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-04_redaction_soporte.sql PR-04_redaction_soporte
-- =====================================================================
CONNECT soporte_lab/"&&pwd_soporte"@&&srv

PROMPT >>> PR-04.1 Esperado: 20 filas visibles
SELECT COUNT(*) AS filas FROM ventas_lab.clientes;

PROMPT >>> PR-04.2 Esperado: cédula, correo y tarjeta enmascarados
SELECT id_cliente, nombre, cedula, correo, tarjeta, vendedor FROM ventas_lab.clientes
 WHERE id_cliente IN (1, 2, 3) ORDER BY id_cliente;
