"""
generar_entregables.py - Genera el artefacto interactivo y el informe a partir de:
  * docs/datos/*.json          (riesgos, tareas, controles, pruebas, matriz)
  * docs/informe/*.html        (marco teórico)
  * evidencias/*.txt           (salidas REALES de los scripts)

Los resultados de los controles observables (CUMPLE/PARCIAL/NO CUMPLE) se leen
de las evidencias, y cada prueba se marca como "Coincide" solo si su evidencia
contiene los patrones esperados. Nada se marca como cumplido a mano: si falta
una evidencia, el estado queda "Pendiente de evaluación".

Uso:  python herramientas/generar_entregables.py
Salida: artefacto/index.html, docs/informe/informe.html y, si encuentra
        Microsoft Edge, entregables/Informe-ISO27001-Confidencialidad-Oracle.pdf
"""
import html
import json
import re
import subprocess
import tempfile
import sys
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DATOS = RAIZ / "docs" / "datos"
EVID = RAIZ / "evidencias"


def cargar(nombre):
    return json.loads((DATOS / nombre).read_text(encoding="utf-8"))


P = cargar("proyecto.json")
T = cargar("pruebas.json")
M = cargar("matriz.json")
MARCO = (RAIZ / "docs" / "informe" / "marco_teorico.html").read_text(encoding="utf-8")
e = html.escape


# ---------------------------------------------------------------- evidencias
def leer_evidencia(nombre):
    ruta = EVID / f"{nombre}.txt"
    return ruta.read_text(encoding="utf-8", errors="replace") if ruta.exists() else None


def resultado_vc(nombre):
    texto = leer_evidencia(nombre)
    if texto is None:
        return None
    seccion = texto.split("=== Resultado", 1)[-1]
    hallados = re.findall(r"(NO CUMPLE|CUMPLE|PARCIAL)\s*$", seccion, flags=re.M)
    return hallados[-1] if hallados else None


def verificar_prueba(evidencia, patrones, ausentes=()):
    texto = leer_evidencia(evidencia)
    if texto is None:
        return "Pendiente de evaluación", ["sin evidencia"]
    faltan = [p for p in patrones if not re.search(p, texto, flags=re.M)]
    sobran = [p for p in ausentes if re.search(p, texto, flags=re.M)]
    if not faltan and not sobran:
        return "Coincide", []
    return "No coincide", faltan + [f"no debía aparecer: {p}" for p in sobran]


ESTADO_VC = {"CUMPLE": "Cumple", "PARCIAL": "Parcial", "NO CUMPLE": "No cumple", None: "Pendiente de evaluación"}

for o in T["observables"]:
    o["resultados"] = [(ev, resultado_vc(ev)) for ev in o["evidencia"] if ev.startswith("VC-")]
    final = o["resultados"][-1][1] if o["resultados"] else None
    o["estado"] = ESTADO_VC[final]

for t in T["pruebas"]:
    t["obtenido"], t["faltan"] = verificar_prueba(t["evidencia"], t["patrones"], t.get("ausentes", []))
    if "evidencia_extra" in t:
        estado2, faltan2 = verificar_prueba(t["evidencia_extra"], t["patrones_extra"])
        if estado2 != "Coincide":
            t["obtenido"], t["faltan"] = estado2, t["faltan"] + faltan2

obs_por_control = {o["control"]: o for o in T["observables"]}
for f in M["filas"]:
    o = obs_por_control[f["control"]]
    f["estado_final"] = f.get("estado") or o["estado"]
    f["resultado_vc"] = " → ".join(f"{ev}: {r or 'sin evidencia'}" for ev, r in o["resultados"])

for r in P["riesgos"]:
    r["inh"] = r["p"] * r["i"]
    r["res"] = r["p_res"] * r["i_res"]


def nivel(v):
    return "Crítico" if v >= 16 else "Alto" if v >= 10 else "Medio" if v >= 5 else "Bajo"


def chip(texto, clase=None):
    clase = clase or {"Cumple": "ok", "Coincide": "ok", "Sí": "ok", "Parcial": "warn", "No cumple": "bad",
                      "No coincide": "bad", "Pendiente de evaluación": "pend", "Crítico": "bad", "Alto": "warn",
                      "Medio": "pend", "Bajo": "ok"}.get(texto, "pend")
    return f'<span class="chip {clase}">{e(texto)}</span>'


evidencias_todas = sorted(p.stem for p in EVID.glob("*.txt"))

# ---------------------------------------------------------------- tablas
def tabla(cabeceras, filas, id_=None, filtrable=True):
    th = "".join(f"<th>{e(c)}</th>" for c in cabeceras)
    cuerpo = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in fila) + "</tr>" for fila in filas)
    attr = f' id="{id_}"' if id_ else ""
    cls = ' class="filtrable"' if filtrable else ""
    return f'<div class="tabla"><table{attr}{cls}><thead><tr>{th}</tr></thead><tbody>{cuerpo}</tbody></table></div>'


def ev_link(nombre, artefacto):
    if not (EVID / f"{nombre}.txt").exists():
        return f"<code>{e(nombre)}</code> (pendiente)"
    if artefacto:
        return f'<a href="#ev-{e(nombre)}" class="evlink" data-ev="{e(nombre)}">{e(nombre)}</a>'
    return f"<code>evidencias/{e(nombre)}.txt</code>"


def seccion_riesgos():
    esc_p = tabla(["Valor", "Probabilidad (P)", "Impacto (I)"],
                  [[e(p[0]), e(p[1]), e(i[1])] for p, i in zip(P["escala"]["probabilidad"], P["escala"]["impacto"])],
                  filtrable=False)
    filas = [[f"<strong>{e(r['id'])}</strong>", e(r["activo"]),
              f"<strong>Amenaza:</strong> {e(r['amenaza'])}<br><strong>Vulnerabilidad:</strong> {e(r['vulnerabilidad'])}",
              e(r["escenario"]), str(r["p"]), str(r["i"]),
              f"{r['inh']} {chip(nivel(r['inh']))}", e(r["justificacion"]), e(", ".join(r["controles"])),
              f"{r['p_res']}×{r['i_res']} = {r['res']} {chip(nivel(r['res']))}<br><small>{e(r['justificacion_res'])}</small>"]
             for r in P["riesgos"]]
    return (f"<p>{e(P['escala']['niveles'])}</p>{esc_p}" +
            tabla(["ID", "Activo", "Amenaza / vulnerabilidad", "Escenario", "P", "I", "Inherente", "Justificación",
                   "Controles", "Residual (tras verificar)"], filas, "t-riesgos"))


def seccion_tareas():
    filas = [[f"<strong>{e(t['id'])}</strong>", e(t["tarea"]), e(t["implementacion"]),
              chip(t["demostrable"], "ok" if t["demostrable"] == "Sí" else "warn") +
              (f"<br><small>{e(t['limitacion'])}</small>" if t.get("limitacion") else ""),
              f"<code>{e(t['scripts'])}</code>"] for t in P["tareas"]]
    return tabla(["ID", "Tarea crítica del DBA", "Implementación en Oracle", "¿Demostrable en este entorno?",
                  "Scripts / pruebas"], filas, "t-tareas")


def seccion_controles():
    filas = [[f"<strong>{e(c['id'])}</strong>", e(c["titulo"]), e(c["tema"]), e(c["pertinencia"]),
              e(", ".join(c["riesgos"])), e(", ".join(c["tareas"])), e(c["implementacion"]),
              f"<code>{e(c['evidencia'])}</code>", e(c["limitacion"])] for c in P["controles"]]
    return tabla(["Control", "Título (traducción propia)", "Tema", "Pertinencia para la confidencialidad", "Riesgos",
                  "Tareas", "Implementación en Oracle", "Evidencia observable", "Limitaciones"], filas, "t-controles")


def seccion_observables(artefacto):
    filas = []
    for o in T["observables"]:
        res = "<br>".join(f"{ev_link(ev, artefacto)}: {chip(ESTADO_VC[r])}" for ev, r in o["resultados"])
        extras = [ev for ev in o["evidencia"] if not ev.startswith("VC-")]
        if extras:
            res += "<br>" + ", ".join(ev_link(ev, artefacto) for ev in extras)
        filas.append([f"<strong>{e(o['id'])}</strong>", e(o["control"]), e(o["comprobacion"]), e(o["tecnica"]),
                      e(o["criterio"]), res])
    return tabla(["ID", "Control ISO", "Comprobación observable", "Técnica / vista", "Criterio de aceptación",
                  "Resultado registrado"], filas, "t-observables")


def seccion_matriz(artefacto):
    esc = tabla(["Nivel", "Nombre", "Significado"], [[e(a), e(b), e(c)] for a, b, c in M["escala_madurez"]],
                filtrable=False)
    filas = []
    for f in M["filas"]:
        actual = ' class="actual"'
        crit = "".join(f"<li{actual if i == f['nivel'] else ''}><strong>{i}</strong> {e(c)}</li>"
                       for i, c in enumerate(f["criterios"]))
        est = chip(f["estado_final"]) + (f"<br><small>{e(f['motivo_estado'])}</small>" if f.get("motivo_estado") else "")
        filas.append([e(f["tarea"]), e(f["riesgo"]), f"<strong>{e(f['control'])}</strong>",
                      f'<ol class="crit" start="0">{crit}</ol>',
                      f'<span class="nivel">{f["nivel"]}</span><br><small>{e(f["justificacion"])}</small>',
                      f"<code>{e(f['evidencia'])}</code><br><small>{e(f['resultado_vc'])}</small>", est])
    return (f"<p>{e(M['nota'])}</p>{esc}" +
            tabla(["Tarea", "Riesgo", "Control", "Criterios 0–4 (el resaltado es el nivel alcanzado)",
                   "Madurez asignada", "Evidencia", "Estado"], filas, "t-matriz"))


def seccion_pruebas(artefacto):
    filas = []
    for t in T["pruebas"]:
        ev = ev_link(t["evidencia"], artefacto)
        if "evidencia_extra" in t:
            ev += "<br>" + ev_link(t["evidencia_extra"], artefacto)
        obt = chip(t["obtenido"]) + ("<br><small>Faltó: " + e("; ".join(t["faltan"])) + "</small>" if t["faltan"] else "")
        filas.append([f"<strong>{e(t['id'])}</strong>", e(t["tipo"]), e(t["control"]), e(t["usuario"]),
                      e(t["procedimiento"]), e(t["esperado"]), e(t["herramienta"]), obt, ev])
    return tabla(["ID", "Tipo", "Control", "Usuario / privilegios", "Procedimiento", "Resultado esperado",
                  "Herramienta", "Resultado obtenido", "Evidencia"], filas, "t-pruebas")


REFERENCIAS = [
    "Asamblea Legislativa de la República de Costa Rica. (2011). <em>Ley n.º 8968: Protección de la persona frente al tratamiento de sus datos personales</em>. Sistema Costarricense de Información Jurídica. https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?param1=NRTC&amp;nValor1=1&amp;nValor2=70975&amp;nValor3=85989&amp;strTipM=TC",
    "Hall, T. (2025, 15 de octubre). <em>Oracle AI Database 26ai released</em>. ORACLE-BASE. https://oracle-base.com/blog/2025/10/15/oracle-ai-database-26ai-released/",
    "International Organization for Standardization & International Electrotechnical Commission. (2022a). <em>Information security, cybersecurity and privacy protection — Information security management systems — Requirements</em> (ISO/IEC Standard No. 27001:2022). https://www.iso.org/standard/27001 [Texto completo no consultado: norma de pago]",
    "International Organization for Standardization & International Electrotechnical Commission. (2022b). <em>Information security, cybersecurity and privacy protection — Information security controls</em> (ISO/IEC Standard No. 27002:2022). https://www.iso.org/standard/75652.html [Texto completo no consultado: norma de pago]",
    "Open Security Architecture. (s. f.). <em>ISO/IEC 27002:2022</em> [Fuente secundaria para los títulos de los controles]. https://www.opensecurityarchitecture.org/frameworks/iso-27002-2022",
    "Oracle. (s. f.-a). <em>Database licensing information user manual 21c</em>. https://docs.oracle.com/en/database/oracle/oracle-database/21/dblic/Licensing-Information.html",
    "Oracle. (s. f.-b). <em>Database Express Edition installation guide 21c for Linux x86-64: Licensing restrictions</em>. https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinl/licensing-restrictions.html",
    "Oracle. (s. f.-c). <em>Database security guide 21c: Introduction to auditing</em>. https://docs.oracle.com/en/database/oracle/oracle-database/21/dbseg/introduction-to-auditing.html",
    "Oracle. (s. f.-d). <em>Oracle AI Database 26ai: Changes, desupports, and deprecations</em>. https://docs.oracle.com/en/database/oracle/oracle-database/26/upgrd/oracle-database-changes-deprecations-desupports.html",
    "Oracle. (s. f.-e). <em>Oracle AI Database security guide 26ai: Securing data for Oracle AI Database connections</em>. https://docs.oracle.com/en/database/oracle/oracle-database/26/dbseg/nne-vs-tls.html",
    "Oracle. (2026). <em>Oracle AI Database licensing information user manual 26ai</em>. https://docs.oracle.com/en/database/oracle/oracle-database/26/dblic/Licensing-Information.html",
    "Poder Ejecutivo de la República de Costa Rica. (2013). <em>Decreto Ejecutivo n.º 37554-JP: Reglamento a la Ley de Protección de la Persona frente al Tratamiento de sus Datos Personales</em>. Sistema Costarricense de Información Jurídica. https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?param1=NRTC&amp;nValor1=1&amp;nValor2=74352&amp;nValor3=106487&amp;strTipM=TC",
    "Rose, S., Borchert, O., Mitchell, S., &amp; Connelly, S. (2020). <em>Zero trust architecture</em> (NIST Special Publication 800-207). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-207",
]


def seccion_referencias():
    return '<ol class="refs">' + "".join(f"<li>{r}</li>" for r in REFERENCIAS) + "</ol>"


def seccion_ia():
    # Formato de la sección 8 del enunciado: 5 columnas y la declaración jurada inmediatamente debajo.
    texto = (RAIZ / "docs" / "ia" / "registro-uso-ia.md").read_text(encoding="utf-8")
    filas = []
    for linea in texto.splitlines():
        if linea.startswith("| Claude Code"):
            celdas = [c.strip() for c in linea.strip().strip("|").split(" | ")]
            filas.append([re.sub(r"`([^`]+)`", r"<code>\1</code>", e(c)) for c in celdas])
    return (tabla(["Herramienta IA", "Prompt exacto utilizado", "Aporte de la IA",
                   "Validación / Corrección del estudiante", "Fuente verificada"], filas, "t-ia", filtrable=False) +
            "<p><small>El prompt 01 completo está en <code>docs/ia/prompt-01-analisis-inicial.md</code>.</small></p>"
            "<p><strong>Declaración Jurada:</strong></p><p>Yo, <strong>Ismael Rojas Herrera</strong>, declaro que todo contenido generado "
            "con IA ha sido declarado en la tabla anterior, validado contra fuentes oficiales (ISO, documentación del motor "
            "de BD) y que asumo responsabilidad por su veracidad. Entiendo que omitir esta declaración constituye falta grave.</p>"
            "<p class='firma'>Firma: ______________________________ &nbsp;&nbsp; Carné: ____________________ &nbsp;&nbsp; Fecha: ________________</p>")


def tabla_ia_firmada():
    # Entregable 5 («Tabla de uso de IA firmada») como documento aparte para imprimir y firmar.
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tabla de uso de IA</title><style>:root{{color-scheme:light}}{CSS.split('@media (prefers-color-scheme:dark)')[0]}{CSS[CSS.index('*{box-sizing'):]}{CSS_INF}
.firma{{margin-top:36px}}#t-ia th:nth-child(1){{width:11%}}#t-ia th:nth-child(2){{width:27%}}#t-ia th:nth-child(3){{width:24%}}#t-ia th:nth-child(4){{width:23%}}#t-ia th:nth-child(5){{width:15%}}#t-ia{{table-layout:fixed}}#t-ia td:first-child{{white-space:normal}}</style></head><body><main>
<p>Universidad Nacional de Costa Rica · Escuela de Informática · {e(P['meta']['curso'])} · {e(P['meta']['ciclo'])}<br>
Profesor: {e(P['meta']['profesor'])} · Estudiante: <strong>{e(P['meta']['estudiante'])}</strong></p>
<h2 class="nobreak">Tabla de uso de IA</h2><p>{e(P['meta']['titulo'])}</p>{seccion_ia()}</main></body></html>"""


ACTUAR = """
<h3>Hallazgos y correcciones aplicadas</h3>
<ul>
<li><strong>VC-07 (A.8.2):</strong> la cuenta <code>APP_RIESGO</code> tenía <code>SELECT ANY TABLE</code> → NO CUMPLE. En PR-10, VPD le devolvió 0 filas de CLIENTES (defensa en profundidad), pero pudo leer la copia DEV y la tabla de reglas de seguridad. <strong>A-01:</strong> se revocó el privilegio y se bloqueó la cuenta. VC-07 se volvió a ejecutar → CUMPLE.</li>
<li><strong>PR-19 (A.8.2, A.8.15):</strong> un DBA (SYSTEM) se agregó a la tabla de reglas de VPD y vio los 20 clientes con la tarjeta completa, porque el rol DBA hereda EXEMPT REDACTION POLICY. El INSERT no quedaba auditado. <strong>A-02:</strong> se creó la política <code>POL_CONF_CAMBIOS_REGLAS</code>; al repetir PR-19 el cambio queda registrado. El riesgo se DETECTA, no se IMPIDE.</li>
<li><strong>PR-16 (A.8.12, A.8.13):</strong> un export de Data Pump guarda en claro los datos de tablas TDE (ORA-39173) y Oracle Free no permite cifrar exports (ORA-00439). Se configuró RMAN para cifrar todos los respaldos físicos (E-11, VC-13). Para exports se documenta el cifrado con openssl como alternativa, que ofrece una protección distinta porque la clave queda fuera de Oracle.</li>
<li><strong>VC-01 (A.5.12):</strong> en la primera ejecución detectó 4 columnas de VENTAS sin clasificar; se corrigió el script 04 y la verificación pasó a CUMPLE.</li>
</ul>
<h3>Propuestas no ejecutadas (riesgo residual)</h3>
<p>Están documentadas, con las sentencias comentadas, en <code>sql/40_actuar/A-03_propuestas_no_ejecutadas.sql</code>:</p>
<ul>
<li><strong>P-01:</strong> endurecer el perfil DEFAULT, que es una política global de la base.</li>
<li><strong>P-02:</strong> Database Vault. Está incluido en Free, pero en este motor figura deshabilitado (<code>V$OPTION</code> = FALSE).</li>
<li><strong>P-03:</strong> TLS con certificados.</li>
<li><strong>P-04:</strong> guardar el keystore en un HSM o en Oracle Key Vault (OKV).</li>
<li><strong>P-05:</strong> enviar la auditoría a un SIEM.</li>
<li><strong>P-06:</strong> cuenta de respaldo dedicada.</li>
<li><strong>P-07:</strong> aplicar el último Release Update.</li>
</ul>
"""

LIMITACIONES = """
<ul>
<li>Es un laboratorio con datos ficticios en un contenedor local, no una organización real. Las valoraciones de riesgo se basan en un escenario construido y no en mediciones.</li>
<li>Aplicar estos controles no equivale a cumplir ISO/IEC 27001 ni a estar certificado: no se implementó un SGSI (alcance, políticas, declaración de aplicabilidad, auditorías internas).</li>
<li>No se tuvo acceso al texto completo de ISO/IEC 27001/27002. Los títulos de los controles provienen de una fuente secundaria, y las traducciones al español son propias.</li>
<li>Se usó Oracle AI Database 26ai Free en lugar de «19c/21c XE»: no existe 19c XE y Free es la sucesora de XE. Algunas salidas cambian respecto de 21c: por ejemplo, ORA-41900 en lugar de ORA-01031, y en 26ai solo existe la auditoría unificada.</li>
<li>Los redo logs, los archived logs y LogMiner registran cambios, no consultas SELECT. Por eso no se usan como evidencia de lectura de datos confidenciales.</li>
<li>No hay SIEM, HSM, TLS con certificados ni MFA. Son mejoras propuestas (fase Actuar).</li>
</ul>
"""

ENTORNO = f"""
<table class="mini"><tbody>
<tr><th>Motor</th><td>{e(P['meta']['motor'])}</td></tr>
<tr><th>Auditoría</th><td>Unificada pura (<code>UNIFIED_AUDIT_TRAIL</code>; <code>audit_trail = NONE</code>), por lo que <code>SYS.AUD$</code> no aplica</td></tr>
<tr><th>Opciones verificadas</th><td>V$OPTION: TDE, Backup Encryption, Data Redaction, FGAC (VPD), FGA, Privilege Analysis y Unified Auditing = TRUE; Database Vault y Label Security = FALSE</td></tr>
<tr><th>Red</th><td>Puerto 1521 del contenedor publicado solo en 127.0.0.1:1522; cifrado nativo AES256/SHA256 obligatorio</td></tr>
<tr><th>Herramientas</th><td>SQL*Plus, RMAN y Data Pump dentro del contenedor; SQL Developer para las capturas; Git Bash para los scripts</td></tr>
</tbody></table>
"""

PHVA = """
<table class="mini"><thead><tr><th>Fase</th><th>Qué se hizo</th><th>Scripts</th></tr></thead><tbody>
<tr><td><strong>Planificar</strong></td><td>Diagnóstico del entorno, escala de riesgo, riesgos, tareas, selección y mapeo de controles</td><td><code>sql/00_diagnostico</code>, este informe</td></tr>
<tr><td><strong>Hacer</strong></td><td>Keystore TDE, tablespace cifrado, esquema ficticio, usuarios/roles/perfiles, clasificación, VPD, Redaction, auditoría, retención, copia DEV enmascarada, RMAN cifrado, cifrado de red</td><td><code>sql/10_lab_setup</code>, <code>herramientas/aplicar_cifrado_red.sh</code></td></tr>
<tr><td><strong>Verificar</strong></td><td>19 pruebas positivas y negativas; 15 comprobaciones observables con resultado calculado</td><td><code>sql/30_pruebas</code>, <code>sql/20_verificacion</code></td></tr>
<tr><td><strong>Actuar</strong></td><td>Corrección de hallazgos (A-01, A-02), re-verificación, riesgo residual y propuestas</td><td><code>sql/40_actuar</code></td></tr>
</tbody></table>
"""

NORMAS = """
<p><strong>ISO/IEC 27001:2022</strong> define los requisitos certificables de un SGSI (cláusulas 4 a 10). Su <strong>Anexo A</strong> es un catálogo de 93 controles de referencia, de los que la organización selecciona los aplicables y lo declara en la Declaración de Aplicabilidad. <strong>ISO/IEC 27002:2022</strong> no es certificable: explica el propósito y la guía de implementación de cada control. En este trabajo se distingue además el <strong>control ISO</strong> (qué se busca, por ejemplo A.8.2) de la <strong>comprobación técnica</strong> que permite observarlo en Oracle (por ejemplo VC-07, que consulta DBA_SYS_PRIVS).</p>
"""


def bloques(artefacto):
    return [
        ("inicio", "Inicio", None),
        ("riesgos", "Riesgos", seccion_riesgos()),
        ("tareas", "Tareas DBA", seccion_tareas()),
        ("controles", "Controles ISO", NORMAS + seccion_controles()),
        ("observables", "Observables", seccion_observables(artefacto)),
        ("matriz", "Matriz", seccion_matriz(artefacto)),
        ("pruebas", "Pruebas", seccion_pruebas(artefacto)),
        ("actuar", "Actuar", ACTUAR + "<h3>Limitaciones</h3>" + LIMITACIONES),
        ("marco", "Marco teórico", MARCO),
        ("ia", "Uso de IA", seccion_ia()),
        ("referencias", "Referencias", seccion_referencias()),
    ]


def resumen_numeros():
    vc = [o["estado"] for o in T["observables"]]
    pr = [t["obtenido"] for t in T["pruebas"]]
    mz = [f["estado_final"] for f in M["filas"]]
    return {
        "vc_cumple": vc.count("Cumple"), "vc_parcial": vc.count("Parcial"), "vc_no": vc.count("No cumple"),
        "vc_pend": vc.count("Pendiente de evaluación"),
        "pr_ok": pr.count("Coincide"), "pr_total": len(pr),
        "mz_cumple": mz.count("Cumple"), "mz_parcial": mz.count("Parcial"),
        "madurez": sum(f["nivel"] for f in M["filas"]) / len(M["filas"]),
    }


CSS = """
:root{--bg:#f7f8fa;--panel:#fff;--ink:#1c2230;--muted:#5d6678;--line:#dde2ea;--head:#123e6b;--soft:#eef2f7;
--ok:#1d7a3e;--okbg:#e2f3e7;--warn:#8f5c00;--warnbg:#fdf0d5;--bad:#a12626;--badbg:#fbe4e4;--pend:#4e5872;--pendbg:#e8ebf1;--acc:#1f5fa8}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#11151c;--panel:#181e27;--ink:#e3e8f0;--muted:#a3adbf;--line:#2c3542;
--head:#8fc1ff;--soft:#202835;--ok:#7dd99b;--okbg:#173525;--warn:#f2c46b;--warnbg:#3a2f15;--bad:#ff9b9b;--badbg:#3d1d1d;--pend:#b9c2d6;--pendbg:#262e3b;--acc:#8fc1ff}}
:root[data-theme="dark"]{--bg:#11151c;--panel:#181e27;--ink:#e3e8f0;--muted:#a3adbf;--line:#2c3542;--head:#8fc1ff;--soft:#202835;
--ok:#7dd99b;--okbg:#173525;--warn:#f2c46b;--warnbg:#3a2f15;--bad:#ff9b9b;--badbg:#3d1d1d;--pend:#b9c2d6;--pendbg:#262e3b;--acc:#8fc1ff}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 "Segoe UI",system-ui,Arial,sans-serif}
a{color:var(--acc)}code{font-family:Consolas,monospace;font-size:12.5px;background:var(--soft);padding:0 3px;border-radius:3px}
h1{font-size:1.5rem;color:var(--head);margin:0 0 4px}h2{font-size:1.2rem;color:var(--head);margin:28px 0 8px;border-bottom:2px solid var(--line);padding-bottom:4px}
h3{font-size:1rem;margin:18px 0 6px}small{color:var(--muted)}
.tabla{overflow-x:auto;margin:8px 0 16px}table{border-collapse:collapse;width:100%;font-size:13px;background:var(--panel)}
th,td{border:1px solid var(--line);padding:6px 8px;vertical-align:top;text-align:left}td:first-child{white-space:nowrap}th{background:var(--soft);position:sticky;top:0}
.chip{display:inline-block;padding:1px 8px;border-radius:10px;font-size:12px;font-weight:600;white-space:nowrap}
.ok{background:var(--okbg);color:var(--ok)}.warn{background:var(--warnbg);color:var(--warn)}.bad{background:var(--badbg);color:var(--bad)}.pend{background:var(--pendbg);color:var(--pend)}
ol.crit{margin:0;padding-left:4px;list-style:none}ol.crit li{margin:2px 0;color:var(--muted)}ol.crit li.actual{color:var(--ink);font-weight:600;background:var(--soft);border-radius:4px}
.nivel{font-size:1.4rem;font-weight:700;color:var(--head)}table.mini{width:auto;max-width:100%}
.refs li{margin-bottom:8px;word-break:break-word}.firma{margin-top:24px}
"""

JS = """
const qs=(s,r=document)=>r.querySelector(s),qsa=(s,r=document)=>[...r.querySelectorAll(s)];
function mostrar(id){qsa('.pestana').forEach(p=>p.hidden=p.id!==id);
 qsa('.side [data-t]').forEach(b=>b.setAttribute('aria-current',b.dataset.t===id));
 const b=qs('.side [data-t="'+id+'"]');qs('#migas').textContent=b?b.dataset.grupo+' / '+b.dataset.nombre:'';
 document.body.classList.remove('menu-abierto');try{localStorage.setItem('iso-tab',id)}catch(e){};qs('.contenido').scrollTo(0,0);window.scrollTo(0,0)}
qsa('[data-t]').forEach(b=>b.addEventListener('click',ev=>{ev.preventDefault();mostrar(b.dataset.t)}));
qs('#menu').onclick=()=>document.body.classList.toggle('menu-abierto');
qs('.velo').onclick=()=>document.body.classList.remove('menu-abierto');
qsa('.pestana').forEach(sec=>{const t=qs('table.filtrable',sec);if(!t)return;const caja=document.createElement('div');caja.className='filtros';
 caja.innerHTML='<label class="buscar"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg><input type="search" placeholder="Buscar en esta tabla (texto, ID, control, estado...)" aria-label="Buscar"></label>'+
 '<select aria-label="Estado"><option value="">Todos los estados</option><option>Cumple</option><option>Parcial</option><option>No cumple</option><option>Coincide</option><option>No coincide</option><option>Pendiente</option></select><span class="cuenta"></span>';
 t.closest('.tabla').before(caja);const [inp,sel,cta]=[qs('input',caja),qs('select',caja),qs('.cuenta',caja)];
 const f=()=>{const q=inp.value.toLowerCase(),s=sel.value.toLowerCase();let n=0;qsa('tbody tr',t).forEach(tr=>{const tx=tr.textContent.toLowerCase();
 const ok=(!q||tx.includes(q))&&(!s||tx.includes(s));tr.hidden=!ok;n+=ok});cta.textContent=n+' de '+qsa('tbody tr',t).length+' registros'};inp.oninput=f;sel.onchange=f;f()});
function abrirEvidencia(id){const pre=qs('#txt-'+CSS.escape(id));qs('#visor-titulo').textContent=id;
 qs('#visor-ruta').textContent='evidencias/'+id+'.txt';qs('#visor-pre').textContent=pre?pre.textContent:'(no encontrada)';qs('#visor').showModal()}
qsa('.evlink').forEach(a=>a.onclick=ev=>{ev.preventDefault();abrirEvidencia(a.dataset.ev)});
qs('#visor-cerrar').onclick=()=>qs('#visor').close();
qs('#visor-copiar').onclick=()=>{try{navigator.clipboard.writeText(qs('#visor-pre').textContent);qs('#visor-copiar').textContent='Copiado'}catch(e){};
 setTimeout(()=>qs('#visor-copiar').textContent='Copiar',1500)};
qsa('.seg button').forEach(b=>b.onclick=()=>{const g=b.closest('.seg');qsa('button',g).forEach(x=>x.setAttribute('aria-pressed',x===b));
 qs(g.dataset.objetivo).dataset.modo=b.dataset.modo});
const tip=qs('#tip');document.addEventListener('pointerover',ev=>{const el=ev.target.closest('[data-tip]');if(!el){tip.hidden=true;return}
 tip.innerHTML=el.dataset.tip;tip.hidden=false});
document.addEventListener('pointermove',ev=>{if(tip.hidden)return;const w=tip.offsetWidth,h=tip.offsetHeight;
 let x=ev.clientX+14,y=ev.clientY+14;if(x+w>innerWidth-8)x=ev.clientX-w-14;if(y+h>innerHeight-8)y=ev.clientY-h-14;tip.style.left=x+'px';tip.style.top=y+'px'});
qs('#tema').onclick=()=>{const r=document.documentElement;const d=r.dataset.theme==='dark'||(!r.dataset.theme&&matchMedia('(prefers-color-scheme: dark)').matches);
 r.dataset.theme=d?'light':'dark';try{localStorage.setItem('iso-tema',r.dataset.theme)}catch(e){}};
try{const t=localStorage.getItem('iso-tema');if(t)document.documentElement.dataset.theme=t}catch(e){}
let ini='inicio';try{ini=localStorage.getItem('iso-tab')||'inicio'}catch(e){};if(!document.getElementById(ini))ini='inicio';mostrar(ini);
"""

CSS_ART = """
:root{--bg:#f3f5f9;--panel:#fff;--ink:#141a26;--muted:#5b6476;--line:#e2e6ee;--soft:#f0f3f8;--head:#0f2f57;--acc:#2a78d6;--serie:#2a78d6;
--side:#0d1b2e;--side2:#13253d;--sideink:#c9d4e5;--sidemut:#7f8ea6;
--good:#0ca30c;--warning:#fab219;--serious:#ec835a;--critical:#d03b3b;--sombra:0 1px 2px rgba(16,24,40,.06),0 1px 3px rgba(16,24,40,.08)}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#0f1218;--panel:#171b23;--ink:#eceef3;--muted:#a3abbb;--line:#2a303c;
--soft:#1f2530;--head:#cfe0ff;--acc:#6aa7f0;--serie:#3987e5;--side:#0a0f17;--side2:#121a26;--sombra:none}}
:root[data-theme="dark"]{--bg:#0f1218;--panel:#171b23;--ink:#eceef3;--muted:#a3abbb;--line:#2a303c;--soft:#1f2530;--head:#cfe0ff;
--acc:#6aa7f0;--serie:#3987e5;--side:#0a0f17;--side2:#121a26;--sombra:none}
body{display:grid;grid-template-columns:256px minmax(0,1fr);min-height:100vh}
svg{width:18px;height:18px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round;flex:none}
.side{background:var(--side);color:var(--sideink);position:sticky;top:0;height:100vh;overflow-y:auto;display:flex;flex-direction:column}
.marca{display:flex;gap:10px;align-items:center;padding:18px 18px 14px;border-bottom:1px solid var(--side2)}
.logo{width:36px;height:36px;border-radius:9px;background:linear-gradient(135deg,#2a78d6,#1b4f91);display:grid;place-items:center;color:#fff}
.logo svg{width:20px;height:20px}.marca b{display:block;color:#fff;font-size:15px;line-height:1.2}.marca small{color:var(--sidemut);font-size:12px}
.grupo{padding:14px 10px 2px}.grupo p{margin:0 10px 6px;font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--sidemut)}
.side button{display:flex;gap:10px;align-items:center;width:100%;background:none;border:0;color:inherit;font:inherit;font-size:14px;
padding:8px 10px;border-radius:8px;cursor:pointer;text-align:left}
.side button:hover{background:var(--side2);color:#fff}
.side button[aria-current="true"]{background:#1d3a5f;color:#fff;box-shadow:inset 3px 0 0 #6aa7f0}
.side .cnt{margin-left:auto;font-size:11px;background:var(--side2);color:var(--sideink);padding:1px 7px;border-radius:10px}
.pie{margin-top:auto;padding:14px 18px;border-top:1px solid var(--side2);font-size:12px;color:var(--sidemut)}
.pie b{color:var(--sideink);display:block;font-size:13px}
.contenido{min-width:0;display:flex;flex-direction:column}
.barra{position:sticky;top:0;z-index:6;display:flex;align-items:center;gap:12px;padding:10px 24px;background:var(--panel);border-bottom:1px solid var(--line)}
#migas{color:var(--muted);font-size:13.5px}.barra .esp{flex:1}
.insignia{display:inline-flex;gap:6px;align-items:center;font-size:12px;padding:4px 10px;border-radius:20px;background:var(--soft);color:var(--muted);border:1px solid var(--line);white-space:nowrap}
.punto{width:8px;height:8px;border-radius:50%;background:var(--good)}
.icono{display:inline-grid;place-items:center;width:34px;height:34px;border-radius:8px;border:1px solid var(--line);background:var(--panel);color:var(--ink);cursor:pointer}
#menu{display:none}
main{padding:22px 24px 60px;max-width:1500px;width:100%}
.pestana>header{margin-bottom:16px}.pestana>header h2{margin:0;border:0;padding:0;font-size:1.45rem;color:var(--ink)}
.pestana>header p{margin:4px 0 0;color:var(--muted);max-width:900px}
h2{color:var(--ink)}h3{font-size:1rem;margin:22px 0 8px;color:var(--ink)}
.tarjeta,.tabla,.pestana>p,.pestana>ul,.pestana>div.texto{background:var(--panel);border:1px solid var(--line);border-radius:12px;box-shadow:var(--sombra)}
.pestana>p,.pestana>ul,.pestana>div.texto{padding:14px 18px}.pestana>ul{padding-left:36px}
.tabla{overflow:auto;max-height:72vh;margin:10px 0 18px}
table{background:transparent;font-size:13px}th,td{border:0;border-bottom:1px solid var(--line);padding:9px 12px}
th{background:var(--soft);font-size:12px;text-transform:uppercase;letter-spacing:.03em;color:var(--muted);z-index:1}
tbody tr:hover td{background:var(--soft)}table.mini{width:100%}table.mini th{text-transform:none;letter-spacing:0;font-size:13px;width:190px}
.chip{border-radius:20px;padding:2px 9px;font-weight:600}
.chip.ok{background:color-mix(in srgb,var(--good) 16%,transparent);color:var(--ink)}
.chip.ok::before{content:"✓ ";color:var(--good)}
.chip.warn{background:color-mix(in srgb,var(--warning) 22%,transparent);color:var(--ink)}
.chip.warn::before{content:"! ";color:#b07800}
.chip.bad{background:color-mix(in srgb,var(--critical) 16%,transparent);color:var(--ink)}
.chip.bad::before{content:"✕ ";color:var(--critical)}
.chip.pend{background:var(--soft);color:var(--muted)}
.filtros{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:4px 0 0}
.buscar{flex:1;min-width:240px;display:flex;align-items:center;gap:8px;padding:0 12px;border:1px solid var(--line);border-radius:10px;background:var(--panel);color:var(--muted)}
.buscar input{flex:1;border:0;outline:0;background:none;font:inherit;padding:9px 0;color:var(--ink)}
.filtros select{font:inherit;padding:9px 12px;border:1px solid var(--line);border-radius:10px;background:var(--panel);color:var(--ink)}
.cuenta{color:var(--muted);font-size:13px}
.aviso{display:flex;gap:10px;align-items:flex-start;background:color-mix(in srgb,var(--warning) 12%,var(--panel));border:1px solid color-mix(in srgb,var(--warning) 40%,var(--line));
border-radius:12px;padding:12px 16px;margin:0 0 18px;font-size:13.5px}
.aviso svg{color:#b07800;margin-top:2px}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(210px,100%),1fr));gap:14px;margin:0 0 18px}
.kpi{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:16px;box-shadow:var(--sombra)}
.kpi .et{display:flex;align-items:center;gap:8px;color:var(--muted);font-size:13px}
.kpi .et svg{color:var(--acc)}
.kpi b{display:block;font-size:2rem;line-height:1.1;margin:8px 0 2px;color:var(--ink);font-weight:650}
.kpi b span{font-size:1rem;color:var(--muted);font-weight:500}.kpi small{display:block}
.prog{height:8px;border-radius:4px;background:var(--soft);margin-top:10px;overflow:hidden;display:flex;gap:2px}
.prog i{display:block;height:100%;border-radius:4px}
.rejilla{display:grid;grid-template-columns:repeat(12,1fr);gap:14px;margin-bottom:14px}
.c7{grid-column:span 7}.c5{grid-column:span 5}.c6{grid-column:span 6}.c12{grid-column:span 12}
.tarjeta{padding:16px 18px;min-width:0}.tarjeta h3{margin:0;font-size:15px}.tarjeta .sub{color:var(--muted);font-size:13px;margin:2px 0 12px}
.tcab{display:flex;justify-content:space-between;gap:10px;align-items:flex-start;flex-wrap:wrap}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:9px;padding:2px;background:var(--soft)}
.seg button{font:inherit;font-size:12.5px;border:0;background:none;color:var(--muted);padding:4px 10px;border-radius:7px;cursor:pointer}
.seg button[aria-pressed="true"]{background:var(--panel);color:var(--ink);box-shadow:var(--sombra);font-weight:600}
.calor{display:grid;grid-template-columns:28px repeat(5,1fr);gap:3px;font-size:12px}
.calor .ej{display:grid;place-items:center;color:var(--muted)}
.celda{min-height:62px;border-radius:6px;padding:5px;display:flex;flex-wrap:wrap;gap:4px;align-content:flex-start;position:relative}
.celda::after{content:attr(data-v);position:absolute;right:6px;bottom:3px;font-size:10.5px;color:var(--muted)}
.lv-Bajo{background:color-mix(in srgb,var(--good) 14%,var(--panel))}.lv-Medio{background:color-mix(in srgb,var(--warning) 20%,var(--panel))}
.lv-Alto{background:color-mix(in srgb,var(--serious) 24%,var(--panel))}.lv-Crítico{background:color-mix(in srgb,var(--critical) 24%,var(--panel))}
.rk{font-size:11px;font-weight:650;padding:2px 6px;border-radius:5px;background:var(--panel);color:var(--ink);border:1px solid var(--line);cursor:default}
#calor[data-modo="inh"] .rk.res,#calor[data-modo="res"] .rk.inh{display:none}
.ejes{display:flex;justify-content:space-between;color:var(--muted);font-size:12px;margin:6px 0 0 31px}
.leyenda{display:flex;gap:14px;flex-wrap:wrap;font-size:12.5px;color:var(--muted);margin-top:10px}
.leyenda span{display:inline-flex;gap:6px;align-items:center}.leyenda i{width:12px;height:12px;border-radius:3px;display:inline-block}
.pila{display:flex;gap:2px;height:28px;border-radius:6px;overflow:hidden;margin:6px 0 10px}.pila i{display:block;height:100%}
.estados{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:12px}
.estados div{border:1px solid var(--line);border-radius:10px;padding:10px 12px}.estados b{font-size:1.5rem;display:block;color:var(--ink)}
.estados span{font-size:12.5px;color:var(--muted);display:flex;gap:6px;align-items:center}
.lista{list-style:none;margin:0;padding:0}.lista li{padding:9px 0;border-top:1px solid var(--line);font-size:13.5px}
.lista li:first-child{border-top:0}
.barras{display:grid;grid-template-columns:auto 1fr auto;gap:7px 12px;align-items:center;font-size:13px}
.barras .nom{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:260px}.barras .nom b{margin-right:6px}
.pista{height:14px;background:var(--soft);border-radius:4px;position:relative}
.pista i{position:absolute;left:0;top:0;bottom:0;background:var(--serie);border-radius:0 4px 4px 0}
.pista::before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(90deg,transparent 0 calc(25% - 1px),var(--line) calc(25% - 1px) 25%)}
.val{font-weight:650;min-width:30px;text-align:right}
.escala{display:flex;justify-content:space-between;color:var(--muted);font-size:11px;grid-column:2}
.fases{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
.fase{border:1px solid var(--line);border-radius:10px;padding:12px;position:relative;cursor:pointer;background:var(--panel)}
.fase:hover{border-color:var(--acc)}.fase .n{display:inline-grid;place-items:center;width:26px;height:26px;border-radius:50%;background:var(--acc);color:#fff;font-weight:700;font-size:13px}
.fase b{display:block;margin:8px 0 2px}.fase small{line-height:1.35;display:block}
.linea{list-style:none;margin:0;padding:0}.linea li{display:grid;grid-template-columns:20px 1fr;gap:10px;padding:10px 0;border-top:1px solid var(--line)}
.linea li:first-child{border-top:0}.linea .pt{width:12px;height:12px;border-radius:50%;margin-top:4px;border:3px solid var(--acc);background:var(--panel)}
.linea .flujo{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-top:4px;font-size:12.5px}
.evlink{white-space:nowrap;font-family:Consolas,monospace;font-size:12.5px;text-decoration:none;padding:1px 6px;border-radius:5px;background:color-mix(in srgb,var(--acc) 10%,transparent)}
.evlink:hover{text-decoration:underline}
.btn{font:inherit;font-size:13px;display:inline-flex;gap:6px;align-items:center;border:1px solid var(--line);background:var(--panel);color:var(--ink);border-radius:8px;padding:6px 12px;cursor:pointer}
.btn.prim{background:var(--acc);border-color:var(--acc);color:#fff}
dialog{width:min(1100px,95vw);max-height:90vh;border:1px solid var(--line);border-radius:14px;background:var(--panel);color:var(--ink);padding:0;box-shadow:0 20px 60px rgba(0,0,0,.35)}
dialog::backdrop{background:rgba(8,12,20,.55)}
.vcab{display:flex;gap:12px;justify-content:space-between;align-items:center;padding:12px 16px;border-bottom:1px solid var(--line)}
.vcab small{display:block;font-family:Consolas,monospace}
#visor-pre{margin:0;padding:14px 16px;overflow:auto;max-height:76vh;font:12px/1.4 Consolas,monospace;white-space:pre;background:var(--soft)}
#tip{position:fixed;z-index:50;max-width:320px;background:var(--panel);color:var(--ink);border:1px solid var(--line);border-radius:8px;padding:8px 10px;
font-size:12.5px;box-shadow:0 8px 24px rgba(0,0,0,.18);pointer-events:none}
.velo{display:none}
@media (max-width:1100px){.c7,.c5,.c6{grid-column:span 12}.fases{grid-template-columns:repeat(2,1fr)}}
@media (max-width:900px){body{grid-template-columns:minmax(0,1fr)}.side{position:fixed;left:0;top:0;z-index:20;width:270px;transform:translateX(-100%);transition:transform .2s}
body.menu-abierto .side{transform:none}body.menu-abierto .velo{display:block;position:fixed;inset:0;z-index:15;background:rgba(0,0,0,.45)}
#menu{display:inline-grid}.barra{padding:10px 16px}main{padding:16px 16px 50px}.insignia.ocultable{display:none}.barras .nom{max-width:130px}}
@media (max-width:560px){.fases,.estados{grid-template-columns:1fr}.kpi b{font-size:1.6rem}}
"""

ICONOS = {
    "inicio": '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
    "riesgos": '<path d="M12 3l9.5 16.5h-19z"/><path d="M12 10v4"/><path d="M12 17.5h.01"/>',
    "tareas": '<path d="M10 6h10M10 12h10M10 18h10"/><path d="M4 6l1.5 1.5L8 5M4 12l1.5 1.5L8 11M4 18l1.5 1.5L8 17"/>',
    "controles": '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
    "observables": '<circle cx="12" cy="12" r="3"/><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/>',
    "matriz": '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>',
    "pruebas": '<path d="M9 3h6M10 3v6l-5.5 9.5A1.7 1.7 0 006 21h12a1.7 1.7 0 001.5-2.5L14 9V3"/><path d="M7 15h10"/>',
    "actuar": '<path d="M20 12a8 8 0 11-2.3-5.7"/><path d="M20 4v5h-5"/>',
    "evidencias": '<path d="M14 3H6.5A1.5 1.5 0 005 4.5v15A1.5 1.5 0 006.5 21h11a1.5 1.5 0 001.5-1.5V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>',
    "marco": '<path d="M4 19.5A2.5 2.5 0 016.5 17H20V3H6.5A2.5 2.5 0 004 5.5z"/><path d="M4 19.5A2.5 2.5 0 006.5 22H20v-5"/>',
    "ia": '<rect x="4" y="7" width="16" height="13" rx="2.5"/><path d="M12 3v4M9 12.5h.01M15 12.5h.01M9.5 16.5h5"/>',
    "referencias": '<path d="M10 13a5 5 0 007 0l3-3a5 5 0 00-7-7l-1 1"/><path d="M14 11a5 5 0 00-7 0l-3 3a5 5 0 007 7l1-1"/>',
    "db": '<ellipse cx="12" cy="5.5" rx="8" ry="2.5"/><path d="M4 5.5v13c0 1.4 3.6 2.5 8 2.5s8-1.1 8-2.5v-13"/><path d="M4 12c0 1.4 3.6 2.5 8 2.5s8-1.1 8-2.5"/>',
    "aviso": '<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/>',
    "menu": '<path d="M4 6h16M4 12h16M4 18h16"/>',
    "tema": '<path d="M21 12.8A9 9 0 1111.2 3a7 7 0 009.8 9.8z"/>',
}


def icono(nombre):
    return f'<svg viewBox="0 0 24 24" aria-hidden="true">{ICONOS[nombre]}</svg>'


GRUPOS = [("General", ["inicio"]), ("Planificar", ["riesgos", "tareas", "controles"]),
          ("Hacer y verificar", ["observables", "pruebas", "matriz", "evidencias"]), ("Actuar", ["actuar"]),
          ("Documentación", ["marco", "referencias"])]

DESCRIPCION = {
    "inicio": "Estado general del laboratorio: riesgos, controles verificados, madurez y hallazgos.",
    "riesgos": "Riesgos de confidencialidad valorados con probabilidad × impacto, antes (inherente) y después (residual) de los controles.",
    "tareas": "Tareas críticas del DBA que afectan la confidencialidad, cómo se implementan en Oracle y si son demostrables en este entorno.",
    "controles": "Controles del Anexo A de ISO/IEC 27001:2022 seleccionados, con su implementación en Oracle, evidencia y limitaciones.",
    "observables": "Comprobaciones que un auditor externo puede ejecutar. El resultado se lee de la salida real de cada script VC.",
    "pruebas": "Pruebas positivas y negativas. «Coincide» significa que la evidencia contiene el resultado esperado.",
    "matriz": "Matriz de evaluación: tarea, riesgo, control, criterio de madurez 0–4, evidencia y estado.",
    "evidencias": "Salidas reales de Oracle guardadas al ejecutar cada script. Haga clic en una para ver su contenido.",
    "actuar": "Hallazgos corregidos y verificados de nuevo, propuestas de mejora y limitaciones del laboratorio.",
    "marco": "Fundamentos teóricos del trabajo.",
    "ia": "Tabla de uso de IA y declaración jurada (sección 8 del enunciado).",
    "referencias": "Fuentes citadas en formato APA 7.",
}

FASE_EV = {"E": "Hacer (configuración)", "VC": "Verificar (control observable)", "PR": "Verificar (prueba)", "A": "Actuar (corrección)"}


def cabecera_evidencia(nombre):
    datos = {}
    for linea in (leer_evidencia(nombre) or "").splitlines()[:8]:
        m = re.match(r"^== (\w+)\s*: (.*)$", linea)
        if m:
            datos[m.group(1)] = m.group(2).strip()
    return datos


def seccion_evidencias():
    filas = []
    for x in evidencias_todas:
        d = cabecera_evidencia(x)
        fase = FASE_EV.get(x.split("-")[0], "—")
        if x.endswith("_DESPUES") or "despues" in x:
            fase = "Actuar (verificación repetida)"
        res = resultado_vc(x) if x.startswith("VC-") else None
        filas.append([ev_link(x, True), e(fase), f"<code>{e(d.get('Script', '—'))}</code>", e(d.get("Modo", "—")),
                      e(d.get("Fecha", "—")[:16]), chip(ESTADO_VC[res]) if res else "—"])
    return tabla(["Evidencia", "Fase PHVA", "Script", "Modo de conexión", "Fecha", "Resultado"], filas, "t-evidencias")


def tablero(n):
    nivel_cls = {"Bajo": "var(--good)", "Medio": "var(--warning)", "Alto": "var(--serious)", "Crítico": "var(--critical)"}
    # Mapa de calor 5×5: filas = probabilidad (5 arriba), columnas = impacto.
    celdas = []
    for p in range(5, 0, -1):
        celdas.append(f'<div class="ej">{p}</div>')
        for i in range(1, 6):
            marcas = ""
            for r in P["riesgos"]:
                for modo, (rp, ri) in (("inh", (r["p"], r["i"])), ("res", (r["p_res"], r["i_res"]))):
                    if (rp, ri) == (p, i):
                        v = rp * ri
                        marcas += (f'<span class="rk {modo}" data-tip="<b>{e(r["id"])}</b> · {e(r["amenaza"])}<br>'
                                   f'{"Inherente" if modo == "inh" else "Residual"}: {rp} × {ri} = {v} ({nivel(v)})">{e(r["id"][-2:])}</span>')
            celdas.append(f'<div class="celda lv-{nivel(p * i)}" data-v="{p * i}">{marcas}</div>')
    criticos_inh = sum(nivel(r["inh"]) == "Crítico" for r in P["riesgos"])
    criticos_res = sum(nivel(r["res"]) == "Crítico" for r in P["riesgos"])
    total_vc = len(T["observables"])
    seg = lambda cant, color: f'<i style="flex:{cant};background:{color}"></i>' if cant else ""
    # Solo las comprobaciones VC en PARCIAL; el motivo se toma de la fila de la matriz del mismo control.
    just = {f["control"]: f["justificacion"] for f in M["filas"]}
    parciales = "".join(f'<li>{chip(o["estado"])} <b>{e(o["id"])} · {e(o["control"])}</b> — {e(just.get(o["control"], ""))}</li>'
                        for o in T["observables"] if o["estado"] in ("Parcial", "No cumple"))
    titulos = {c["id"]: c["titulo"] for c in P["controles"]}
    barras = "".join(
        f'<div class="nom" data-tip="<b>{e(f["control"])}</b> {e(titulos.get(f["control"], ""))}<br>{e(f["justificacion"])}">'
        f'<b>{e(f["control"])}</b>{e(titulos.get(f["control"], ""))}</div>'
        f'<div class="pista" data-tip="<b>{e(f["control"])}</b>: nivel {f["nivel"]} de 4 · {e(f["estado_final"])}"><i style="width:{f["nivel"] * 25}%"></i></div>'
        f'<div class="val">{f["nivel"]}</div>' for f in M["filas"])
    vc07_antes = ESTADO_VC[resultado_vc("VC-07_acceso_privilegiado")]
    vc07_desp = ESTADO_VC[resultado_vc("VC-07_acceso_privilegiado_DESPUES")]
    ev = lambda x: ev_link(x, True)
    hallazgos = f"""
<li><span class="pt"></span><div><b>Cuenta con SELECT ANY TABLE (A.8.2)</b><div class="flujo">{ev('VC-07_acceso_privilegiado')} {chip(vc07_antes)} →
 {ev('A-01_revocar_privilegio')} → {ev('VC-07_acceso_privilegiado_DESPUES')} {chip(vc07_desp)}</div></div></li>
<li><span class="pt"></span><div><b>El DBA modifica las reglas de VPD (A.8.2, A.8.15)</b><div class="flujo">{ev('PR-19_dba_reglas_antes')} sin auditar →
 {ev('A-02_auditar_reglas')} → {ev('PR-19_dba_reglas_despues')} {chip('Auditado', 'ok')} <small>se detecta, no se impide</small></div></div></li>
<li><span class="pt"></span><div><b>Data Pump exporta en claro datos TDE (A.8.12, A.8.13)</b><div class="flujo">{ev('PR-16_respaldos_cifrados')}
 ORA-39173 / ORA-00439 → respaldos RMAN cifrados {ev('E-11_rman_cifrado')} {chip('Parcial')}</div></div></li>
<li><span class="pt"></span><div><b>Columnas sin clasificar (A.5.12)</b><div class="flujo">primera ejecución: 4 columnas de VENTAS →
 script 04 corregido → {ev('VC-01_clasificacion')} {chip(ESTADO_VC[resultado_vc('VC-01_clasificacion')])}</div></div></li>"""
    fases = [("1", "Planificar", f"{len(P['riesgos'])} riesgos · {len(P['tareas'])} tareas · {len(P['controles'])} controles", "riesgos"),
             ("2", "Hacer", "TDE, roles y perfiles, VPD, Redaction, auditoría, copia DEV, RMAN y red", "evidencias"),
             ("3", "Verificar", f"{total_vc} comprobaciones · {n['pr_total']} pruebas", "observables"),
             ("4", "Actuar", "2 correcciones verificadas · 7 propuestas", "actuar")]
    fases_html = "".join(f'<div class="fase" data-t="{d}" role="button" tabindex="0"><span class="n">{k}</span><b>{t}</b><small>{s}</small></div>'
                         for k, t, s, d in fases)
    return f"""
<div class="aviso">{icono('aviso')}<div><strong>Modo consulta.</strong> {e(P['meta']['aviso'])}</div></div>
<div class="kpis">
<div class="kpi"><div class="et">{icono('riesgos')}Riesgos críticos</div><b>{criticos_inh} <span>→ {criticos_res} tras controles</span></b>
<small>de {len(P['riesgos'])} riesgos valorados</small></div>
<div class="kpi"><div class="et">{icono('observables')}Controles observables</div><b>{n['vc_cumple']} <span>/ {total_vc} en CUMPLE</span></b><small>{n['vc_parcial']} parcial · {n['vc_no']} no cumple</small>
<div class="prog">{seg(n['vc_cumple'], 'var(--good)')}{seg(n['vc_parcial'], 'var(--warning)')}{seg(n['vc_no'], 'var(--critical)')}{seg(n['vc_pend'], 'var(--line)')}</div></div>
<div class="kpi"><div class="et">{icono('pruebas')}Pruebas</div><b>{n['pr_ok']} <span>/ {n['pr_total']} coinciden</span></b>
<small>con el resultado esperado</small><div class="prog">{seg(n['pr_ok'], 'var(--good)')}{seg(n['pr_total'] - n['pr_ok'], 'var(--critical)')}</div></div>
<div class="kpi"><div class="et">{icono('matriz')}Madurez promedio</div><b>{n['madurez']:.1f} <span>/ 4</span></b>
<small>matriz: {n['mz_cumple']} cumple · {n['mz_parcial']} parcial</small><div class="prog"><i style="width:{n['madurez'] / 4 * 100:.0f}%;background:var(--serie)"></i></div></div>
</div>
<div class="rejilla">
<section class="tarjeta c12"><div class="tcab"><div><h3>Ciclo PHVA</h3><p class="sub">Haga clic en una fase para ir a su detalle.</p></div></div>
<div class="fases">{fases_html}</div></section>
<section class="tarjeta c7"><div class="tcab"><div><h3>Mapa de calor de riesgos</h3><p class="sub">Probabilidad × impacto (escala 1–5). Pase el cursor sobre un riesgo.</p></div>
<div class="seg" data-objetivo="#calor" role="group" aria-label="Vista"><button data-modo="inh" aria-pressed="true">Inherente</button><button data-modo="res" aria-pressed="false">Residual</button></div></div>
<div id="calor" data-modo="inh"><div class="calor">{''.join(celdas)}</div>
<div class="ejes"><span>Impacto 1</span><span>→</span><span>5</span></div></div>
<div class="leyenda">{''.join(f'<span><i style="background:{c}"></i>{k}</span>' for k, c in nivel_cls.items())}<span>Eje vertical: probabilidad</span></div></section>
<section class="tarjeta c5"><h3>Resultado de las comprobaciones</h3><p class="sub">{total_vc} scripts VC de solo lectura, resultado leído de la evidencia.</p>
<div class="estados"><div><b>{n['vc_cumple']}</b><span>{chip('Cumple')}</span></div><div><b>{n['vc_parcial']}</b><span>{chip('Parcial')}</span></div>
<div><b>{n['vc_no']}</b><span>{chip('No cumple')}</span></div></div>
<div class="pila" aria-hidden="true">{seg(n['vc_cumple'], 'var(--good)')}{seg(n['vc_parcial'], 'var(--warning)')}{seg(n['vc_no'], 'var(--critical)')}</div>
<ul class="lista">{parciales}</ul></section>
<section class="tarjeta c6"><h3>Madurez por control</h3><p class="sub">Nivel alcanzado en la matriz (0 inexistente – 4 gestionado).</p>
<div class="barras">{barras}<span></span><div class="escala"><span>0</span><span>1</span><span>2</span><span>3</span><span>4</span></div><span></span></div></section>
<section class="tarjeta c6"><h3>Hallazgos y correcciones</h3><p class="sub">Cada paso enlaza a su evidencia.</p><ul class="linea">{hallazgos}</ul></section>
<section class="tarjeta c12"><h3>Entorno verificado</h3><p class="sub">Datos tomados del diagnóstico E-00.</p>{ENTORNO}</section>
</div>"""


def artefacto():
    n = resumen_numeros()
    gen = datetime.now().strftime("%d/%m/%Y %H:%M")
    contenido = {i: (t, c) for i, t, c in bloques(True)}
    contenido["inicio"] = ("Panel general", tablero(n))
    contenido["evidencias"] = ("Evidencias", seccion_evidencias())
    # La sección de uso de IA se presenta en el informe y en la tabla firmada, no en el artefacto.
    del contenido["ia"]
    contenido["marco"] = (contenido["marco"][0], f'<div class="texto">{contenido["marco"][1]}</div>')
    contenido["actuar"] = (contenido["actuar"][0], f'<div class="texto">{contenido["actuar"][1]}</div>')
    contenido["referencias"] = (contenido["referencias"][0], f'<div class="texto">{contenido["referencias"][1]}</div>')
    cuenta = {"riesgos": len(P["riesgos"]), "tareas": len(P["tareas"]), "controles": len(P["controles"]),
              "observables": len(T["observables"]), "pruebas": n["pr_total"], "matriz": len(M["filas"]),
              "evidencias": len(evidencias_todas)}
    menu = ""
    for grupo, ids in GRUPOS:
        menu += f'<div class="grupo"><p>{e(grupo)}</p>'
        for i in ids:
            c = f'<span class="cnt">{cuenta[i]}</span>' if i in cuenta else ""
            menu += (f'<button data-t="{i}" data-grupo="{e(grupo)}" data-nombre="{e(contenido[i][0])}">'
                     f'{icono(i)}<span>{e(contenido[i][0])}</span>{c}</button>')
        menu += "</div>"
    secciones = "".join(f'<section class="pestana" id="{i}" hidden><header><h2>{e(t)}</h2><p>{e(DESCRIPCION[i])}</p></header>{c}</section>'
                        for i, (t, c) in contenido.items())

    def incrustar(nombre):
        # Evita que un "</script>" dentro de la evidencia cierre la etiqueta
        return re.sub(r"</(script)", r"<\\/\1", leer_evidencia(nombre) or "", flags=re.I)
    textos = "".join(f'<script type="text/plain" id="txt-{e(x)}">{incrustar(x)}</script>' for x in evidencias_todas)
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>ISO 27001 Confidencialidad Oracle</title><style>{CSS}{CSS_ART}</style></head><body>
<aside class="side" aria-label="Módulos"><div class="marca"><span class="logo">{icono('controles')}</span><div><b>Confidencialidad Oracle</b><small>ISO/IEC 27001:2022 · PHVA</small></div></div>
<nav>{menu}</nav>
<div class="pie"><b>{e(P['meta']['estudiante'])}</b>{e(P['meta']['curso'])}<br>Prof. {e(P['meta']['profesor'])} · {e(P['meta']['ciclo'])}</div></aside>
<div class="velo"></div>
<div class="contenido">
<div class="barra"><button id="menu" class="icono" type="button" aria-label="Abrir menú">{icono('menu')}</button>
<span id="migas"></span><span class="esp"></span>
<span class="insignia ocultable">{icono('db')}Oracle 26ai Free · FREEPDB1</span>
<span class="insignia ocultable"><span class="punto"></span>Evidencias del {gen}</span>
<button id="tema" class="icono" type="button" aria-label="Cambiar tema claro/oscuro" title="Tema claro/oscuro">{icono('tema')}</button></div>
<main>{secciones}</main></div>
<div id="tip" hidden></div>
<dialog id="visor"><div class="vcab"><div><strong id="visor-titulo"></strong><small id="visor-ruta"></small></div>
<div><button id="visor-copiar" class="btn" type="button">Copiar</button> <button id="visor-cerrar" class="btn prim" type="button">Cerrar</button></div></div><pre id="visor-pre"></pre></dialog>
{textos}<script>{JS}</script></body></html>"""


CSS_INF = """
body{background:#fff;color:#1c2230}main{max-width:980px;margin:0 auto;padding:24px 18px}
.portada{text-align:center;padding:60px 0 40px;border-bottom:2px solid var(--line);margin-bottom:20px}
.portada h1{font-size:1.8rem}.portada p{margin:4px 0}.aviso{border-left:4px solid var(--warn);background:var(--warnbg);padding:8px 12px}
th{position:static}
@media print{@page{size:Letter landscape;margin:12mm}main{max-width:none;padding:0}h2{break-before:page}h2.nobreak{break-before:auto}
tr,li{break-inside:avoid}.tabla{overflow:visible}a{color:inherit;text-decoration:none}}
"""


def informe():
    n = resumen_numeros()
    secc = bloques(False)[1:]
    cuerpo = "".join(f"<h2>{k}. {e(t)}</h2>{c}" for k, (_, t, c) in enumerate(secc, start=3))
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Informe ISO 27001 Confidencialidad Oracle</title><style>:root{{color-scheme:light}}{CSS.split('@media (prefers-color-scheme:dark)')[0]}{CSS[CSS.index('*{box-sizing'):]}{CSS_INF}</style></head><body><main>
<div class="portada"><p>Universidad Nacional de Costa Rica · Escuela de Informática</p><p>{e(P['meta']['curso'])} · {e(P['meta']['ciclo'])}</p>
<h1>{e(P['meta']['titulo'])}</h1><p>Profesor: {e(P['meta']['profesor'])}</p><p><strong>Estudiante: {e(P['meta']['estudiante'])}</strong></p>
<p>{datetime.now().strftime('%d/%m/%Y')}</p></div>
<p class="aviso">{e(P['meta']['aviso'])} El artefacto interactivo está en <code>artefacto/index.html</code> (abrir con doble clic) y contiene las salidas completas de cada evidencia.</p>
<h2 class="nobreak">1. Resumen</h2>
<p>Se diseñó y verificó un marco de controles basado en el Anexo A de ISO/IEC 27001:2022 para la confidencialidad en las tareas del DBA, sobre {e(P['meta']['motor'])}.
Se identificaron {len(P['riesgos'])} riesgos y {len(P['tareas'])} tareas críticas, se mapearon 15 controles y se construyeron 15 comprobaciones observables y {n['pr_total']} pruebas.
Resultado registrado: {n['vc_cumple']} comprobaciones en CUMPLE, {n['vc_parcial']} en PARCIAL y {n['vc_no']} en NO CUMPLE; {n['pr_ok']} de {n['pr_total']} pruebas con el resultado esperado;
madurez promedio {n['madurez']:.1f} de 4. Las brechas se explican en la sección «Actuar».</p>
<h2 class="nobreak">2. Alcance, entorno y metodología</h2>{ENTORNO}{PHVA}
{cuerpo}</main></body></html>"""


def main():
    (RAIZ / "artefacto").mkdir(exist_ok=True)
    (RAIZ / "artefacto" / "index.html").write_text(artefacto(), encoding="utf-8")
    inf = RAIZ / "docs" / "informe" / "informe.html"
    inf.write_text(informe(), encoding="utf-8")
    n = resumen_numeros()
    print(f"artefacto/index.html y docs/informe/informe.html generados | VC cumple={n['vc_cumple']} parcial={n['vc_parcial']} "
          f"no={n['vc_no']} pend={n['vc_pend']} | pruebas ok={n['pr_ok']}/{n['pr_total']}")
    for t in T["pruebas"]:
        if t["obtenido"] != "Coincide":
            print(f"  ATENCIÓN {t['id']}: {t['obtenido']} -> {t['faltan']}")
    edge = Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
    if edge.exists():
        (RAIZ / "entregables").mkdir(exist_ok=True)
        # Perfil propio para que Edge headless no choque con las ventanas abiertas del usuario.
        perfil = Path(tempfile.mkdtemp(prefix="edge-pdf-"))
        ia = RAIZ / "docs" / "informe" / "tabla-uso-ia.html"
        ia.write_text(tabla_ia_firmada(), encoding="utf-8")
        for origen, nombre in ((inf, "Informe-ISO27001-Confidencialidad-Oracle.pdf"),
                               (ia, "Tabla-Uso-IA-Firmada-ISO27001-Oracle.pdf")):
            pdf = RAIZ / "entregables" / nombre
            subprocess.run([str(edge), "--headless=new", "--disable-gpu", "--no-pdf-header-footer", f"--user-data-dir={perfil}",
                            f"--print-to-pdf={pdf}", origen.as_uri()], check=False, capture_output=True, timeout=180)
            print("PDF:", pdf if pdf.exists() else "no generado")


if __name__ == "__main__":
    sys.exit(main())
