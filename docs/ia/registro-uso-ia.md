# Tabla de uso de IA y declaración jurada

Formato de la sección 8 del enunciado («Uso ético y documentado de inteligencia artificial»): tabla con las columnas Herramienta IA, Prompt exacto utilizado, Aporte de la IA, Validación / Corrección del estudiante y Fuente verificada. Debajo va la declaración jurada. Es el entregable 5, «Tabla de uso de IA firmada». El informe PDF la incluye en la sección «Uso de IA», y también existe como documento aparte para imprimir y firmar: `entregables/Tabla-Uso-IA-Firmada-ISO27001-Oracle.pdf`.

Los prompts se transcriben **exactamente** como se escribieron, incluidas las faltas de ortografía. Se registran los prompts que generaron contenido del trabajo (scripts, documentos, configuración o decisiones del proyecto). Las consultas puramente conversacionales, cuya respuesta no se incorporó a ningún entregable, no se incluyen. El prompt 01, por su extensión, está completo en `prompt-01-analisis-inicial.md`. Las columnas «Validación / Corrección del estudiante» y «Fuente verificada» quedan en **Pendiente** hasta que el estudiante las complete con lo que revisó personalmente.

| Herramienta IA | Prompt exacto utilizado | Aporte de la IA | Validación / Corrección del estudiante | Fuente verificada |
|---|---|---|---|---|
| Claude Code (Claude Opus 5.5, Anthropic) | 01 · Texto completo en `docs/ia/prompt-01-analisis-inicial.md` (especificación del proyecto: PHVA, riesgos R-CONF, 15 controles, matriz, pruebas, restricciones de seguridad y de citación) | Lectura del enunciado y las pizarras; transcripción con dudas marcadas; diagnóstico del equipo (solo lectura); verificación de las funciones de Oracle por edición; plan PHVA. | Pendiente | Pendiente |
| Claude Code (Claude Opus 5.5) | 02 · «1. -si es mi laptop, -si,-es individual y mañana necesito llevar un base para enseñarle al profesor y explicarle algo mas o menos 2. tu no puedes descargar oracle?, no te sirve el de docker que tengo ?» (respuestas a la consulta: «usa la que tu creas que es mejor» y «Detenerlo (Recomendado)») | Elección de Oracle AI Database 26ai Free; creación del contenedor aislado `iso27001-oracle`; diagnóstico E-00; borrador de avance (escala, riesgos, tareas, mapeo ISO). | Pendiente | Oracle AI Database Licensing Information User Manual 26ai (pendiente de revisión) |
| Claude Code (Claude Opus 5.5) | 03 · «entonces del proyecto en si no haz hecho nada? segundo mi nombre es ismael rojas herrera para que lo agregues, tercero, dame un md explicando un poco el proyecto en general, lo que voy a hacer para desarrollarlo y  TODO el avance» | Nombre agregado; documento explicativo del avance. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 04 · «ok, empeza con todo el proyecto, pero separame muy bien en una carpeta lo del avance por APARTE, el md explicativo corrigelo la explicacion damela como si yo la fuera a leer y es exactamente lo que le tengo que decir al profesor por si me pregunta» | Laboratorio completo (10 scripts de configuración), 15 verificaciones, 19 pruebas, 3 scripts de la fase Actuar, ejecución con evidencias, marco teórico, README, artefacto, informe, guion y checklist; carpeta `avance-profesor/` separada. | Pendiente | Ley 8968 (texto de SCIJ/MICITT, arts. 1-3, 9-11); documentación de Oracle 21c/26ai (pendiente de revisión) |
| Claude Code (Claude Opus 5.5) | 05 · «como lo subiste al git si no existe repositorio ? no puedes hacer tu el repositorio sin marca de agua ?» (respuestas a la consulta: «Privado (Recomendado)» y «No incluirlos (Recomendado)») | Creación del repositorio privado `ismaaa1x/iso27001-confidencialidad-oracle` en GitHub con la cuenta del estudiante; primer commit sin línea de coautoría; exclusión de `.secrets/`, del PDF de la asignación y de las fotos de la pizarra; `.gitattributes` para los finales de línea; revisión de que ninguna contraseña quedara en los archivos subidos. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 06 · «acuerdate que eso de la declaracion de la ia  hay que hacerlo como el profesor lo puso en el pdf que te pase» | Ajuste de esta tabla al formato de la sección 8 (5 columnas y declaración jurada inmediatamente debajo); documento aparte para firmar. | Pendiente | Enunciado del curso, sección 8 |
| Claude Code (Claude Opus 5.5) | 07 · «eso del uso de ia te dije que cambiaras mis respuestas osea prompts para que sean mas profesionales y enfocadas en un uso de la herramienta ia, se ve muy poco profesional, el unico prompt que dejas es el que te mande largo, despues en el md que me diste con la explicacion del avance, corrijelo y pon tal y como yo lo voy a decir, osea que yo voy a leer eso para explicarle al profesor, que salga lo que voy a hacer de proyecto, como lo voy a hacer y lo que llevo hasta el momento» | Reescritura de `avance-profesor/EXPLICACION-PARA-EL-PROFESOR.md` como guion de lectura (qué es el proyecto, cómo se hará, avance). Los prompts registrados no se modificaron, porque el enunciado exige el prompt exacto. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 08 · «ok, haz el recorte y la guía» | Se dejaron en la tabla solo los prompts que generaron contenido del trabajo; guía de validación por fila (sección «Guía para completar la validación»). | Pendiente | Enunciado del curso, sección 8 |

**Declaración Jurada:**

Yo, **Ismael Rojas Herrera**, declaro que todo contenido generado con IA ha sido declarado en la tabla anterior, validado contra fuentes oficiales (ISO, documentación del motor de BD) y que asumo responsabilidad por su veracidad. Entiendo que omitir esta declaración constituye falta grave.

Firma: ______________________________ &nbsp;&nbsp; Carné: ____________________ &nbsp;&nbsp; Fecha: ________________

*Sin firmar: el estudiante la firma después de completar las columnas de validación.*

---

## Guía para completar la validación (para el estudiante)

**Regla:** en «Validación / Corrección» escriba **solo lo que usted hizo**, en primera persona y con algo concreto: qué abrió, qué ejecutó, qué resultado vio y qué corrigió o descartó. Es el mismo estilo del ejemplo del enunciado: «Verifiqué en ISO 27002:2022 y descarté A8.4, agregué A8.11». Si no revisó algo, no lo escriba. En «Fuente verificada» anote el documento y la sección que consultó (ejemplo del enunciado: «ISO/IEC 27002:2022 - Cap 8.11»). Calcule unas 2 o 3 horas en total; la fila 04 es la más larga.

### Fila 01: análisis inicial y mapeo de controles
1. Abra las 3 fotos de la pizarra y compare con el escenario del laboratorio: usuario JUAN, rol `vendedores`, `IDLE_TIME`, auditoría (día, hora, usuario, sesión, SQL). ¿Falta algo de la pizarra o algo está mal interpretado?
2. Revise la lista de los 15 controles (pestaña «Controles» del artefacto) contra una fuente sobre ISO/IEC 27002:2022. Para cada uno, ¿el título y el tema coinciden? ¿Hay alguno que no corresponda a confidencialidad o alguno que debería agregarse?
3. *Ejemplo:* «Comparé el escenario con las fotos de la pizarra; coincide. Revisé los 15 controles en [fuente] y confirmé los títulos; [descarté / agregué X porque …]».
4. *Fuente:* la que usted use (norma oficial, biblioteca UNA/INTECO o fuente secundaria; si es secundaria, dígalo).

### Fila 02: elección de Oracle y diagnóstico del entorno
1. Busque en la documentación de Oracle qué versiones XE existieron, para confirmar que no hay 19c XE.
2. Abra el *Oracle AI Database Licensing Information User Manual 26ai* y confirme que la edición Free incluye TDE, Data Redaction y VPD.
3. Abra `evidencias/E-00_diagnostico_entorno.txt` y busque la versión (23.26.1), la PDB `FREEPDB1` y la tabla `V$OPTION`.
4. *Ejemplo:* «Confirmé en el manual de licencias de 26ai que Free incluye TDE, Redaction y VPD. Verifiqué en E-00 la versión 23.26.1 y que Database Vault = FALSE».
5. *Fuente:* el manual de licencias, con el nombre de la sección.

### Fila 03: nombre y documento explicativo
1. Lea `avance-profesor/EXPLICACION-PARA-EL-PROFESOR.md` completo. ¿Puede explicar cada párrafo con sus palabras? Lo que no entienda, investíguelo o corríjalo.
2. *Ejemplo:* «Revisé la explicación, corregí [X] y comprobé que los datos coinciden con el informe».

### Fila 04: laboratorio, scripts, evidencias y documentos (la más importante)
1. **Ejecute el ciclo completo:** `bash herramientas/ejecutar_todo.sh` (unos 8 minutos). Al final compare el resumen con lo esperado: 13 CUMPLE, 2 PARCIAL y VC-07 que pasa de NO CUMPLE a CUMPLE.
2. **Abra al menos 4 scripts y explíqueselos a sí mismo:**
   - `sql/10_lab_setup/05_vpd.sql`: ¿por qué la función devuelve `1 = 0` a quien no tiene regla?
   - `sql/10_lab_setup/06_redaction.sql`: ¿qué hace `REDACT_CCN16_F12`?
   - `sql/20_verificacion/VC-07_acceso_privilegiado.sql`: ¿qué consulta y cuándo dice NO CUMPLE?
   - `sql/30_pruebas/PR-02_vpd_aislamiento_ana.sql`: ¿qué demuestra?
3. **Pruebe algo a mano en SQL Developer** (y tome la captura): conéctese como JUAN y haga `SELECT * FROM ventas_lab.clientes;`. Deben salir solo 10 filas y la tarjeta enmascarada.
4. **Verifique la Ley 8968:** abra el texto en SCIJ y lea los artículos 10 y 11. ¿Lo que dice el marco teórico coincide?
5. **Revise 3 o 4 enlaces** de la sección «Referencias» del informe: que abran y que digan lo que se cita.
6. *Ejemplo:* «Ejecuté ejecutar_todo.sh y obtuve 13 CUMPLE y 2 PARCIAL, igual que las evidencias. Revisé los scripts de VPD, Redaction, VC-07 y PR-02. Probé como JUAN en SQL Developer y vi 10 filas con la tarjeta enmascarada. Confirmé los arts. 10 y 11 de la Ley 8968 en SCIJ. Corregí [X]».
7. *Fuente:* «Ley 8968, arts. 10-11 (SCIJ); Oracle Database Security Guide, capítulos de VPD y Data Redaction».

### Fila 05: repositorio
1. Entre a GitHub y confirme que el repositorio es privado y que no aparecen la carpeta `.secrets/`, el PDF de la asignación ni las fotos.
2. *Ejemplo:* «Revisé el repositorio en GitHub: es privado y no contiene contraseñas ni el material del profesor».

### Fila 06: formato de la tabla de IA
1. Compare esta tabla y la declaración con la sección 8 del PDF de la asignación: las mismas 5 columnas y el mismo texto de la declaración.
2. *Ejemplo:* «Comparé con la sección 8 del enunciado; coinciden las columnas y el texto de la declaración».

### Filas 07 y 08: explicación del avance y esta guía
1. Fila 07: «Leí la explicación y la usé en la reunión de avance; ajusté [X]».
2. Fila 08: «Seguí esta guía para completar la validación».

### Al terminar
- [ ] Ninguna fila dice «Pendiente».
- [ ] Ejecute `python herramientas/generar_entregables.py` para actualizar el informe, el artefacto y el PDF para firmar.
- [ ] Imprima y firme `entregables/Tabla-Uso-IA-Firmada-ISO27001-Oracle.pdf`, o fírmelo digitalmente.

## Herramientas y comandos que ejecutó la IA

Para transparencia, la IA también:

- Ejecutó comandos de solo lectura en el equipo (sistema operativo, herramientas instaladas, contenedores Docker).
- Detuvo el contenedor `rman-lab-oracle`, con autorización del estudiante.
- Creó el contenedor `iso27001-oracle` y ejecutó en él todos los scripts del repositorio. Las salidas están en `evidencias/`.
- Consultó documentación en línea de Oracle, la Ley 8968 (MICITT/SCIJ) y fuentes secundarias sobre ISO 27001:2022 (el texto de la norma es de pago y no estuvo disponible).
- Creó el repositorio privado en GitHub con la cuenta del estudiante y subió el proyecto, con su autorización.
