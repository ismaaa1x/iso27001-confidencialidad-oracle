# Guion del video (≈ 5 minutos): recorrido por el artefacto

El enunciado pide un «video explicativo 5 minutos» (secciones 7 y 10) sin indicar su contenido. El video recorre el artefacto (`artefacto/index.html`) siguiendo los seis puntos de la sección 6 del enunciado en el orden PHVA. Lo que va entre comillas es lo que se dice; **Haz:** es la acción en pantalla.


## Escena 1 · Presentación y Panel general (0:00 – 0:40)
**Pantalla:** **Panel general**.
**Haz:** señala con el mouse el diagrama **Ciclo PHVA** y luego los indicadores de arriba.

> «Hola, soy Ismael Rojas Herrera, del curso Administración de Bases de Datos. Este es el artefacto de mi proyecto: controles de la norma ISO/IEC 27001:2022 para proteger la confidencialidad de una base de datos Oracle. Está organizado con el ciclo PHVA, que se ve en el menú de la izquierda: Planificar, Hacer y verificar, y Actuar. Todo lo que muestra viene de pruebas reales ejecutadas en un laboratorio Oracle 26ai Free con datos ficticios. En este panel se resume el resultado: de las quince comprobaciones, trece cumplen y dos quedan en parcial.»

**Haz:** baja con la rueda hasta **Entorno verificado**.

> «Aquí está el entorno que verifiqué. Uso Oracle 26ai Free, que es la edición gratuita sucesora de Express Edition, la XE que menciona el enunciado.»

## Escena 2 · Planificar: riesgos (0:40 – 1:25)
**Haz:** menú izquierdo → **Riesgos**. Señala el **mapa de calor**; luego baja a la tabla.

> «En Planificar identifiqué seis riesgos de confidencialidad, del R-CONF-01 al R-CONF-06: abuso de privilegios, suplantación de identidad, copia no autorizada de archivos, exposición de datos a personal no autorizado, fuga no detectada y la interceptación en la red. Cada riesgo tiene su activo, la amenaza, un escenario concreto y su valoración de probabilidad por impacto, de 1 a 5.»

**Haz:** en la tabla, señala la fila **R-CONF-01** y sus columnas P, I e Inherente.

> «Por ejemplo, el abuso de privilegios: una cuenta de aplicación con SELECT ANY TABLE podría extraer todos los clientes. Empezó con probabilidad 4 e impacto 5. Con los controles, la probabilidad bajó a 2; el impacto se mantiene porque los datos siguen siendo igual de sensibles.»

## Escena 3 · Planificar: tareas del DBA y controles ISO (1:25 – 2:15)
**Haz:** menú izquierdo → **Tareas DBA**. Baja despacio por la tabla.

> «Luego mapeé quince tareas críticas del DBA: gestión de usuarios, privilegios, autenticación, cifrado, enmascaramiento, respaldos, auditoría y otras. Para cada una indico cómo se implementa en Oracle, si se pudo demostrar en este entorno y con qué script se prueba.»

**Haz:** menú izquierdo → **Controles ISO**. Señala la columna **Implementación en Oracle** y luego **Evidencia observable**.

> «Aquí están los quince controles ISO del enunciado, con su pertinencia para la confidencialidad, los riesgos y tareas que cubren, la implementación en Oracle y la evidencia observable. Por ejemplo: A.8.3, restricción de acceso, lo implementé con VPD, que filtra las filas según el usuario; A.8.11, enmascaramiento, con Data Redaction; A.8.12, prevención de fuga, con cifrado TDE; y A.8.15, registro, con auditoría unificada. También anoto las limitaciones de cada uno.»

## Escena 4 · Verificar: controles observables (2:15 – 2:50)
**Haz:** menú izquierdo → **Observables**. En el buscador de la tabla escribe `VC-07`. Haz clic en el enlace de la columna **Resultado registrado** o de evidencia para abrir el visor.

> «Para que un auditor externo pueda comprobar los controles, definí quince comprobaciones observables, de VC-01 a VC-15. Cada una es un script SQL con un criterio de aceptación y da Cumple, Parcial o No cumple. Al hacer clic se abre la salida real del script. Este es VC-07: busca cuentas que no son administrativas y tienen privilegios amplios.»

**Haz:** **Cerrar** el visor y borra el texto del buscador.

## Escena 5 · Verificar: matriz y seguimiento (2:50 – 3:55)
**Haz:** menú izquierdo → **Matriz y seguimiento** → pestaña **A. Resumen por control**. Señala las columnas Tarea, Riesgo, Control, Criterio 0–4, Evidencia y Estado.

> «Esta es la matriz de evaluación que pide el enunciado: tarea, riesgo, control, criterio de madurez de 0 a 4, evidencia y estado con semáforo. Además agregué la fecha, la madurez y la variación, para hacer seguimiento.»

**Haz:** pestaña **B. Historial** → en el filtro **Control** elige **A.8.2**.

> «En el historial se ven todas las evaluaciones de un control. En A.8.2 dejé a propósito una cuenta, APP_RIESGO, con SELECT ANY TABLE. El script VC-07 la detectó y dio No cumple, en rojo. En la fase Actuar le quité el privilegio, volví a verificar y dio Cumple, en verde. La última fila es mi evaluación de hoy; está marcada como Manual para no confundirla con una ejecución automática del script.»

**Haz:** pestaña **C. Evolución (gráfica)** → elige **A.8.2** → **Agregar a la gráfica** → elige **A.8.20** → **Agregar a la gráfica** → pasa el mouse sobre el último punto de A.8.2.

> «Y aquí la evolución en el tiempo, lo que en clase vimos como E de i, t: la evaluación del control i en el momento t. Puedo agregar varios controles a la misma gráfica y filtrar por fechas con Desde y Hasta. El color de la línea identifica el control y el semáforo indica el estado de cada evaluación. Los puntos son evaluaciones reales; la línea solo los une, no inventa valores en medio.»

## Escena 6 · Batería de pruebas (3:55 – 4:30)
**Haz:** menú izquierdo → **Pruebas**. Señala las columnas ID, Tipo, Procedimiento, Resultado esperado y Herramienta. En el buscador escribe `PR-05` y abre su evidencia.

> «La batería tiene diecinueve pruebas, con su tipo, procedimiento, resultado esperado, herramienta y el resultado obtenido; las diecinueve dieron lo esperado. Hay pruebas positivas y negativas. Esta es negativa: el vendedor JUAN intenta borrar clientes y Oracle lo rechaza con ORA-41900, falta de privilegio. Que dé error significa que el mínimo privilegio funciona.»

**Haz:** **Cerrar**, borra el buscador, escribe `PR-15` y abre su evidencia.

> «Y esta prueba busca un texto directamente en los archivos de datos: en el tablespace sin cifrar aparece; en el cifrado con TDE hay cero coincidencias. Si alguien copia el archivo, no puede leer los datos.»

**Haz:** **Cerrar** el visor.

## Escena 7 · Actuar y cierre (4:30 – 5:00)
**Haz:** menú izquierdo → **Actuar**. Señala **Hallazgos y correcciones aplicadas** y luego **Propuestas no ejecutadas**.

> «En Actuar están las correcciones que apliqué, como la de APP_RIESGO, y lo que queda como riesgo residual: el cifrado y los respaldos todavía tienen vías sin cubrir, por eso esos dos controles quedaron en parcial, y un DBA puede alterar las reglas de VPD; lo hice detectable con auditoría y propongo Database Vault. El artefacto también incluye el marco teórico, las referencias en APA 7 y las cincuenta y cuatro evidencias. Los scripts están en el repositorio. Gracias.»

**Haz:** espera 2 segundos en silencio y detén la grabación.
