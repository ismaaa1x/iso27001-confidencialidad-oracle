# Tabla de uso de IA y declaración jurada (registro de trabajo)

> **Versión oficial del entregable 5:** `entregables/Tabla_Uso_IA_Para_Firmar.pdf`. Ese documento reemplaza la tabla de este archivo. Este archivo se conserva como registro de trabajo y ya no se usa para generar ningún entregable.

Formato de la sección 8 del enunciado («Uso ético y documentado de inteligencia artificial»): tabla con las columnas Herramienta IA, Prompt exacto utilizado, Aporte de la IA, Validación / Corrección del estudiante y Fuente verificada. Debajo va la declaración jurada. Es el entregable 5, «Tabla de uso de IA firmada». El informe PDF remite, en la sección «Uso de IA», a la versión oficial `entregables/Tabla_Uso_IA_Para_Firmar.pdf`.

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
| Claude Code (Claude Opus 5.5) | 09 · «bro por que en el pdf y el html del avance escribiste las preguntas al profesor ? ese no es el documento de confidencialidad ?» | Se quitó la sección de consultas al profesor del HTML y del PDF del avance. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 10 · «si, sacalo del repositorio» | Las notas personales para la reunión dejaron de publicarse en el repositorio (`.gitignore`). | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 11 · «si, pon los accesos directos en la carpeta del avance» | Accesos directos locales al artefacto y al informe, y archivo `.bat` para iniciar el contenedor. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 12 · «y digamos si tuvieras que explicar el artefacto completo que me pusiste en evidencias como lo harias, dame una explicacion para yo leerla» | Guion personal para explicar el artefacto (`avance-profesor/EXPLICACION-ARTEFACTO.md`, no publicado). | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 13 · «y dame ese html mejor visualmente como si fuera un sistea completo pero solo el front» | Rediseño del artefacto: menú lateral por fases PHVA, panel general con indicadores, mapa de calor de riesgos, madurez por control, hallazgos y módulo de evidencias con visor. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 14 · «y borra del html la parte de la ia eso lo hacemos despues» | Se quitó la sección de uso de IA del artefacto; se mantiene en el informe y en esta tabla. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 15 · «no puedes correr los scrips y que se vea en mi coomputadora ?» | Script de demostración en vivo `herramientas/demo.sh` (8 pasos que no modifican el laboratorio ni las evidencias) y acceso directo local. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 16 · «okey bro no he hecho nada desde la ultima vez, necesito que me pongas en una carpeta aparte, por ejemplo todo lo que llevamos para entregar o avanzado en una carpeta llamada chatgpt» | Carpeta local `chatgpt/` con una copia ordenada de todo lo avanzado y un índice (`00-LEEME.md`). | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 17 · Texto completo en `docs/ia/prompt-17-seguimiento-historico.md` (seguimiento histórico de controles a partir de las fotos de la pizarra del 28/10/2026), más la línea «y dime despues de hacer esos cambios que es lo que tengo que hacer yo que no puedas hacer tu y falte para la entrega paso a paso» | Módulo «Matriz y seguimiento» del artefacto: registro de evaluaciones con revisiones, semáforo, gráfica de evolución por fechas, historial, indicadores, exportación e importación JSON, evaluaciones base recuperadas de las evidencias y datos de demostración separados; pruebas automatizadas en el navegador; documentación (`docs/seguimiento-evaluaciones.md`). | Pendiente | Fotos de la pizarra del 28/10/2026; enunciado del curso (escala 0–4, matriz) |
| Claude Code (Claude Opus 5.5) | 18 · «veo que hay muchas carpetas sueltas en este proyecto, muchas versiones, puedes borrar lo que ests sobre guardado y dejar lo mas reciente limpio» (respuestas a la consulta: «Borrar ambas (Recomendado)» y «Sí, en material-del-curso/ (Recomendado)») | Inventario del proyecto; se eliminaron la copia `chatgpt/`, `chatgpt.zip` (desactualizado), `corrida.log` y la caché de Python; el enunciado y las fotos de la pizarra se ordenaron en `material-del-curso/`. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 19 · «la carpeta de avance creo que ya se puede eliminar ya que solo era para mostrarsela al profesor» (respuesta a la consulta: «Borrar todo») | Se eliminó la carpeta `avance-profesor/` (PDF y HTML del avance, guiones personales, accesos directos y `.bat`); el PDF y el HTML del avance quedan en el historial de Git. | Pendiente | — |

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
1. El documento explicativo del avance se usó en la reunión con el profesor y luego se eliminó junto con la carpeta del avance (fila 19). Describa cómo lo usó y qué ajustó.
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

### Filas 09 a 16: ajustes del avance, artefacto, demo y copia
1. Abra cada cosa que se menciona y compruebe que hace lo que dice la fila: el PDF del avance sin consultas, el repositorio sin notas personales, los accesos directos, el artefacto rediseñado sin la sección de IA y la demo en vivo. La carpeta `chatgpt/` se eliminó después (fila 18).
2. *Ejemplo:* «Ejecuté la demo en vivo y vi los 8 pasos; comprobé que las evidencias no cambiaron».

### Fila 17: seguimiento histórico (pizarra del 28/10)
1. Compare con las 2 fotos nuevas de la pizarra: E(i,t), varios controles en la misma gráfica y el semáforo rojo, amarillo y verde.
2. Siga la guía `docs/seguimiento-evaluaciones.md`: registre al menos 2 evaluaciones propias de un control, agregue otro a la gráfica, filtre por fechas, corrija una y exporte el JSON.
3. Decida si deja o no los datos de demostración, y si registra una madurez para la ejecución «antes» de VC-07 (hoy queda «No asignada» porque nadie la evaluó en ese momento).
4. *Ejemplo:* «Registré 2 evaluaciones de A.8.2 con mis capturas de SQL Developer, comparé A.8.2 y A.5.17 en la gráfica y exporté el respaldo».

### Fila 18: limpieza
1. Revise que la carpeta del proyecto solo tenga las carpetas actuales y que `material-del-curso/` tenga el enunciado y las 5 fotos.

### Fila 19: eliminación de la carpeta del avance
1. Confirme que ya no necesita el material del avance; el PDF se puede recuperar del historial de Git si hiciera falta.

### Al terminar
- [ ] Ninguna fila dice «Pendiente».
- [ ] Si usó otra IA (por ejemplo, ChatGPT para redactar algún prompt), agregue su propia fila con esa herramienta y el prompt exacto.
- [ ] Imprima y firme `entregables/Tabla_Uso_IA_Para_Firmar.pdf` (versión oficial), o fírmelo digitalmente, y complete carné y fecha.

## Herramientas y comandos que ejecutó la IA

Para transparencia, la IA también:

- Ejecutó comandos de solo lectura en el equipo (sistema operativo, herramientas instaladas, contenedores Docker).
- Detuvo el contenedor `rman-lab-oracle`, con autorización del estudiante.
- Creó el contenedor `iso27001-oracle` y ejecutó en él todos los scripts del repositorio. Las salidas están en `evidencias/`.
- Consultó documentación en línea de Oracle, la Ley 8968 (MICITT/SCIJ) y fuentes secundarias sobre ISO 27001:2022 (el texto de la norma es de pago y no estuvo disponible).
- Creó el repositorio privado en GitHub con la cuenta del estudiante y subió el proyecto, con su autorización.
- Eliminó, a pedido del estudiante, archivos duplicados o temporales (`chatgpt/`, `chatgpt.zip`, `corrida.log`, caché de Python) y movió el material del curso a `material-del-curso/`.
- Eliminó, a pedido del estudiante, la carpeta `avance-profesor/`.
