-- =====================================================================
-- PR-03 | Positiva | Data Redaction para un vendedor
-- ---------------------------------------------------------------------
-- Control        : A.8.11, A.8.3 (riesgo R-CONF-01)   Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: JUAN (rol VENDEDORES).
-- Esperado       : CEDULA y CORREO completos (los necesita para facturar);
--                  TARJETA enmascarada: ****-****-****-NNNN.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-03_redaction_vendedor.sql PR-03_redaction_vendedor
-- =====================================================================
CONNECT juan/"&&pwd_juan"@&&srv

PROMPT >>> PR-03 Esperado: cédula y correo visibles; tarjeta ****-****-****-NNNN
SELECT id_cliente, cedula, correo, tarjeta FROM ventas_lab.clientes
 WHERE id_cliente IN (1, 3, 5) ORDER BY id_cliente;
