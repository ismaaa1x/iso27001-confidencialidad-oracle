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
    texto = (RAIZ / "docs" / "ia" / "registro-uso-ia.md").read_text(encoding="utf-8")
    filas = []
    for linea in texto.splitlines():
        if re.match(r"^\| \d{2} \|", linea):
            celdas = [c.strip() for c in linea.strip().strip("|").split(" | ")]
            filas.append([e(c) for c in celdas])
    return (tabla(["#", "Herramienta IA", "Prompt exacto utilizado", "Aporte de la IA",
                   "Validación / corrección del estudiante", "Fuente verificada"], filas, "t-ia", filtrable=False) +
            "<p>El prompt 01 completo está en <code>docs/ia/prompt-01-analisis-inicial.md</code>. "
            "La validación del estudiante está <strong>pendiente</strong> hasta que él mismo la complete.</p>"
            "<h3>Declaración jurada</h3><p>Yo, <strong>Ismael Rojas Herrera</strong>, declaro que todo contenido generado "
            "con IA ha sido declarado en la tabla anterior, validado contra fuentes oficiales (ISO, documentación del motor "
            "de BD) y que asumo responsabilidad por su veracidad. Entiendo que omitir esta declaración constituye falta grave.</p>"
            "<p class='firma'>Firma: ______________________________ &nbsp;&nbsp; Fecha: ________________</p>"
            "<p><small>Sin firmar: el estudiante la firma después de completar las validaciones pendientes.</small></p>")


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
function mostrar(id){qsa('.pestana').forEach(p=>p.hidden=p.id!==id);qsa('nav button').forEach(b=>b.setAttribute('aria-current',b.dataset.t===id));
 try{localStorage.setItem('iso-tab',id)}catch(e){};window.scrollTo(0,0)}
qsa('nav button').forEach(b=>b.onclick=()=>mostrar(b.dataset.t));
qsa('.pestana').forEach(sec=>{const t=qs('table.filtrable',sec);if(!t)return;const caja=document.createElement('div');caja.className='filtros';
 caja.innerHTML='<input type="search" placeholder="Filtrar esta tabla (texto, ID, control, estado...)" aria-label="Filtrar">'+
 '<select aria-label="Estado"><option value="">Todos los estados</option><option>Cumple</option><option>Parcial</option><option>No cumple</option><option>Coincide</option><option>No coincide</option><option>Pendiente</option></select><span class="cuenta"></span>';
 t.closest('.tabla').before(caja);const [inp,sel,cta]=[qs('input',caja),qs('select',caja),qs('.cuenta',caja)];
 const f=()=>{const q=inp.value.toLowerCase(),s=sel.value.toLowerCase();let n=0;qsa('tbody tr',t).forEach(tr=>{const tx=tr.textContent.toLowerCase();
 const ok=(!q||tx.includes(q))&&(!s||tx.includes(s));tr.hidden=!ok;n+=ok});cta.textContent=n+' fila(s)'};inp.oninput=f;sel.onchange=f;f()});
qsa('.evlink').forEach(a=>a.onclick=ev=>{ev.preventDefault();const id=a.dataset.ev;const pre=qs('#txt-'+CSS.escape(id));
 qs('#visor-titulo').textContent='evidencias/'+id+'.txt';qs('#visor-pre').textContent=pre?pre.textContent:'(no encontrada)';qs('#visor').showModal()});
qs('#visor-cerrar').onclick=()=>qs('#visor').close();
qs('#tema').onclick=()=>{const r=document.documentElement;const d=r.dataset.theme==='dark'||(!r.dataset.theme&&matchMedia('(prefers-color-scheme: dark)').matches);
 r.dataset.theme=d?'light':'dark';try{localStorage.setItem('iso-tema',r.dataset.theme)}catch(e){}};
try{const t=localStorage.getItem('iso-tema');if(t)document.documentElement.dataset.theme=t}catch(e){}
let ini='inicio';try{ini=localStorage.getItem('iso-tab')||'inicio'}catch(e){};if(!document.getElementById(ini))ini='inicio';mostrar(ini);
"""

CSS_ART = """
header{background:var(--panel);border-bottom:1px solid var(--line);padding:14px 16px}
.cab{max-width:1400px;margin:0 auto;display:flex;gap:12px;align-items:flex-start;justify-content:space-between;flex-wrap:wrap}
.aviso{background:var(--warnbg);color:var(--ink);border-left:4px solid var(--warn);padding:8px 12px;margin:10px auto 0;max-width:1400px;font-size:13.5px}
nav{position:sticky;top:0;z-index:5;background:var(--panel);border-bottom:1px solid var(--line);overflow-x:auto;white-space:nowrap;padding:0 8px}
nav button{background:none;border:0;border-bottom:3px solid transparent;color:var(--muted);font:inherit;padding:10px 10px;cursor:pointer}
nav button[aria-current="true"]{color:var(--head);border-bottom-color:var(--acc);font-weight:600}
main{max-width:1400px;margin:0 auto;padding:8px 16px 60px}
.filtros{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:8px 0}
.filtros input,.filtros select{font:inherit;padding:6px 8px;border:1px solid var(--line);border-radius:6px;background:var(--panel);color:var(--ink)}
.filtros input{flex:1;min-width:220px}.cuenta{color:var(--muted);font-size:13px}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin:12px 0}
.kpi{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px}.kpi b{display:block;font-size:1.6rem;color:var(--head)}
#tema{font:inherit;border:1px solid var(--line);background:var(--soft);color:var(--ink);border-radius:6px;padding:4px 10px;cursor:pointer}
dialog{width:min(1100px,95vw);max-height:90vh;border:1px solid var(--line);border-radius:8px;background:var(--panel);color:var(--ink);padding:0}
dialog::backdrop{background:rgba(0,0,0,.45)}.vcab{display:flex;justify-content:space-between;align-items:center;padding:8px 12px;border-bottom:1px solid var(--line)}
#visor-pre{margin:0;padding:12px;overflow:auto;max-height:78vh;font:12px/1.35 Consolas,monospace;white-space:pre}
.evlist{columns:3 260px}.evlist li{break-inside:avoid}
"""


def artefacto():
    n = resumen_numeros()
    gen = datetime.now().strftime("%Y-%m-%d %H:%M")
    inicio = f"""
<h2>Resumen</h2>
<p>{e(P['meta']['titulo'])}. Laboratorio en Oracle con datos ficticios, organizado con PHVA. Cada control ISO tiene una comprobación técnica y pruebas cuyas salidas reales se pueden abrir desde este artefacto.</p>
<div class="kpis">
<div class="kpi"><b>{len(P['riesgos'])}</b>riesgos de confidencialidad</div>
<div class="kpi"><b>{len(P['tareas'])}</b>tareas críticas del DBA</div>
<div class="kpi"><b>{n['vc_cumple']} / {len(T['observables'])}</b>comprobaciones observables en CUMPLE ({n['vc_parcial']} parcial, {n['vc_no']} no cumple)</div>
<div class="kpi"><b>{n['pr_ok']} / {n['pr_total']}</b>pruebas con el resultado esperado</div>
<div class="kpi"><b>{n['madurez']:.1f}</b>madurez promedio (0–4) · matriz: {n['mz_cumple']} cumple, {n['mz_parcial']} parcial</div>
</div>
<h3>Entorno verificado</h3>{ENTORNO}
<h3>Metodología PHVA</h3>{PHVA}
<h3>Evidencias registradas ({len(evidencias_todas)})</h3>
<ul class="evlist">{''.join(f'<li>{ev_link(x, True)}</li>' for x in evidencias_todas)}</ul>
"""
    secciones = "".join(f'<section class="pestana" id="{i}" hidden><h2>{e(t)}</h2>{inicio if c is None else c}</section>'
                        for i, t, c in bloques(True))
    botones = "".join(f'<button data-t="{i}">{e(t)}</button>' for i, t, _ in bloques(True))
    def incrustar(nombre):
        # Evita que un "</script>" dentro de la evidencia cierre la etiqueta
        return re.sub(r"</(script)", r"<\\/\1", leer_evidencia(nombre) or "", flags=re.I)
    textos = "".join(f'<script type="text/plain" id="txt-{e(x)}">{incrustar(x)}</script>'
                     for x in evidencias_todas)
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>ISO 27001 Confidencialidad Oracle</title><style>{CSS}{CSS_ART}</style></head><body>
<header><div class="cab"><div><h1>{e(P['meta']['titulo'])}</h1>
<small>{e(P['meta']['estudiante'])} · {e(P['meta']['curso'])} · {e(P['meta']['escuela'])} · Prof. {e(P['meta']['profesor'])} · {e(P['meta']['ciclo'])}</small></div>
<button id="tema" type="button">Tema claro/oscuro</button></div>
<div class="aviso"><strong>Aviso:</strong> {e(P['meta']['aviso'])} Generado el {gen} a partir de <code>evidencias/</code>.</div></header>
<nav aria-label="Secciones">{botones}</nav><main>{secciones}</main>
<dialog id="visor"><div class="vcab"><strong id="visor-titulo"></strong><button id="visor-cerrar" type="button">Cerrar</button></div><pre id="visor-pre"></pre></dialog>
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
        pdf = RAIZ / "entregables" / "Informe-ISO27001-Confidencialidad-Oracle.pdf"
        subprocess.run([str(edge), "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                        f"--print-to-pdf={pdf}", inf.as_uri()], check=False, capture_output=True, timeout=180)
        print("PDF:", pdf if pdf.exists() else "no generado")


if __name__ == "__main__":
    sys.exit(main())
