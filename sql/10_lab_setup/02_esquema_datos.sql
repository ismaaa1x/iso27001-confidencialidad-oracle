-- =====================================================================
-- 02_esquema_datos.sql  -  Tablespaces, esquema de negocio y datos ficticios
-- ---------------------------------------------------------------------
-- Propósito      : Crear el escenario del laboratorio:
--                  * TS_CONFIDENCIAL: tablespace cifrado con TDE (AES256)
--                  * TS_SIN_CIFRAR  : tablespace normal (solo para la
--                    prueba comparativa PR-15)
--                  * VENTAS_LAB     : esquema dueño de los datos
--                  * SEGURIDAD_LAB  : esquema dueño de los objetos de
--                    seguridad (separado del negocio)
--                  Todos los datos son FICTICIOS (dominio .test,
--                  tarjetas de prueba, cédulas inventadas).
-- Compatibilidad : 12.2+ (NO AUTHENTICATION desde 18c). Probado en 26ai Free.
-- Privilegios    : SYSTEM (CREATE TABLESPACE, CREATE USER, CREATE ANY TABLE).
-- Contenedor     : FREEPDB1.
-- Requisito      : 01_tde_keystore.sql ejecutado (keystore OPEN).
-- MODIFICA       : SÍ (crea objetos del laboratorio).
-- Ejecución      : herramientas/ejecutar.sh system sql/10_lab_setup/02_esquema_datos.sql E-02_esquema_datos
-- =====================================================================

PROMPT === 1. Tablespace cifrado (TDE, AES256) ===
-- En Free/XE no se puede cifrar EN LÍNEA un tablespace existente: por eso
-- se crea uno nuevo ya cifrado y los datos sensibles se crean en él.
CREATE TABLESPACE ts_confidencial
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/ts_confidencial01.dbf'
  SIZE 20M AUTOEXTEND ON NEXT 10M MAXSIZE 500M
  ENCRYPTION USING 'AES256' ENCRYPT;

PROMPT === 2. Tablespace SIN cifrar (solo para comparar en PR-15) ===
CREATE TABLESPACE ts_sin_cifrar
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/ts_sin_cifrar01.dbf'
  SIZE 10M AUTOEXTEND ON NEXT 5M MAXSIZE 100M;

PROMPT === 3. Esquemas sin contraseña (nadie puede iniciar sesión con ellos) ===
-- A.5.16: los dueños de objetos no son cuentas de personas.
CREATE USER ventas_lab NO AUTHENTICATION
  DEFAULT TABLESPACE ts_confidencial
  QUOTA UNLIMITED ON ts_confidencial
  QUOTA 50M ON ts_sin_cifrar;

CREATE USER seguridad_lab NO AUTHENTICATION
  DEFAULT TABLESPACE ts_confidencial
  QUOTA 10M ON ts_confidencial;

CREATE USER ventas_dev NO AUTHENTICATION
  DEFAULT TABLESPACE ts_sin_cifrar
  QUOTA 50M ON ts_sin_cifrar;

PROMPT === 4. Tablas de negocio (en el tablespace cifrado) ===
CREATE TABLE ventas_lab.clientes (
  id_cliente      NUMBER        CONSTRAINT pk_clientes PRIMARY KEY,
  nombre          VARCHAR2(80)  NOT NULL,
  cedula          VARCHAR2(12)  NOT NULL,
  correo          VARCHAR2(80)  NOT NULL,
  telefono        VARCHAR2(9)   NOT NULL,
  tarjeta         VARCHAR2(19)  NOT NULL,
  vendedor        VARCHAR2(30)  NOT NULL,
  fecha_registro  DATE          DEFAULT SYSDATE NOT NULL
) TABLESPACE ts_confidencial;

CREATE TABLE ventas_lab.ventas (
  id_venta    NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_ventas PRIMARY KEY,
  id_cliente  NUMBER        NOT NULL CONSTRAINT fk_ventas_cliente REFERENCES ventas_lab.clientes,
  vendedor    VARCHAR2(30)  NOT NULL,
  monto       NUMBER(12,2)  NOT NULL CONSTRAINT ck_ventas_monto CHECK (monto > 0),
  fecha       DATE          DEFAULT SYSDATE NOT NULL
) TABLESPACE ts_confidencial;

PROMPT === 5. Datos ficticios: 20 clientes repartidos entre JUAN y ANA ===
INSERT INTO ventas_lab.clientes (id_cliente, nombre, cedula, correo, telefono, tarjeta, vendedor)
SELECT LEVEL,
       'Cliente Ficticio ' || LPAD(LEVEL, 2, '0'),
       TO_CHAR(MOD(LEVEL, 7) + 1) || '-' || LPAD(MOD(LEVEL * 3571, 10000), 4, '0')
                                  || '-' || LPAD(MOD(LEVEL * 7919, 10000), 4, '0'),
       'cliente' || LPAD(LEVEL, 2, '0') || '@correo-ficticio.test',
       '8' || LPAD(MOD(LEVEL * 131, 1000), 3, '0') || '-' || LPAD(MOD(LEVEL * 977, 10000), 4, '0'),
       '4111-1111-' || LPAD(MOD(LEVEL * 37, 10000), 4, '0') || '-' || LPAD(1000 + LEVEL, 4, '0'),
       CASE WHEN MOD(LEVEL, 2) = 1 THEN 'JUAN' ELSE 'ANA' END
  FROM dual CONNECT BY LEVEL <= 20;

INSERT INTO ventas_lab.ventas (id_cliente, vendedor, monto)
SELECT id_cliente, vendedor, 10000 + id_cliente * 1250 FROM ventas_lab.clientes;

COMMIT;

PROMPT === 6. Procedimiento de negocio (equivale al "sp01" de la pizarra) ===
-- Los vendedores registran ventas SOLO mediante este procedimiento; no
-- reciben INSERT directo sobre la tabla (mínimo privilegio, A.8.3).
CREATE OR REPLACE PROCEDURE ventas_lab.registrar_venta (
  p_id_cliente IN NUMBER,
  p_monto      IN NUMBER
) AUTHID DEFINER AS
  v_vendedor ventas_lab.clientes.vendedor%TYPE;
BEGIN
  SELECT vendedor INTO v_vendedor
    FROM ventas_lab.clientes
   WHERE id_cliente = p_id_cliente;

  IF v_vendedor <> SYS_CONTEXT('USERENV', 'SESSION_USER') THEN
    RAISE_APPLICATION_ERROR(-20001, 'El cliente no pertenece al vendedor de la sesión');
  END IF;

  INSERT INTO ventas_lab.ventas (id_cliente, vendedor, monto)
  VALUES (p_id_cliente, v_vendedor, p_monto);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Cliente inexistente o no visible para el vendedor');
END;
/

PROMPT === 7. Tablas para la prueba comparativa de TDE (PR-15) ===
CREATE TABLE ventas_lab.prueba_tde_cifrado (texto VARCHAR2(60)) TABLESPACE ts_confidencial;
CREATE TABLE ventas_lab.prueba_tde_plano   (texto VARCHAR2(60)) TABLESPACE ts_sin_cifrar;
INSERT INTO ventas_lab.prueba_tde_cifrado VALUES ('MARCADOR-CONFIDENCIAL-ISO27001-2026');
INSERT INTO ventas_lab.prueba_tde_plano   VALUES ('MARCADOR-CONFIDENCIAL-ISO27001-2026');
COMMIT;

PROMPT === Verificación: ubicación y cifrado de los tablespaces ===
SELECT tablespace_name, encrypted, status FROM dba_tablespaces
 WHERE tablespace_name IN ('TS_CONFIDENCIAL', 'TS_SIN_CIFRAR') ORDER BY 1;
SELECT owner, table_name, tablespace_name, num_rows FROM dba_tables
 WHERE owner = 'VENTAS_LAB' ORDER BY table_name;
SELECT vendedor, COUNT(*) AS clientes FROM ventas_lab.clientes GROUP BY vendedor ORDER BY 1;
