# Registro del uso de inteligencia artificial

Tabla exigida en la sección 8 del enunciado. Los prompts se transcriben **exactamente** como se escribieron, incluidas las faltas de ortografía. El prompt 01, por su extensión, está completo en `prompt-01-analisis-inicial.md`.

**Estado de validación:** las columnas «Validación / corrección del estudiante» y «Fuente verificada» quedan **Pendientes** hasta que el estudiante las complete con lo que revisó personalmente. La IA no puede afirmar que el estudiante validó algo.

| # | Herramienta IA | Prompt exacto utilizado | Aporte de la IA | Validación / corrección del estudiante | Fuente verificada |
|---|---|---|---|---|---|
| 01 | Claude Code (Claude Opus 5.5, Anthropic) | Ver `prompt-01-analisis-inicial.md` (texto completo) | Lectura del enunciado y las pizarras; transcripción con dudas marcadas; diagnóstico del equipo; verificación de las funciones de Oracle por edición; plan PHVA. | Pendiente | Pendiente |
| 02 | Claude Code (Claude Opus 5.5) | «entonces que es lo que hay que hacer o que es lo que necesitas de mi para hacer el trabajo» | Lista de decisiones y pasos pendientes. | Pendiente | — |
| 03 | Claude Code (Claude Opus 5.5) | «1. -si es mi laptop, -si,-es individual y mañana necesito llevar un base para enseñarle al profesor y explicarle algo mas o menos 2. tu no puedes descargar oracle?, no te sirve el de docker que tengo ?» (respuestas a la consulta: «usa la que tu creas que es mejor» y «Detenerlo (Recomendado)») | Creación del contenedor Oracle 26ai Free aislado; diagnóstico E-00; borrador de avance (escala, riesgos, tareas, mapeo ISO). | Pendiente | Oracle AI Database Licensing Information User Manual 26ai (pendiente de revisión) |
| 04 | Claude Code (Claude Opus 5.5) | «entonces del proyecto en si no haz hecho nada? segundo mi nombre es ismael rojas herrera para que lo agregues, tercero, dame un md explicando un poco el proyecto en general, lo que voy a hacer para desarrollarlo y  TODO el avance» | Nombre agregado; documento explicativo del avance. | Pendiente | — |
| 05 | Claude Code (Claude Opus 5.5) | «bro no hay que desarrollar un sistema ?» | Aclaración basada en las secciones 6 y 10 del enunciado: el entregable es un artefacto (HTML/PDF/sitio) con scripts SQL, no una aplicación. | Pendiente: confirmar con el profesor | Enunciado del curso, secciones 6 y 10 |
| 06 | Claude Code (Claude Opus 5.5) | «ok, empeza con todo el proyecto, pero separame muy bien en una carpeta lo del avance por APARTE, el md explicativo corrigelo la explicacion damela como si yo la fuera a leer y es exactamente lo que le tengo que decir al profesor por si me pregunta» | Laboratorio completo (10 scripts de configuración), 15 verificaciones, 19 pruebas, 3 scripts de la fase Actuar, ejecución con evidencias, marco teórico, README, artefacto, informe, guion y checklist; carpeta `avance-profesor/` separada. | Pendiente | Ley 8968 (texto de SCIJ/MICITT, arts. 1-3, 9-11); documentación de Oracle 21c/26ai (pendiente de revisión) |

## Cómo completar la validación (para el estudiante)

Para cada fila, escriba en «Validación / corrección» qué hizo **usted**. Por ejemplo:

- *«Comparé la transcripción con las fotos y corregí X»* (fila 01).
- *«Ejecuté `bash herramientas/ejecutar_todo.sh` y obtuve los mismos resultados en evidencias/»* (fila 06).
- *«Abrí la guía de licencias de Oracle 26ai y confirmé que Free incluye TDE, Redaction y VPD»* (fila 03).
- *«Revisé los títulos de los 15 controles en ISO/IEC 27002:2022 (biblioteca UNA/INTECO)»*. Si no tuvo acceso a la norma, escríbalo así.

En «Fuente verificada», anote la fuente que **usted** consultó (documento y sección).

## Herramientas y comandos que ejecutó la IA

Para transparencia, la IA también:

- Ejecutó comandos de solo lectura en el equipo (sistema operativo, herramientas instaladas, contenedores Docker).
- Detuvo el contenedor `rman-lab-oracle`, con autorización del estudiante.
- Creó el contenedor `iso27001-oracle` y ejecutó en él todos los scripts del repositorio. Las salidas están en `evidencias/`.
- Consultó documentación en línea de Oracle, la Ley 8968 (MICITT/SCIJ) y fuentes secundarias sobre ISO 27001:2022 (el texto de la norma es de pago y no estuvo disponible).
