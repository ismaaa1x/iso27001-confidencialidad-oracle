# Prompt 17 — Seguimiento histórico de controles

- Herramienta: Claude Code (modelo Claude Opus 5.5, `claude-opus-5-5`)
- Fecha: 2026-10-28
- Texto exacto enviado por el estudiante (sin modificaciones). El bloque principal se pegó en el mensaje y al final se agregó una línea propia, que se transcribe después del separador.

---

Necesito que modifiques el artefacto existente de mi proyecto ISO/IEC 27001:2022 sobre confidencialidad en Oracle. Tu objetivo principal es incorporar seguimiento histórico de controles, gráficas de evolución y una matriz que permita registrar y consultar evaluaciones.

Estos cambios surgen de una reunión con el profesor. Lee las dos nuevas fotografías de la pizarra junto con el enunciado original y revisa el proyecto actual antes de implementar.

CONTEXTO

Ya existen un artefacto HTML, un generador Python, archivos JSON, scripts SQL, evidencias y documentos. Aprovecha lo que funciona y modifica las fuentes correspondientes para que las mejoras se conserven al regenerar los entregables.

Identifica si estás trabajando en el proyecto original o en la copia organizada por carpetas. No asumas que las rutas de ambas estructuras son iguales.

El profesor quiere observar cómo distintos controles mejoran, empeoran o permanecen estables a través del tiempo. El artefacto debe permitir seleccionar un control y agregar otros a la misma gráfica, además de consultar períodos mediante fechas Desde/Hasta.

No interpretes “control i” como una jerarquía de subcontroles: en este contexto representa distintos controles seleccionables.

1. REGISTRO HISTÓRICO DE EVALUACIONES

Implementa un formulario para registrar evaluaciones de los controles existentes con:

* Identificador y nombre del control.
* Fecha de evaluación y hora cuando sea necesaria.
* Madurez de 0 a 4.
* Estado: Cumple, Parcial o No cumple.
* Evidencia o referencia que respalda la evaluación.
* Observaciones y justificación.
* Responsable de la evaluación, cuando corresponda.

Utiliza la escala 0–4 porque es la indicada en el enunciado. No introduzcas una escala 0–1 basada únicamente en una interpretación de la pizarra.

Diferencia:

* El catálogo de controles.
* Las evaluaciones históricas de cada control.
* Los controles seleccionados para visualizar en la gráfica.

Registrar una nueva evaluación debe agregar un registro, no sustituir el anterior. Permite corregir errores de captura conservando una revisión del valor anterior, la fecha del cambio y su motivo. No presentes ese historial local como un registro de auditoría inviolable.

Valida campos obligatorios, valores permitidos y fechas. Permite varias evaluaciones del mismo control y define cómo distinguirlas si coinciden en el mismo día.

2. SEMÁFORO DE ESTADO

Incluye color y texto:

* Verde: Cumple.
* Amarillo: Parcial.
* Rojo: No cumple.
* Gris: Pendiente de evaluación.

El semáforo debe aparecer en la matriz, el detalle de las evaluaciones y los puntos consultados de las gráficas.

El estado debe fundamentarse en los criterios del control y sus evidencias. No conviertas automáticamente la madurez en un estado de cumplimiento sin una regla explícita y justificada.

Un control sin evaluación no equivale a uno con madurez 0. Muéstralo como pendiente, sin inventar puntuaciones.

3. GRÁFICA DE EVOLUCIÓN

Implementa una gráfica temporal que permita:

* Seleccionar un control.
* Agregar otros controles a la misma gráfica.
* Quitar controles de la visualización sin eliminar sus datos.
* Filtrar mediante Desde y Hasta.
* Restablecer filtros.
* Consultar el historial completo.

Características:

* Eje horizontal: fechas reales, con distancia proporcional al tiempo.
* Eje vertical: madurez de 0 a 4.
* Una línea por control y colores estables para identificarlos.
* Leyenda con identificador y nombre.
* Puntos correspondientes a evaluaciones realmente registradas.
* Detalle al seleccionar o señalar un punto: control, fecha, madurez, estado con semáforo, evidencia y observaciones.

El color de cada línea identifica el control; el semáforo representa el estado de una evaluación. Haz que esta diferencia resulte clara.

Ordena los registros cronológicamente. No generes valores intermedios ni suavices las curvas de una forma que sugiera mediciones inexistentes. Si unes puntos, aclara que representan observaciones puntuales.

Muestra mensajes claros cuando:

* No hay controles seleccionados.
* No hay evaluaciones en el período.
* Solo existe una evaluación.
* La fecha Desde es posterior a Hasta.

Los límites del período deben ser inclusivos. Evita desplazamientos de fecha causados por conversiones UTC; define el manejo de fechas con zona America/Costa_Rica cuando corresponda.

Permite identificar mejora, deterioro o estabilidad comparando las puntuaciones disponibles del mismo control. Si solo hay un registro, indica que no existe información suficiente para determinar una tendencia.

4. MATRIZ DE EVALUACIÓN Y SEGUIMIENTO

Conserva los campos exigidos:
Tarea | Riesgo | Control | Criterio 0–4 | Evidencia | Estado.

Añade los campos necesarios para el seguimiento, como fecha, madurez obtenida, observaciones y acceso al historial.

Organiza la interfaz en dos vistas complementarias:

A. Resumen por control:

* Última evaluación disponible dentro del período seleccionado.
* Fecha.
* Madurez.
* Estado con semáforo.
* Acceso a evidencia e historial.
* Variación respecto a la evaluación anterior dentro del período, si existe.

B. Historial:

* Todas las evaluaciones del control.
* Filtros por fechas, control y estado.
* Acceso para registrar una evaluación y corregir errores conservando las revisiones.

Los controles sin registros dentro del período deben aparecer como “Sin evaluación en el período”, sin asignarles un resultado anterior como si fuera actual.

La matriz, las gráficas y los indicadores deben utilizar los mismos registros y filtros. Explica qué representan los promedios o porcentajes que muestres y excluye los valores pendientes del cálculo, indicando cuántos controles quedaron sin evaluar.

5. PERSISTENCIA Y PORTABILIDAD

Los registros deben mantenerse al cerrar y volver a abrir el artefacto. No basta con guardarlos en una variable JavaScript.

Elige la solución más sencilla compatible con la arquitectura existente. Si utilizas almacenamiento local del navegador:

* Explica que los datos dependen del navegador y del equipo.
* Incluye exportación e importación de evaluaciones y revisiones en JSON.
* Valida la estructura del archivo importado.
* Detecta duplicados mediante identificadores estables.
* No reemplaces silenciosamente los registros existentes.
* Maneja errores de almacenamiento y advierte cuando no se haya guardado.

Distingue los datos base incluidos por el generador de las evaluaciones creadas desde la interfaz. Regenerar o actualizar el HTML no debe descartar silenciosamente las evaluaciones del usuario. Proporciona un procedimiento claro de respaldo y migración.

No agregues un backend, dominio o infraestructura adicional salvo que demuestres que es necesario para estos requisitos.

6. INTEGRACIÓN CON LAS EVIDENCIAS EXISTENTES

Revisa qué evaluaciones históricas pueden recuperarse de los archivos reales, incluyendo resultados antes y después de las correcciones.

Importa únicamente registros respaldados por evidencia suficiente. Conserva referencias a sus archivos y distingue:

* Fecha de ejecución de la prueba.
* Fecha de evaluación.
* Fecha de generación del artefacto.

No inventes fechas ni distribuyas resultados en días distintos para producir una gráfica más atractiva.

Si las evidencias solo contienen mediciones de una misma jornada, conserva esa realidad. Para demostrar la evolución temporal puedes ofrecer datos de ejemplo separados, claramente identificados como demostración, que no se mezclen con los resultados reales ni con sus indicadores.

Las evaluaciones registradas manualmente deben identificarse como tales. No deben aparentar que se ejecutó una comprobación automática en Oracle.

7. CALIDAD Y VALIDACIÓN

Mejora la presentación lo necesario para integrar estas funciones:

* Formularios claros.
* Tablas legibles.
* Diseño adaptable.
* Navegación accesible mediante teclado.
* Estados identificables sin depender únicamente del color.
* Evidencias mostradas como texto seguro, sin ejecutar HTML introducido por el usuario.

Prueba en el navegador:

1. Registrar varias evaluaciones de un control.
2. Agregar un segundo control a la gráfica.
3. Mostrar mejora, deterioro y estabilidad.
4. Filtrar por fechas, incluyendo los límites.
5. Consultar un período sin registros.
6. Corregir una evaluación y consultar su revisión.
7. Cerrar y abrir el artefacto comprobando la persistencia.
8. Exportar e importar sin duplicar ni perder información.
9. Comprobar la coincidencia entre matriz, gráfica e indicadores.
10. Regenerar el artefacto y verificar el procedimiento de conservación de datos.

Para validar la interfaz no ejecutes scripts de limpieza ni reconfigures Oracle. Utiliza las evidencias existentes y datos de prueba separados.

FORMA DE TRABAJAR

Primero presenta un diagnóstico breve y las decisiones de implementación. Después realiza los cambios y compruébalos; no te detengas únicamente en proponer un plan.

Prioriza estos requisitos sobre cambios estéticos generales. Conserva las funciones y contenidos válidos del artefacto.

Al terminar entrega:

* Resumen de lo implementado.
* Archivos modificados.
* Ubicación del artefacto actualizado.
* Instrucciones para registrar evaluaciones, comparar controles y filtrar fechas.
* Procedimiento para guardar, exportar, importar y conservar los datos al regenerar.
* Pruebas realizadas.
* Limitaciones y pendientes reales.

Actualiza las instrucciones de uso y los documentos afectados para que describan fielmente el funcionamiento implementado.

---

Línea agregada por el estudiante al final del mismo mensaje:

y dime despues de hacer esos cambios que es lo que tengo que hacer yo que no puedas hacer tu y falte para la entrega paso a paso

---

El registro de este prompt (aporte de la IA, validación y fuente) está en la tabla de uso de IA: `docs/ia/registro-uso-ia.md`.
