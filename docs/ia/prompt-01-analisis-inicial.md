# Prompt 01 — Análisis inicial

- Herramienta: Claude Code (modelo Claude Opus 5.5, `claude-opus-5-5`)
- Fecha: 2026-10-21
- Texto exacto del prompt enviado por el estudiante (sin modificaciones):

---

Necesito que me ayudes a desarrollar mi proyecto universitario de Administración de Bases de Datos sobre controles ISO/IEC 27001:2022 e ISO/IEC 27002:2022 para proteger la confidencialidad en Oracle.

En la carpeta del proyecto encontrarás:

* Asignacion-ISO27001-Confidencialidad-DBA-II-Ciclo-2026-UNA.pdf.
* Tres fotografías de las pizarras del profesor.

Primero lee el PDF completo y examina las tres imágenes. El PDF contiene los requisitos oficiales; las pizarras complementan las explicaciones. No mezcles este trabajo con otros proyectos de respaldos ni asumas que necesito un dominio, hosting o una aplicación completa.

OBJETIVO

Ayudarme a producir un trabajo técnicamente correcto, verificable y comprensible, que pueda ejecutar y explicar personalmente. No quiero solamente un documento teórico ni una interfaz bonita: necesito controles vinculados con riesgos reales y scripts que permitan comprobarlos en Oracle.

ANÁLISIS INICIAL

Antes de implementar:

1. Revisa los archivos existentes y cualquier instrucción del repositorio.
2. Extrae los requisitos del PDF y relaciónalos con la rúbrica y los entregables.
3. Transcribe lo legible de las pizarras, separando las observaciones claras de las interpretaciones.
4. Si alguna palabra, instrucción SQL o número no se distingue, indícalo; no lo completes como si fuera seguro.
5. Identifica contradicciones o ejemplos que no correspondan a Oracle.

En las fotografías se aprecian temas como:

* Confidencialidad: acceso a datos sensibles y copias no autorizadas.
* Usuarios, privilegios, roles, perfiles y políticas de seguridad.
* Ejemplos de CREATE USER, GRANT, CREATE ROLE e IDLE_TIME.
* Control interno y administración de riesgos.
* Trazabilidad, auditoría, redo logs online, archived logs y LogMiner.
* Referencias que parecen mencionar SYS.AUD$ y Oracle XE; comprueba la transcripción antes de utilizarlas.

No conviertas todos los temas de la pizarra en funciones obligatorias. Explica cuáles contribuyen directamente al trabajo de confidencialidad y cuáles sirven como contexto.

ENTORNO TÉCNICO

Comprueba mediante operaciones de solo lectura:

* Sistema operativo.
* Herramientas Oracle y SQL Developer disponibles.
* Versión y edición reales de Oracle, si puedes conectarte.
* Arquitectura CDB/PDB y contenedor donde se realizarán las pruebas.
* Privilegios disponibles para ejecutar las consultas.
* Herramientas existentes que permitan generar el artefacto y el informe.

No busques contraseñas ni muestres secretos. Si no puedes conectarte, proporciona instrucciones y consultas exactas para que yo obtenga la información.

El PDF propone Oracle 19c/21c XE. Verifica las denominaciones y capacidades reales de las versiones y ediciones antes de diseñar los controles. No asumas que todas permiten las mismas características.

REQUISITOS DEL TRABAJO

Organiza la solución con la metodología PHVA y cubre:

1. Riesgos de confidencialidad
   Define al menos cinco riesgos, identificados como R-CONF-01 a R-CONF-05, con:

* Activo o información afectada.
* Amenaza y vulnerabilidad.
* Escenario concreto.
* Impacto y probabilidad.
* Justificación de la valoración.
* Controles relacionados.

Define la escala de evaluación y diferencia riesgo inherente y residual si los utilizas. No inventes mediciones de una organización real.

2. Tareas del DBA
   Mapea al menos doce tareas críticas, incluyendo:

* Gestión de usuarios.
* Privilegios.
* Autenticación.
* Cifrado TDE.
* Enmascaramiento.
* Respaldos.
* Auditoría.
* Parcheo.
* Listener y configuración de red.
* Eliminación segura.
* Gestión de logs.
* Clones de desarrollo y pruebas.

Distingue tareas que pueden demostrarse en mi entorno de las que requieren otra edición, licencia, infraestructura o permisos.

3. Controles ISO
   Analiza los controles indicados en el PDF:
   A.5.12, A.5.15, A.5.16, A.5.17, A.5.18, A.5.33,
   A.8.2, A.8.3, A.8.5, A.8.10, A.8.11, A.8.12,
   A.8.13, A.8.15 y A.8.20.

Para cada uno:

* Verifica su identificador y denominación.
* Explica su pertinencia para la confidencialidad.
* Relaciónalo con riesgos y tareas.
* Propón una implementación en Oracle.
* Define evidencia observable y limitaciones.

Diferencia ISO 27001, su Anexo A e ISO 27002. No presentes la aplicación de estos controles como una certificación de cumplimiento.

4. Controles observables
   Prepara quince comprobaciones observables por un auditor externo. Diferencia el control ISO de la comprobación técnica utilizada para evaluarlo.

5. Matriz de evaluación
   Incluye como mínimo:
   Tarea | Riesgo | Control | Criterio 0–4 | Evidencia | Estado.

Define criterios concretos para cada nivel de madurez, evitando descripciones genéricas. Diferencia madurez de cumplimiento.

Utiliza Cumple, No cumple o Parcial cuando exista evidencia suficiente. Cuando todavía no haya pruebas, señala “Pendiente de evaluación”; no inventes resultados para completar la matriz.

6. Batería de pruebas
   Incluye:
   ID | Tipo | Procedimiento | Resultado esperado | Herramienta.

Añade requisitos previos, usuario o privilegios necesarios, resultado obtenido y evidencia cuando se ejecuten.

7. Marco teórico
   Prepara una síntesis de dos a tres páginas que cubra:

* Cambios de ISO 27001:2013 a 2022.
* Mínimo privilegio y separación de funciones.
* Defensa en profundidad y Zero Trust en bases de datos.
* TDE, enmascaramiento, Data Redaction, RLS/VPD y TLS.
* DLP y respaldos cifrados.
* Logging, monitoreo y SIEM.
* Ley 8968 de Costa Rica y su reglamento.

INVESTIGACIÓN Y PRECISIÓN

Consulta fuentes oficiales vigentes:

* ISO para la estructura y controles de las normas.
* Documentación Oracle correspondiente a la versión.
* Fuentes oficiales costarricenses para la normativa.

No inventes referencias, citas textuales, páginas, enlaces ni requisitos. Si no puedes acceder al texto completo de una norma, explica esa limitación y distingue lo verificado de lo pendiente.

El PDF incluye pg_hba.conf como ejemplo, pero ese archivo corresponde a PostgreSQL: no lo utilices como configuración de Oracle.

Verifica qué mecanismo de auditoría corresponde al entorno antes de elegir vistas o scripts. No asumas que SYS.AUD$ es la fuente adecuada en todos los casos.

Explica los límites de redo logs y LogMiner: no los presentes como sustitutos generales de la auditoría ni como evidencia de todas las consultas SELECT.

SCRIPTS Y DEMOSTRACIÓN

Produce scripts .sql de verificación con:

* Propósito.
* Versión o condiciones de compatibilidad.
* Privilegios necesarios.
* Contenedor de ejecución cuando corresponda.
* Consultas.
* Interpretación del resultado.
* Limitaciones.

Prioriza consultas de solo lectura. Separa los scripts que crean objetos o usuarios de laboratorio de los scripts que verifican controles.

Para demostrar permisos, utiliza datos ficticios y un esquema de pruebas aislado. Incluye pruebas positivas y negativas: acciones permitidas y acciones denegadas.

No modifiques usuarios existentes, políticas globales, auditoría, listener, cifrado o configuraciones sensibles sin explicar primero el cambio y obtener autorización. No trabajes sobre producción.

Si una característica no está disponible, documenta la limitación y propone una alternativa viable, aclarando si ofrece una protección diferente. No presentes una simulación como implementación real.

ARTEFACTO Y ENTREGABLES

Recomienda el formato más sencillo que cumpla la asignación. Mi preferencia inicial es un HTML interactivo local, fácil de abrir, con tablas, filtros y navegación, acompañado del informe PDF y los scripts. No necesita dominio ni servicios externos salvo que exista una razón concreta.

El artefacto debe incluir riesgos, tareas, controles, matriz, pruebas y referencias. Si no tiene conexión real con Oracle, debe mostrar claramente que presenta información y evidencias registradas; no debe fingir análisis en tiempo real.

Prepara también:

* Informe con referencias APA 7.
* README con instalación, ejecución de scripts e interpretación.
* Estructura del repositorio Git.
* Guion de demostración de aproximadamente cinco minutos.
* Lista de evidencias que debo capturar.
* Lista de verificación de todos los entregables y la rúbrica.

DOCUMENTACIÓN OBLIGATORIA DE IA

Conserva este prompt exacto y registra los siguientes usos de IA. Incluye:
Herramienta IA | Prompt exacto utilizado | Aporte de la IA | Validación/corrección del estudiante | Fuente verificada.

No afirmes que yo validé algo que aún no he revisado. Deja esos campos pendientes e indícame cómo realizar la validación.

Incluye el modelo de declaración jurada exigido por el PDF, con campos para mi nombre y firma. No la firmes ni declares en mi nombre que ya completé las verificaciones.

FORMA DE TRABAJAR

En tu primera respuesta:

1. Confirma qué archivos pudiste leer.
2. Resume los requisitos y explica lo recuperado de las pizarras.
3. Presenta el diagnóstico del entorno que hayas podido verificar.
4. Recomienda el alcance y la estructura de entregables.
5. Propón un plan por etapas.
6. Señala las preguntas que realmente bloqueen el trabajo.

Todavía no implementes ni cambies configuraciones en esta primera etapa. Después avanzaremos con los scripts, el artefacto y el informe sobre una base técnica comprobada.

Explícame las decisiones en español claro, de manera que pueda defender el trabajo ante el profesor.

---

---

El registro de este prompt (aporte de la IA, validación y fuente) está en la tabla de uso de IA: `docs/ia/registro-uso-ia.md`.
