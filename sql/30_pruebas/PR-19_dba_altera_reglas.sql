-- =====================================================================
-- PR-19 | Riesgo residual | Un DBA puede alterar las reglas de VPD
-- ---------------------------------------------------------------------
-- Control        : A.8.2, A.8.15 (separación de funciones; riesgo R-CONF-05)
-- Herramienta    : SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: SYSTEM (rol DBA).
-- Propósito      : Demostrar honestamente el LÍMITE de los controles técnicos:
--                  un administrador con privilegios ANY puede darse acceso
--                  modificando la tabla de reglas. El control compensatorio es
--                  DETECTARLO (auditoría) y, como mejora, Database Vault.
-- Esperado       : ANTES de la fase Actuar: SYSTEM se agrega a las reglas,
--                  ve los datos y el cambio NO queda en una política propia.
--                  DESPUÉS de sql/40_actuar/A-02: el cambio queda auditado en
--                  POL_CONF_CAMBIOS_REGLAS (se revisa en VC-14 / PR-14).
--                  El script revierte el cambio al final.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-19_dba_altera_reglas.sql PR-19_dba_reglas
-- =====================================================================
CONNECT system/"&&pwd_system"@&&srv

PROMPT >>> Antes: SYSTEM ve 0 filas (VPD)
SELECT COUNT(*) AS filas FROM ventas_lab.clientes;

PROMPT >>> PR-19.1 SYSTEM se agrega a la tabla de reglas con alcance TODOS
INSERT INTO seguridad_lab.reglas_acceso VALUES ('SYSTEM', 'TODOS');
COMMIT;

PROMPT >>> Resultado: ahora SYSTEM ve todas las filas y, por estar exento de
PROMPT >>> Redaction (rol DBA), también la tarjeta completa
SELECT COUNT(*) AS filas FROM ventas_lab.clientes;
SELECT id_cliente, cedula, tarjeta FROM ventas_lab.clientes WHERE id_cliente = 1;

PROMPT >>> Revertir el cambio
DELETE FROM seguridad_lab.reglas_acceso WHERE usuario = 'SYSTEM';
COMMIT;

PROMPT >>> ¿Quedó registrado el INSERT de SYSTEM en las reglas? (últimos 2 minutos)
PROMPT     Antes de A-02: solo aparece el DELETE (por DELETE ANY TABLE); el INSERT no.
PROMPT     Después de A-02: aparecen INSERT, SELECT y DELETE con POL_CONF_CAMBIOS_REGLAS.
SELECT TO_CHAR(event_timestamp, 'HH24:MI:SS') AS event_timestamp, dbusername, action_name,
       object_name, unified_audit_policies
  FROM unified_audit_trail
 WHERE object_name = 'REGLAS_ACCESO' AND dbusername = 'SYSTEM'
   AND event_timestamp > SYSTIMESTAMP - INTERVAL '2' MINUTE
 ORDER BY event_timestamp;
