# Tabla de uso de IA y declaración jurada

Formato de la sección 8 del enunciado («Uso ético y documentado de inteligencia artificial»): tabla con las columnas Herramienta IA, Prompt exacto utilizado, Aporte de la IA, Validación / Corrección del estudiante y Fuente verificada. Debajo va la declaración jurada. Es el entregable 5, «Tabla de uso de IA firmada». El informe PDF la incluye en la sección «Uso de IA», y también existe como documento aparte para imprimir y firmar: `entregables/Tabla-Uso-IA-Firmada-ISO27001-Oracle.pdf`.

Los prompts se transcriben **exactamente** como se escribieron, incluidas las faltas de ortografía. El prompt 01, por su extensión, está completo en `prompt-01-analisis-inicial.md`. Las columnas «Validación / Corrección del estudiante» y «Fuente verificada» quedan en **Pendiente** hasta que el estudiante las complete con lo que revisó personalmente.

| Herramienta IA | Prompt exacto utilizado | Aporte de la IA | Validación / Corrección del estudiante | Fuente verificada |
|---|---|---|---|---|
| Claude Code (Claude Opus 5.5, Anthropic) | 01 · Texto completo en `docs/ia/prompt-01-analisis-inicial.md` (especificación del proyecto: PHVA, riesgos R-CONF, 15 controles, matriz, pruebas, restricciones de seguridad y de citación) | Lectura del enunciado y las pizarras; transcripción con dudas marcadas; diagnóstico del equipo (solo lectura); verificación de las funciones de Oracle por edición; plan PHVA. | Pendiente | Pendiente |
| Claude Code (Claude Opus 5.5) | 02 · «entonces que es lo que hay que hacer o que es lo que necesitas de mi para hacer el trabajo» | Lista de decisiones y pasos pendientes. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 03 · «1. -si es mi laptop, -si,-es individual y mañana necesito llevar un base para enseñarle al profesor y explicarle algo mas o menos 2. tu no puedes descargar oracle?, no te sirve el de docker que tengo ?» (respuestas a la consulta: «usa la que tu creas que es mejor» y «Detenerlo (Recomendado)») | Elección de Oracle AI Database 26ai Free; creación del contenedor aislado `iso27001-oracle`; diagnóstico E-00; borrador de avance (escala, riesgos, tareas, mapeo ISO). | Pendiente | Oracle AI Database Licensing Information User Manual 26ai (pendiente de revisión) |
| Claude Code (Claude Opus 5.5) | 04 · «entonces del proyecto en si no haz hecho nada? segundo mi nombre es ismael rojas herrera para que lo agregues, tercero, dame un md explicando un poco el proyecto en general, lo que voy a hacer para desarrollarlo y  TODO el avance» | Nombre agregado; documento explicativo del avance. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 05 · «bro no hay que desarrollar un sistema ?» | Aclaración basada en las secciones 6 y 10 del enunciado: el entregable es un artefacto (HTML/PDF/sitio) con scripts SQL, no una aplicación. | Pendiente: confirmar con el profesor | Enunciado del curso, secciones 6 y 10 |
| Claude Code (Claude Opus 5.5) | 06 · «ok, empeza con todo el proyecto, pero separame muy bien en una carpeta lo del avance por APARTE, el md explicativo corrigelo la explicacion damela como si yo la fuera a leer y es exactamente lo que le tengo que decir al profesor por si me pregunta» | Laboratorio completo (10 scripts de configuración), 15 verificaciones, 19 pruebas, 3 scripts de la fase Actuar, ejecución con evidencias, marco teórico, README, artefacto, informe, guion y checklist; carpeta `avance-profesor/` separada. | Pendiente | Ley 8968 (texto de SCIJ/MICITT, arts. 1-3, 9-11); documentación de Oracle 21c/26ai (pendiente de revisión) |
| Claude Code (Claude Opus 5.5) | 07 · «cual repositorio ?» | Aclaración: el repositorio Git era solo local (`git init`, sin commits ni remoto). La sección 7 del enunciado pide un «repositorio Git institucional» sin indicar cuál; queda como consulta al profesor. | Pendiente | Enunciado del curso, sección 7 |
| Claude Code (Claude Opus 5.5) | 08 · «como lo subiste al git si no existe repositorio ? no puedes hacer tu el repositorio sin marca de agua ?» (respuestas a la consulta: «Privado (Recomendado)» y «No incluirlos (Recomendado)») | Creación del repositorio privado `ismaaa1x/iso27001-confidencialidad-oracle` en GitHub con la cuenta del estudiante; primer commit sin línea de coautoría; exclusión de `.secrets/`, del PDF de la asignación y de las fotos de la pizarra; `.gitattributes` para los finales de línea; revisión de que ninguna contraseña quedara en los archivos subidos. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 09 · «entonces que falta del proyecto en general para terminarlo ? y para el avance que llevo ?» | Lista de pendientes del avance y del proyecto final. | Pendiente | — |
| Claude Code (Claude Opus 5.5) | 10 · «en la parte de los prompts cambia un poco los promots que te di jaja, tipo son cero profesionales y creo que se ven mal,pon prompts que haga creer al profesor que entiendo los temas y que solo uso la ia como herramienta de trabajo, corrije eso en todas las partes donde haya que poner eso» | Ninguno sobre el contenido: la IA no modificó los prompts registrados, porque el enunciado exige el prompt exacto. | Pendiente | Enunciado del curso, sección 8 |
| Claude Code (Claude Opus 5.5) | 11 · «acuerdate que eso de la declaracion de la ia  hay que hacerlo como el profesor lo puso en el pdf que te pase» | Ajuste de esta tabla al formato de la sección 8 (5 columnas y declaración jurada inmediatamente debajo); documento aparte para firmar. | Pendiente | Enunciado del curso, sección 8 |

**Declaración Jurada:**

Yo, **Ismael Rojas Herrera**, declaro que todo contenido generado con IA ha sido declarado en la tabla anterior, validado contra fuentes oficiales (ISO, documentación del motor de BD) y que asumo responsabilidad por su veracidad. Entiendo que omitir esta declaración constituye falta grave.

Firma: ______________________________ &nbsp;&nbsp; Carné: ____________________ &nbsp;&nbsp; Fecha: ________________

*Sin firmar: el estudiante la firma después de completar las columnas de validación.*

---

## Antes de firmar (para el estudiante)

- [ ] Cada fila tiene completa la columna «Validación / Corrección del estudiante» con lo que **usted** revisó o corrigió.
- [ ] Ejecutó o revisó personalmente las evidencias de `evidencias/` que se citan en el informe.
- [ ] Contrastó los títulos de los controles con ISO/IEC 27002:2022, o declaró en el informe que no tuvo acceso al texto oficial.
- [ ] Revisó los enlaces de Oracle y de la Ley 8968 citados en las referencias.

Ejemplos de cómo llenar la validación, siguiendo el ejemplo del enunciado («Verifiqué en ISO 27002:2022 y descarté A8.4, agregué A8.11»):

- *«Comparé la transcripción con las fotos y corregí X»* (fila 01).
- *«Ejecuté `bash herramientas/ejecutar_todo.sh` y obtuve los mismos resultados en evidencias/»* (fila 06).
- *«Abrí la guía de licencias de Oracle 26ai y confirmé que Free incluye TDE, Redaction y VPD»* (fila 03).
- *«Revisé los títulos de los 15 controles en ISO/IEC 27002:2022 (biblioteca UNA/INTECO)»*. Si no tuvo acceso a la norma, escríbalo así.

En «Fuente verificada», anote la fuente que **usted** consultó, con documento y sección (el ejemplo del enunciado es «ISO/IEC 27002:2022 - Cap 8.11»).

Después de editar este archivo, ejecute `python herramientas/generar_entregables.py` para actualizar el informe, el artefacto y el PDF para firmar.

## Herramientas y comandos que ejecutó la IA

Para transparencia, la IA también:

- Ejecutó comandos de solo lectura en el equipo (sistema operativo, herramientas instaladas, contenedores Docker).
- Detuvo el contenedor `rman-lab-oracle`, con autorización del estudiante.
- Creó el contenedor `iso27001-oracle` y ejecutó en él todos los scripts del repositorio. Las salidas están en `evidencias/`.
- Consultó documentación en línea de Oracle, la Ley 8968 (MICITT/SCIJ) y fuentes secundarias sobre ISO 27001:2022 (el texto de la norma es de pago y no estuvo disponible).
- Creó el repositorio privado en GitHub con la cuenta del estudiante y subió el proyecto, con su autorización.
