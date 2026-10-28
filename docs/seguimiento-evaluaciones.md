# Matriz y seguimiento de evaluaciones: guía de uso

Esta guía describe el módulo **«Matriz y seguimiento»** del artefacto (`artefacto/index.html`, menú *Hacer y verificar → Matriz y seguimiento*). El módulo responde a la reunión con el profesor del 28/10/2026: en la pizarra se planteó `E(i,t)`, la evaluación del control *i* en el tiempo *t*, con varios controles en la misma gráfica y un semáforo rojo, amarillo y verde.

## 1. Qué datos usa

Hay tres conjuntos que **nunca se mezclan**:

| Conjunto | De dónde sale | Se puede editar | Se ve en |
|---|---|---|---|
| **Base · evidencia** | El generador los crea desde los archivos reales de `evidencias/` (scripts VC). | No: se corrigen en la fuente y se regenera | «Resultados reales» |
| **Manual** | Lo que se registra con el formulario del artefacto. | Sí, con revisiones | «Resultados reales» |
| **Demostración** | `docs/datos/seguimiento_demo.json`: datos ficticios para mostrar la evolución. | No | Solo «Demostración» |

### Datos base reales: qué se pudo recuperar

- Todas las pruebas se ejecutaron en una sola jornada: el **21/10/2026, entre las 23:15 y las 23:48** (hora de Costa Rica). El artefacto conserva esa realidad: no reparte resultados en días distintos.
- Hay **17 evaluaciones base**:
  - una final por cada uno de los 15 controles;
  - dos ejecuciones anteriores a una corrección: **VC-07** (NO CUMPLE, antes de A-01) y **VC-14** (CUMPLE, antes de A-02).
- **Estado:** en las finales es el de la matriz. Para A.8.12 y A.8.13 la matriz asigna «Parcial» aunque el script dio CUMPLE; el motivo se muestra en las observaciones y el resultado del script aparece en la columna «Origen».
- **Madurez:**
  - En las finales se toma de `docs/datos/matriz.json`.
  - En las dos ejecuciones «antes» queda **«No asignada»**, porque nadie evaluó la madurez en ese momento. Esos puntos aparecen en el historial pero no en la gráfica.
- **Tres fechas distintas que no se confunden:**
  - **Ejecución de la prueba:** viene del encabezado de cada evidencia.
  - **Evaluación:** la fecha del registro. En los datos base coincide con la ejecución del script.
  - **Generación del artefacto:** se muestra en la barra superior y en la nota del módulo.

## 2. Registrar una evaluación

1. Entre a **Matriz y seguimiento** y deje seleccionado «Resultados reales». En «Demostración» el botón está desactivado.
2. Presione **«+ Registrar evaluación»**.
3. Complete el formulario. Los campos con * son obligatorios:
   - **Control:** al elegirlo se muestran sus criterios de madurez del 0 al 4 como guía.
   - **Fecha de evaluación:** no puede ser posterior a hoy. **Hora:** opcional, en hora de Costa Rica.
   - **Madurez:** del 0 al 4.
   - **Estado:** Cumple, Parcial o No cumple. **No se calcula a partir de la madurez:** se elige según el criterio del control y su evidencia.
   - **Evidencia o referencia:** por ejemplo, «VC-07 en SQL Developer, captura 03».
   - **Observaciones y justificación.**
   - **Responsable:** opcional.
4. **Guardar.** La evaluación se **agrega**; nunca sustituye las anteriores. Queda marcada como **Manual**, para que no se confunda con una ejecución automática en Oracle.

Si hay varias evaluaciones del mismo control en el mismo día, se ordenan por hora y, si no tienen hora, por el momento en que se registraron. La columna «N.º» del historial indica el orden dentro del día (#1, #2…).

## 3. Corregir un error de captura

1. Vaya a **B. Historial**, busque la evaluación manual y presione **«Corregir»**.
2. Cambie lo necesario y escriba el **motivo de la corrección**, que es obligatorio.
3. Se guarda una **revisión** con el valor anterior, el valor nuevo, la fecha del cambio y el motivo. Para consultarla, use el botón **«Revisiones (n)»**.

Este historial de revisiones vive en el navegador y sirve para rastrear correcciones. **No es un registro de auditoría inviolable:** quien controle el equipo puede borrarlo.

## 4. Las tres vistas

- **A. Resumen por control (la matriz):**
  - Conserva los campos del enunciado: Tarea | Riesgo | Control | Criterio 0–4 | Evidencia | Estado.
  - Agrega fecha, madurez, variación respecto a la evaluación anterior dentro del período, observaciones y acceso al historial.
  - Muestra la **última evaluación dentro del período**. Un control sin registros en el período aparece como **«Sin evaluación en el período»** (gris), sin arrastrar un resultado anterior y sin contarlo como madurez 0.
- **B. Historial:** todas las evaluaciones, filtrables por período, control y estado.
- **C. Evolución (gráfica):**
  - Elija un control y presione **«Agregar a la gráfica»**; repita para comparar más (hasta 8 a la vez).
  - **«Quitar»** solo lo saca de la gráfica: sus datos se conservan.
  - **Color de la línea** = control (cada uno mantiene su color mientras esté en la gráfica). **Semáforo** = estado de cada evaluación (✓ verde Cumple, ! amarillo Parcial, ✕ rojo No cumple, gris pendiente), que aparece al señalar un punto o al seleccionarlo con el teclado (Tab y Enter).
  - Eje horizontal proporcional al tiempo; eje vertical de madurez del 0 al 4. Cada punto es una evaluación real. Los segmentos solo unen observaciones puntuales: no hay valores intermedios ni curvas suavizadas.
  - La tabla **«Tendencia por control»** compara la última evaluación con la anterior: ▲ Mejora, ▼ Deterioro o ● Estable. Con una sola evaluación indica que no hay información suficiente.

## 5. Filtrar por fechas

- **Desde** y **Hasta** se aplican a la vez a la matriz, al historial, a la gráfica y a los indicadores, que usan los mismos registros.
- Los límites son **inclusivos**: Desde = Hasta = 01/09/2026 muestra todo lo de ese día.
- Si Desde es posterior a Hasta, aparece un error y no se muestran datos.
- **«Restablecer filtros»** limpia fechas y filtros y vuelve a la selección inicial de la gráfica.
- **«Ver historial completo»** quita el período y abre el historial.
- Las fechas se guardan como texto (AAAA-MM-DD y HH:MM, hora de Costa Rica) y nunca se convierten a UTC, así que no se corren de día.

**Indicadores:** se calculan con la última evaluación de cada control en el período. El porcentaje de «Cumple» y la madurez promedio **excluyen** los controles sin evaluación, y el promedio también excluye las evaluaciones con madurez no asignada. El texto bajo los indicadores dice cuántos quedaron fuera.

## 6. Guardar, exportar, importar y conservar los datos

- **Guardado:**
  - Las evaluaciones manuales y sus revisiones se guardan automáticamente en el **almacenamiento local del navegador** (`localStorage`).
  - Dependen de **ese navegador en ese equipo**: si abre el artefacto en otro navegador o en otra computadora, no aparecen.
  - Si el navegador no permite guardar, el artefacto lo avisa en rojo.
- **Exportar JSON:** descarga un archivo `evaluaciones-iso27001-AAAAMMDDHHMM.json` con las evaluaciones manuales y sus revisiones. No incluye los datos base ni los de demostración, porque esos ya vienen en el HTML.
- **Importar JSON:**
  - Valida el formato, la versión y cada registro (control existente, fechas, madurez de 0 a 4, estado permitido).
  - Antes de aplicar muestra un resumen: nuevos, duplicados y conflictos.
  - **Nunca reemplaza:** un registro con el mismo identificador y el mismo contenido se omite como duplicado; uno con el mismo identificador y otro contenido se reporta como conflicto y se conserva el local.

### Procedimiento de respaldo y migración

1. **Antes** de regenerar el artefacto, moverlo de carpeta, cambiar de navegador o de computadora, o borrar los datos del navegador, presione **«Exportar JSON»** y guarde el archivo junto al proyecto, por ejemplo en `respaldos/`. Esa carpeta no se sube a Git.
2. Regenere con `python herramientas/generar_entregables.py`. En las pruebas, al regenerar en la misma ruta y con el mismo navegador, los datos siguieron ahí, porque la clave de almacenamiento es fija.
3. Abra el artefacto y revise que la nota «Guardado en este navegador: N evaluaciones…» muestre la cantidad esperada.
4. Si no aparecen (otro navegador, otro equipo o datos borrados), presione **«Importar JSON»** y elija el respaldo. Al importar dos veces no se duplica nada.

## 7. Limitaciones

- Los datos reales solo tienen **una jornada** (21/10/2026). Para que la evolución sea real hace falta volver a evaluar los controles en otras fechas: ejecutando los VC y registrando el resultado, o registrando evaluaciones manuales con evidencia.
- La persistencia depende del navegador. No hay servidor ni base de datos compartida, así que cada persona ve sus propias evaluaciones, salvo que se intercambien por JSON.
- Las revisiones no son un registro de auditoría inviolable.
- Los datos de demostración son ficticios. Si se presentan, hay que decirlo; el artefacto los marca en todas las vistas.
- La gráfica admite hasta 8 controles a la vez, para que los colores se distingan.
