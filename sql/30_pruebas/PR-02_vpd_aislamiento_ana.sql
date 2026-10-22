-- =====================================================================
-- PR-02 | Negativa | VPD: ANA no puede ver ni modificar clientes de JUAN
-- ---------------------------------------------------------------------
-- Control        : A.8.3 (riesgo R-CONF-01)      Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: ANA (rol VENDEDORES).
-- Esperado       : (1) ANA ve 10 filas, todas suyas.
--                  (2) Buscar el cliente 1 (de JUAN) devuelve 0 filas: para
--                      ANA ese registro "no existe".
--                  (3) Intentar registrar una venta al cliente 1 -> ORA-20002.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-02_vpd_aislamiento_ana.sql PR-02_vpd_ana
-- =====================================================================
CONNECT ana/"&&pwd_ana"@&&srv

PROMPT >>> PR-02.1 Esperado: 10 filas, solo vendedor ANA
SELECT vendedor, COUNT(*) AS filas FROM ventas_lab.clientes GROUP BY vendedor;

PROMPT >>> PR-02.2 Esperado: 0 filas (el cliente 1 pertenece a JUAN)
SELECT id_cliente, nombre, vendedor FROM ventas_lab.clientes WHERE id_cliente = 1;

PROMPT >>> PR-02.3 Esperado: ORA-20002 (cliente no visible para la vendedora)
EXEC ventas_lab.registrar_venta(p_id_cliente => 1, p_monto => 5000)
