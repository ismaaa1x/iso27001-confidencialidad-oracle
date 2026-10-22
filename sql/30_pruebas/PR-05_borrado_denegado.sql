-- =====================================================================
-- PR-05 | Negativa | Un vendedor no puede borrar ni modificar clientes
-- ---------------------------------------------------------------------
-- Control        : A.5.15, A.8.3 (mínimo privilegio)   Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: JUAN (solo SELECT por rol).
-- Esperado       : DELETE y UPDATE rechazados por falta de privilegio:
--                  ORA-41900 "missing ... privilege" en 23ai/26ai
--                  (ORA-01031 en 19c/21c; mismo significado).
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-05_borrado_denegado.sql PR-05_borrado_denegado
-- =====================================================================
CONNECT juan/"&&pwd_juan"@&&srv

PROMPT >>> PR-05.1 Esperado: ORA-41900 missing DELETE privilege (ORA-01031 en 19c/21c)
DELETE FROM ventas_lab.clientes WHERE id_cliente = 1;

PROMPT >>> PR-05.2 Esperado: ORA-41900 missing UPDATE privilege (ORA-01031 en 19c/21c)
UPDATE ventas_lab.clientes SET correo = 'otro@correo-ficticio.test' WHERE id_cliente = 1;
ROLLBACK;
