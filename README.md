# Controles ISO/IEC 27001:2022 para la confidencialidad en Oracle

Proyecto del curso **Administración de Bases de Datos** — Escuela de Informática, Universidad Nacional (UNA), II Ciclo 2026.
**Estudiante:** Ismael Rojas Herrera · **Profesor:** Johnny Villalobos Murillo

El proyecto diseña, aplica y **verifica con scripts** controles del Anexo A de ISO/IEC 27001:2022, usando ISO/IEC 27002:2022 como guía, para reducir riesgos de **confidencialidad** en las tareas del DBA sobre Oracle. Todo se organiza con el ciclo PHVA (Planificar-Hacer-Verificar-Actuar).

> Es un ejercicio académico sobre un laboratorio con **datos ficticios**. No representa una certificación ISO ni una evaluación de cumplimiento de una organización real.

---

## 1. Contenido del repositorio

```
SeguridadBases/
├─ README.md                      ← este archivo
├─ artefacto/index.html           ← ARTEFACTO interactivo (abrir con doble clic)
├─ entregables/                   ← Informe PDF final
├─ sql/
│  ├─ formato.sql                 formato de columnas para las evidencias
│  ├─ 00_diagnostico/             PLANIFICAR · solo lectura
│  ├─ 10_lab_setup/               HACER · CREA objetos del laboratorio
│  ├─ 20_verificacion/            VERIFICAR · 15 controles observables (solo lectura)
│  ├─ 30_pruebas/                 VERIFICAR · batería de pruebas positivas y negativas
│  ├─ 40_actuar/                  ACTUAR · correcciones y propuestas
│  └─ 90_limpieza/                elimina el laboratorio
├─ config/sqlnet_cifrado_servidor.ora   cifrado de red exigido por el servidor
├─ herramientas/
│  ├─ ejecutar.sh                 ejecuta un .sql en el contenedor y guarda la evidencia
│  ├─ ejecutar_todo.sh            ejecuta el ciclo PHVA completo
│  ├─ aplicar_cifrado_red.sh      aplica (o revierte) el cifrado de red
│  ├─ demo.sh                     demostración en vivo (no modifica el laboratorio)
│  ├─ generar_entregables.py      genera el artefacto HTML y el informe
│  └─ plantillas/                 JS y CSS del módulo «Matriz y seguimiento»
├─ evidencias/                    salidas reales de cada script (E-xx, PR-xx, VC-xx, A-xx)
├─ docs/
│  ├─ datos/                      riesgos, tareas, controles, matriz, pruebas y datos de demostración (JSON)
│  ├─ seguimiento-evaluaciones.md guía del registro histórico, la gráfica y el respaldo de evaluaciones
│  ├─ informe/                    fragmentos del informe (marco teórico, etc.)
│  ├─ guion-video.md              guion de la demostración de 5 minutos
│  ├─ checklist-entregables.md    lista de verificación de rúbrica y evidencias
│  └─ ia/                         prompts exactos y registro de trabajo del uso de IA
├─ material-del-curso/            enunciado y fotos de la pizarra (local, NO se sube a Git)
└─ .secrets/                      contraseñas locales (NO se sube a Git)
```

## 2. Entorno

| Elemento | Valor verificado (evidencia `E-00`) |
|---|---|
| Motor | Oracle AI Database 26ai Free, Release 23.26.1.0.0 |
| Despliegue | Contenedor Docker oficial `container-registry.oracle.com/database/free` |
| Contenedor | `iso27001-oracle`, publicado solo en `127.0.0.1:1522` |
| Base de datos | CDB `FREE`, PDB de trabajo `FREEPDB1` |
| Auditoría | Unificada pura (`UNIFIED_AUDIT_TRAIL`) |

**¿Por qué 26ai Free y no "19c/21c XE"?** No existe una edición XE de 19c (las ediciones XE fueron 11gR2, 18c y 21c). Oracle reemplazó XE por la edición **Free**, que según su manual de licencias incluye TDE, Data Redaction, VPD, auditoría fina y Privilege Analysis. Los scripts son compatibles con 21c salvo donde se indica en su encabezado.

## 3. Instalación (desde cero)

Requisitos: Windows 10/11 con **Docker Desktop** y **Git Bash** (viene con Git for Windows).

```bash
# 1. Crear el contenedor (la imagen oficial pesa ~14 GB la primera vez)
mkdir -p .secrets
printf 'Iso%s_Lab26' "$(openssl rand -hex 6)" > .secrets/oracle_pwd.txt
docker run -d --name iso27001-oracle -p 127.0.0.1:1522:1521 \
  -e ORACLE_PWD="$(cat .secrets/oracle_pwd.txt)" \
  -v iso27001-oradata:/opt/oracle/oradata \
  container-registry.oracle.com/database/free:latest

# 2. Esperar a que esté "healthy" (10-15 minutos la primera vez)
docker ps --filter name=iso27001-oracle

# 3. Crear .secrets/lab_defines.sql con las contraseñas del laboratorio
#    (ver la plantilla en la sección 6)
```

## 4. Ejecución

**Todo el ciclo PHVA** (unos 6 minutos; PR-13 espera 3 minutos a propósito):

```bash
bash herramientas/ejecutar_todo.sh
```

**Un script individual** (la salida queda en `evidencias/<nombre>.txt`):

```bash
bash herramientas/ejecutar.sh <modo> <script.sql> [nombre-evidencia]
# modos: system | sysdba-pdb | sysdba-root | ninguno
bash herramientas/ejecutar.sh system sql/20_verificacion/VC-07_acceso_privilegiado.sql VC-07_acceso_privilegiado
```

**Desde SQL Developer:** conexión `SYSTEM` / host `localhost` / puerto `1522` / service name `FREEPDB1`. Abra primero `.secrets/lab_defines.sql`, cambie `srv` a `localhost:1522/FREEPDB1` y ejecútelo con F5. Después ejecute cualquier script con F5 (modo script). Los scripts con `HOST` (PR-15, VC-13, VC-15) deben correrse con `ejecutar.sh`, porque los comandos se ejecutan dentro del servidor.

**Generar el artefacto y el informe** después de una corrida:

```bash
python herramientas/generar_entregables.py
```

**Matriz y seguimiento en el artefacto:** en *Hacer y verificar → Matriz y seguimiento* se registran evaluaciones de los controles en el tiempo (madurez 0–4, estado con semáforo, evidencia y observaciones), se consultan en el historial y se comparan en una gráfica con filtro Desde/Hasta. Las evaluaciones manuales se guardan en el navegador: **exporte el JSON antes de regenerar, mover el archivo o cambiar de navegador**. Instrucciones completas en [`docs/seguimiento-evaluaciones.md`](docs/seguimiento-evaluaciones.md).

**Demostración en vivo** (no modifica el laboratorio ni las evidencias): `bash herramientas/demo.sh`

**Limpiar** el laboratorio:

```bash
bash herramientas/ejecutar.sh sysdba-pdb sql/90_limpieza/99_eliminar_laboratorio.sql E-99_limpieza
bash herramientas/aplicar_cifrado_red.sh --revertir
```

## 5. Cómo interpretar los resultados

- Cada script de `20_verificacion/` termina con una fila **RESULTADO** con valor `CUMPLE`, `PARCIAL` o `NO CUMPLE`, calculada con el criterio que indica su encabezado.
- Cada prueba de `30_pruebas/` imprime `>>> Esperado: ...` antes de la acción. En las pruebas **negativas**, el resultado correcto es **un error de Oracle** (ORA-01031, ORA-00942, ORA-28000, etc.).
- Que una prueba negativa muestre ese error significa que el control **funcionó**.
- La **madurez (0–4)** de la matriz no es lo mismo que el **estado**. La madurez mide cuán sólido y sostenido es el control; el estado dice si la evidencia satisface el criterio de la comprobación.
- Hay hallazgos **intencionales**. `APP_RIESGO` se creó mal configurada para que VC-07 la detecte (NO CUMPLE) y la fase Actuar la corrija (A-01). PR-19 muestra un riesgo residual (el DBA) que se mitiga con auditoría (A-02).

## 6. Plantilla de `.secrets/lab_defines.sql`

```sql
SET DEFINE ON
SET VERIFY OFF
DEFINE srv = localhost:1521/FREEPDB1
DEFINE pwd_system = "<la de .secrets/oracle_pwd.txt>"
DEFINE pwd_keystore = "<contraseña fuerte>"
DEFINE pwd_juan = "<...>"
DEFINE pwd_ana = "<...>"
DEFINE pwd_soporte = "<...>"
DEFINE pwd_auditor = "<...>"
DEFINE pwd_app_riesgo = "<...>"
DEFINE pwd_bloqueo = "<...>"
DEFINE pwd_idle = "<...>"
DEFINE pwd_export = "<solo letras y números>"
```

Las contraseñas de usuario deben cumplir `ORA12C_STRONG_VERIFY_FUNCTION`: 9 o más caracteres con al menos 2 mayúsculas, 2 minúsculas, 2 dígitos y 2 símbolos. `ejecutar.sh` revisa que ninguna contraseña quede escrita en las evidencias.

## 7. Uso de inteligencia artificial

El proyecto se desarrolló con apoyo de Claude Code (Anthropic). Los prompts exactos, el aporte de la IA y el estado de validación del estudiante están en `docs/ia/`. La versión oficial de la tabla de uso de IA, con el formato de la sección 8 del enunciado, la declaración jurada y los anexos A y B con los prompts 01 y 17 completos, es `entregables/Tabla_Uso_IA_Para_Firmar.pdf` (pendiente de firma). El generador no la crea ni la sobrescribe. `docs/ia/registro-uso-ia.md` queda como registro de trabajo.
