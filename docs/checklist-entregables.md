# Lista de verificación: entregables, rúbrica y evidencias

Marca cada casilla cuando **tú** lo hayas revisado.

## A. Entregables oficiales (sección 10 del enunciado)

- [ ] **1. Informe PDF con el artefacto** → `entregables/Informe-ISO27001-Confidencialidad-Oracle.pdf` (incluye el contenido del artefacto y la ruta a `artefacto/index.html`).
- [ ] **2. Scripts .sql de verificación** → `sql/20_verificacion/` (VC-01 a VC-15), más diagnóstico, laboratorio, pruebas, Actuar y limpieza.
- [ ] **3. Repositorio Git** → público en GitHub: https://github.com/ismaaa1x/iso27001-confidencialidad-oracle
- [ ] **4. Video de 5 minutos** → `entregables/Video-ISO27001-Confidencialidad-Oracle.mp4` (solo en el zip; guion en `docs/guion-video.md`).
- [ ] **5. Tabla de uso de IA firmada** → `entregables/Tabla_Uso_IA_Firmada.pdf` (solo en el zip; en el repositorio está la versión sin firma `Tabla_Uso_IA_Para_Firmar.pdf`).

## B. Rúbrica (100 pts)

| Criterio | Peso | Dónde está | Revisado |
|---|---|---|---|
| Identificación de riesgos y tareas DBA | 20 % | Artefacto: pestañas Riesgos y Tareas · Informe secciones 3-4 | [ ] |
| Mapeo y justificación de controles ISO | 20 % | Artefacto: Controles ISO · Informe sección 5 | [ ] |
| Matriz de evaluación y controles observables | 20 % | Artefacto: Observables y Matriz y seguimiento (resumen, historial y evolución) · `sql/20_verificacion` · `evidencias/VC-*` | [ ] |
| Pruebas técnicas y scripts | 15 % | Artefacto: Pruebas · `sql/30_pruebas` · `evidencias/PR-*` | [ ] |
| Documentación de IA y referencias APA 7 | 15 % | Informe: Uso de IA y Referencias · `docs/ia/` | [ ] |
| Presentación, video y repositorio | 10 % | Video · repositorio · formato del informe | [ ] |

## C. Evidencias que debes capturar tú (capturas de pantalla)

Las salidas de texto ya están en `evidencias/`, pero el profesor valorará ver capturas hechas por ti en **SQL Developer**. Guárdalas en `evidencias/capturas/` con estos nombres:

| Archivo | Qué capturar |
|---|---|
| `C-01_conexion_freepdb1.png` | SQL Developer conectado a FREEPDB1 con `SELECT banner_full FROM v$version;` |
| `C-02_juan_vpd.png` | Como JUAN: `SELECT vendedor, COUNT(*) FROM ventas_lab.clientes GROUP BY vendedor;` (solo JUAN) |
| `C-03_juan_redaction.png` | Como JUAN: `SELECT cedula, correo, tarjeta FROM ventas_lab.clientes WHERE ROWNUM <= 3;` |
| `C-04_soporte_redaction.png` | Como SOPORTE_LAB: la misma consulta (cédula y correo enmascarados) |
| `C-05_juan_delete_denegado.png` | Como JUAN: `DELETE FROM ventas_lab.clientes;` → ORA-41900 en 26ai (ORA-01031 en 19c/21c) |
| `C-06_auditoria.png` | Como AUDITOR_LAB: consulta de PR-14 sobre `UNIFIED_AUDIT_TRAIL` |
| `C-07_vc07_antes_despues.png` | `evidencias/VC-07_acceso_privilegiado.txt` y `..._DESPUES.txt`, lado a lado |
| `C-08_tde_strings.png` | `evidencias/PR-15_tde_archivos.txt` abierto (0 coincidencias en el archivo cifrado) |
| `C-09_artefacto.png` | El artefacto abierto en el navegador |
| `C-10_seguimiento.png` | Matriz y seguimiento → Evolución con al menos 2 controles y un punto seleccionado |

**No captures** el archivo `.secrets/lab_defines.sql` ni ninguna pantalla con contraseñas.

## D. Repositorio Git

El repositorio ya existe en GitHub (privado) y está conectado. Para subir cambios nuevos:

```bash
cd "C:/Users/ISMAELROJASHERRERA/Documents/admin Bases de Datos/SeguridadBases"
git status            # revisa que .secrets/ NO aparezca
git add .
git commit -m "Describe aquí el cambio"
git push
```

Para que el profesor lo vea: en GitHub, *Settings → Collaborators → Add people*. Si él pide el Git institucional, se agrega ese remoto y se hace `git push` allí.

## E. Verificaciones finales antes de entregar

- [ ] **No** volví a ejecutar `bash herramientas/ejecutar_todo.sh`: sobrescribe las evidencias y se pierde el «antes» de VC-07 y VC-14 del 21/10.
- [ ] Exporté el JSON de evaluaciones del módulo «Matriz y seguimiento» antes de regenerar (ver `docs/seguimiento-evaluaciones.md`).
- [ ] Ejecuté `python herramientas/generar_entregables.py` después de la última corrida y comprobé que mis evaluaciones siguen en el artefacto.
- [ ] Revisé que `.secrets/` no está en el repositorio (`git ls-files | grep secrets` no debe devolver nada).
- [ ] El informe tiene mi nombre y las referencias en APA 7.
- [ ] Firmé `entregables/Tabla_Uso_IA_Para_Firmar.pdf` y completé carné y fecha.
- [ ] Pregunté al profesor si acepta 26ai Free en lugar de 21c XE (y lo anoté en el informe).
