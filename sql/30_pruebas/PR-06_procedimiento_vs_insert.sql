-- =====================================================================
-- PR-06 | Positiva y negativa | Operar solo mediante el procedimiento autorizado
-- ---------------------------------------------------------------------
-- Control        : A.5.15, A.8.3                     Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: JUAN (EXECUTE sobre REGISTRAR_VENTA).
-- Esperado       : (1) INSERT directo en VENTAS -> ORA-41900 en 26ai / ORA-01031 en 19c-21c (negativa).
--                  (2) REGISTRAR_VENTA con un cliente propio -> éxito (positiva).
--                  (3) REGISTRAR_VENTA con cliente de ANA -> ORA-20002 (negativa).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-06_procedimiento_vs_insert.sql PR-06_procedimiento
-- =====================================================================
CONNECT juan/"&&pwd_juan"@&&srv

PROMPT >>> PR-06.1 Esperado: ORA-41900 missing INSERT privilege (ORA-01031 en 19c/21c)
INSERT INTO ventas_lab.ventas (id_cliente, vendedor, monto) VALUES (1, 'JUAN', 999);

PROMPT >>> PR-06.2 Esperado: PL/SQL procedure successfully completed (cliente 1 es de JUAN)
EXEC ventas_lab.registrar_venta(p_id_cliente => 1, p_monto => 15000)
COMMIT;

PROMPT >>> PR-06.3 Esperado: ORA-20002 (cliente 2 es de ANA)
EXEC ventas_lab.registrar_venta(p_id_cliente => 2, p_monto => 15000)

PROMPT >>> Ventas visibles para JUAN (solo las suyas)
SELECT vendedor, COUNT(*) AS ventas, SUM(monto) AS total FROM ventas_lab.ventas GROUP BY vendedor;
