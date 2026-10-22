# Guion del video (≈ 5 minutos)

**Formato sugerido:** grabación de pantalla (OBS Studio o la Barra de juegos de Windows, `Win + Alt + R`) con tu voz. Ten abiertos de antemano el artefacto (`artefacto/index.html`), Git Bash en la carpeta del proyecto y SQL Developer conectado a `FREEPDB1`.
**Consejo:** practica una vez con cronómetro. Si pasas de 5:30, recorta el bloque 4.

| Tiempo | Qué se ve en pantalla | Qué dices (idea, no hace falta leerlo literal) |
|---|---|---|
| **0:00 – 0:30** | Portada del artefacto | «Soy Ismael Rojas Herrera. Mi proyecto aplica controles de ISO 27001:2022 para proteger la confidencialidad de una base de datos Oracle. Lo organicé con PHVA y cada control tiene una prueba que lo demuestra.» |
| **0:30 – 1:15** | Pestaña **Riesgos** del artefacto | «Identifiqué 6 riesgos de confidencialidad, de R-CONF-01 a R-CONF-06: privilegios excesivos, contraseñas débiles, copia de archivos, datos reales en desarrollo, accesos sin rastro y tráfico sin cifrar. Usé una escala de probabilidad por impacto, de 1 a 5. Muestro el riesgo inherente y el residual después de los controles.» |
| **1:15 – 1:45** | Pestaña **Controles ISO** | «Mapeé los 15 controles que pide el enunciado. Por ejemplo, A.8.3, restricción de acceso, lo implementé con VPD; A.8.11, enmascaramiento, con Data Redaction; A.8.15, registro, con auditoría unificada.» Aclara: «Uso Oracle 26ai Free porque no existe 19c XE y Free es la sucesora oficial de XE.» |
| **1:45 – 3:15** | **Demostración en vivo** en SQL Developer o Git Bash | 1) Conéctate como **JUAN** y ejecuta `SELECT vendedor, COUNT(*) FROM ventas_lab.clientes GROUP BY vendedor;` → «JUAN solo ve sus 10 clientes: es VPD.» 2) `SELECT cedula, tarjeta FROM ventas_lab.clientes WHERE ROWNUM <= 3;` → «La tarjeta sale enmascarada: Data Redaction.» 3) `DELETE FROM ventas_lab.clientes;` → «ORA-01031: no tiene permiso. Esa es una prueba negativa: el error significa que el control funciona.» 4) Conéctate como **SOPORTE_LAB** y repite la consulta → «Soporte ve todos los clientes, pero con la cédula y el correo enmascarados.» |
| **3:15 – 3:50** | Archivo `evidencias/PR-15_tde_archivos.txt` | «Si alguien copia el archivo de la base, el texto confidencial aparece en el tablespace normal, pero en el cifrado con TDE hay 0 coincidencias.» |
| **3:50 – 4:30** | Pestaña **Matriz** y `evidencias/VC-07_*` (antes y después) | «Cada control tiene un script de verificación que da CUMPLE, PARCIAL o NO CUMPLE. Dejé a propósito una cuenta con SELECT ANY TABLE: VC-07 la detectó como NO CUMPLE, la corregí en la fase Actuar y al volver a verificar dio CUMPLE. Eso es el PHVA completo.» |
| **4:30 – 5:00** | Pestaña **Matriz** (estados PARCIAL) y sección de IA | «También muestro los límites: un DBA puede alterar las reglas de VPD. Lo hice detectable con auditoría y propongo Database Vault. El perfil DEFAULT quedó PARCIAL porque cambiarlo afecta a toda la base. Usé IA y lo documenté en la tabla de uso de IA. Gracias.» |

## Antes de grabar

1. Abre Docker Desktop y verifica que el contenedor esté encendido: `docker ps --filter name=iso27001-oracle`.
2. Si quieres empezar desde cero: `bash herramientas/ejecutar_todo.sh` (≈ 6 min).
3. En SQL Developer crea las conexiones JUAN y SOPORTE_LAB (puerto `1522`, service `FREEPDB1`). Las contraseñas están en `.secrets/lab_defines.sql`. **No las muestres en el video.**
4. Cierra las ventanas que puedan mostrar contraseñas o datos personales.
