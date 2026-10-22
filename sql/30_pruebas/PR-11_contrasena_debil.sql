-- =====================================================================
-- PR-11 | Negativa | La función de verificación rechaza contraseñas débiles
-- ---------------------------------------------------------------------
-- Control        : A.5.17 (riesgo R-CONF-02)          Herramienta: SQL*Plus / SQL Developer
-- Requisitos     : Laboratorio creado.  Usuario: JUAN (cambia su propia contraseña).
-- Esperado       : ORA-28003 en los tres intentos: igual al usuario (como en el
--                  ejemplo de la pizarra "identified by JUAN"), corta y sin
--                  complejidad. La contraseña actual NO cambia.
-- Nota           : Los ALTER USER se ejecutan dentro de PL/SQL y solo se
--                  imprime el mensaje de Oracle, para que la contraseña actual
--                  (cláusula REPLACE) nunca aparezca en la evidencia.
-- Ejecución      : herramientas/ejecutar.sh ninguno sql/30_pruebas/PR-11_contrasena_debil.sql PR-11_contrasena_debil
-- =====================================================================
CONNECT juan/"&&pwd_juan"@&&srv
SET SERVEROUTPUT ON
SET ECHO OFF

PROMPT >>> PR-11 Esperado: ORA-28003 en los tres intentos
DECLARE
  TYPE t_lista IS TABLE OF VARCHAR2(40);
  v_debiles t_lista := t_lista('JUAN', 'Ju4n!', 'vendedorjuan');
  v_motivo  t_lista := t_lista('igual al nombre de usuario', 'demasiado corta',
                               'sin mayúsculas, dígitos ni símbolos');
BEGIN
  FOR i IN 1 .. v_debiles.COUNT LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER USER juan IDENTIFIED BY "' || v_debiles(i)
                        || '" REPLACE "' || q'[&&pwd_juan]' || '"';
      DBMS_OUTPUT.PUT_LINE('PR-11.' || i || ' "' || v_debiles(i) || '" (' || v_motivo(i)
                           || ') -> ACEPTADA (el control FALLÓ)');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PR-11.' || i || ' "' || v_debiles(i) || '" (' || v_motivo(i)
                             || ') -> RECHAZADA: ' || REGEXP_SUBSTR(SQLERRM, 'ORA-\d+[^' || CHR(10) || ']*'));
    END;
  END LOOP;
END;
/

SET ECHO ON
PROMPT >>> Comprobación: la sesión sigue funcionando con la contraseña original
SELECT USER AS usuario FROM dual;
