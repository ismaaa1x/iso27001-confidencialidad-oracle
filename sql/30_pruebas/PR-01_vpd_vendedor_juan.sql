-- =====================================================================
-- PR-01 | Positiva | VPD: JUAN consulta clientes y ve SOLO los suyos
-- ---------------------------------------------------------------------
-- Control        : A.8.3 (riesgo R-CONF-01)      Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado (sql/10_lab_setup).  Usuario: JUAN (rol VENDEDORES).
-- Esperado       : 10 filas, todas con VENDEDOR = 'JUAN'. Ninguna de ANA.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-01_vpd_vendedor_juan.sql PR-01_vpd_juan
-- =====================================================================
CONNECT juan/"&&pwd_juan"@&&srv

PROMPT >>> PR-01 Esperado: 10 filas, solo vendedor JUAN
SELECT vendedor, COUNT(*) AS filas FROM ventas_lab.clientes GROUP BY vendedor;
SELECT id_cliente, nombre, vendedor FROM ventas_lab.clientes ORDER BY id_cliente;
