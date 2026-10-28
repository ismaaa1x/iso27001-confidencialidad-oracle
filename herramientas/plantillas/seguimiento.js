/* Módulo «Matriz y seguimiento» del artefacto (lo incrusta generar_entregables.py).
 *
 * Tres conjuntos de datos que nunca se mezclan:
 *   - D.base: evaluaciones generadas desde las evidencias reales (solo lectura).
 *   - usuario: evaluaciones registradas en esta interfaz (localStorage del navegador).
 *   - D.demo: datos de demostración ficticios (solo se ven en modo «Demostración»).
 * Las fechas se manejan como texto AAAA-MM-DD y HH:MM (hora de Costa Rica) y
 * nunca se convierten a UTC, para que no se desplacen de día.
 * Todo texto ingresado por el usuario se inserta con textContent (nunca como HTML).
 */
(function () {
  'use strict';
  const D = JSON.parse(document.getElementById('datos-seguimiento').textContent);
  const CLAVE = 'iso27001-confidencialidad-oracle.evaluaciones.v1';
  const FORMATO = 'iso27001-confidencialidad-oracle/evaluaciones';
  const ESTADOS = ['Cumple', 'Parcial', 'No cumple'];
  const SEM = { 'Cumple': ['ok', '✓'], 'Parcial': ['warn', '!'], 'No cumple': ['bad', '✕'], 'Pendiente': ['pend', '–'] };
  const CAMPOS = ['control', 'fecha', 'hora', 'madurez', 'estado', 'evidencia', 'observaciones', 'responsable'];
  const NOMBRE_CAMPO = { control: 'Control', fecha: 'Fecha', hora: 'Hora', madurez: 'Madurez', estado: 'Estado',
    evidencia: 'Evidencia', observaciones: 'Observaciones', responsable: 'Responsable' };
  const MAX_SERIES = 8;
  const CAT = new Map(D.catalogo.map(c => [c.id, c]));
  const $ = (s, r = document) => r.querySelector(s);
  const raiz = $('#sg');

  // ------------------------------------------------------------ utilidades DOM seguras
  function el(tag, attrs, ...hijos) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v == null || v === false) continue;
      if (k === 'class') n.className = v;
      else if (k === 'text') n.textContent = v;
      else if (k.startsWith('on')) n.addEventListener(k.slice(2), v);
      else n.setAttribute(k, v === true ? '' : v);
    }
    for (const h of hijos.flat()) if (h != null && h !== false) n.append(h instanceof Node ? h : document.createTextNode(String(h)));
    return n;
  }
  const SVGNS = 'http://www.w3.org/2000/svg';
  function sv(tag, attrs, ...hijos) {
    const n = document.createElementNS(SVGNS, tag);
    for (const [k, v] of Object.entries(attrs || {})) if (v != null) n.setAttribute(k, v);
    for (const h of hijos.flat()) if (h != null) n.append(h instanceof Node ? h : document.createTextNode(String(h)));
    return n;
  }
  function semaforo(estado) {
    const e = SEM[estado] ? estado : 'Pendiente';
    const [c, i] = SEM[e];
    return el('span', { class: 'sg-sem ' + c }, el('i', { 'aria-hidden': 'true', text: i }), e === 'Pendiente' ? 'Pendiente de evaluación' : e);
  }
  const origenEtq = e => e.origen === 'base' ? el('span', { class: 'sg-origen', title: 'Generada desde una evidencia real de Oracle' }, 'Base · evidencia')
    : e.origen === 'manual' ? el('span', { class: 'sg-origen manual', title: 'Registrada a mano en esta interfaz; no es una ejecución automática en Oracle' }, 'Manual')
    : el('span', { class: 'sg-origen demo' }, 'Demostración');

  // ------------------------------------------------------------ fechas (Costa Rica, sin UTC)
  const fmtCR = new Intl.DateTimeFormat('en-GB', { timeZone: 'America/Costa_Rica', year: 'numeric', month: '2-digit',
    day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' });
  function partesCR() { return Object.fromEntries(fmtCR.formatToParts(new Date()).map(p => [p.type, p.value])); }
  function hoyCR() { const p = partesCR(); return `${p.year}-${p.month}-${p.day}`; }
  function ahoraCR() { const p = partesCR(); return `${p.year}-${p.month}-${p.day} ${p.hour}:${p.minute}:${p.second}`; }
  function fechaValida(s) {
    if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
    const [y, m, d] = s.split('-').map(Number);
    const t = new Date(Date.UTC(y, m - 1, d));
    return t.getUTCFullYear() === y && t.getUTCMonth() === m - 1 && t.getUTCDate() === d;
  }
  const horaValida = s => s === '' || (typeof s === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(s));
  // Minutos desde 1970 tratando la hora de Costa Rica como reloj de pared (solo para posicionar en el eje).
  function minutos(e) {
    const [y, m, d] = e.fecha.split('-').map(Number);
    const [hh, mm] = (e.hora || '00:00').split(':').map(Number);
    return Date.UTC(y, m - 1, d, hh, mm) / 60000;
  }
  const fmtFecha = f => { const [y, m, d] = f.split('-'); return `${d}/${m}/${y}`; };
  const claveOrden = e => [e.fecha, e.hora || '', e.registrado_en || e.fecha_ejecucion || '', e.id].join(' ');
  const ordenar = l => l.slice().sort((a, b) => claveOrden(a) < claveOrden(b) ? -1 : claveOrden(a) > claveOrden(b) ? 1 : 0);

  // ------------------------------------------------------------ validación
  const texto = (v, min, max) => typeof v === 'string' && v.trim().length >= min && v.length <= max;
  function validarCampos(e) {
    const err = [];
    if (!CAT.has(e.control)) err.push('Seleccione un control del catálogo.');
    if (!fechaValida(e.fecha)) err.push('La fecha es obligatoria y debe ser válida (AAAA-MM-DD).');
    else if (e.fecha > hoyCR()) err.push('La fecha de evaluación no puede ser posterior a hoy (hora de Costa Rica).');
    if (!horaValida(e.hora ?? '')) err.push('La hora debe tener el formato HH:MM (00:00 a 23:59) o quedar vacía.');
    if (!Number.isInteger(e.madurez) || e.madurez < 0 || e.madurez > 4) err.push('La madurez es obligatoria y debe ser un entero de 0 a 4.');
    if (!ESTADOS.includes(e.estado)) err.push('El estado es obligatorio: Cumple, Parcial o No cumple.');
    if (!texto(e.evidencia, 1, 500)) err.push('La evidencia o referencia es obligatoria (máximo 500 caracteres).');
    if (!texto(e.observaciones, 1, 2000)) err.push('Las observaciones y la justificación son obligatorias (máximo 2000 caracteres).');
    if (e.responsable != null && (typeof e.responsable !== 'string' || e.responsable.length > 120)) err.push('El responsable admite como máximo 120 caracteres.');
    return err;
  }
  function validarEvaluacion(e) {
    if (!e || typeof e !== 'object') return ['registro vacío'];
    const err = validarCampos(e);
    if (typeof e.id !== 'string' || !/^man-[a-z0-9-]{4,60}$/.test(e.id)) err.push('identificador inválido');
    if (e.origen !== 'manual') err.push('solo se aceptan evaluaciones de origen «manual»');
    if (typeof e.registrado_en !== 'string') err.push('falta la fecha de registro');
    return err;
  }
  function validarRevision(r, idsEval) {
    if (!r || typeof r !== 'object') return ['revisión vacía'];
    const err = [];
    if (typeof r.id !== 'string' || !/^rev-[a-z0-9-]{4,60}$/.test(r.id)) err.push('identificador de revisión inválido');
    if (!idsEval.has(r.evaluacion_id)) err.push('la revisión apunta a una evaluación inexistente');
    if (typeof r.cambiado_en !== 'string') err.push('falta la fecha del cambio');
    if (!texto(r.motivo, 5, 500)) err.push('falta el motivo del cambio');
    for (const k of ['anterior', 'nuevo']) if (!r[k] || typeof r[k] !== 'object' || validarCampos(r[k]).length) err.push(`valores «${k}» inválidos`);
    return err;
  }
  function validarArchivo(o, idsExtra = new Set()) {
    const errores = [];
    if (!o || typeof o !== 'object') return { errores: ['El archivo no contiene un objeto JSON.'] };
    if (o.formato !== FORMATO) errores.push('Formato no reconocido: no es una exportación de este artefacto.');
    if (o.version !== 1) errores.push('Versión de formato no compatible.');
    if (!Array.isArray(o.evaluaciones) || !Array.isArray(o.revisiones)) errores.push('Faltan las listas «evaluaciones» o «revisiones».');
    if (errores.length) return { errores };
    const ids = new Set();
    o.evaluaciones.forEach((e, i) => {
      const err = validarEvaluacion(e);
      if (err.length) errores.push(`Evaluación ${i + 1}: ${err.join('; ')}`);
      else if (ids.has(e.id)) errores.push(`Evaluación ${i + 1}: identificador repetido dentro del archivo (${e.id}).`);
      else ids.add(e.id);
    });
    const todos = new Set([...ids, ...idsExtra]);
    const idsRev = new Set();
    o.revisiones.forEach((r, i) => {
      const err = validarRevision(r, todos);
      if (err.length) errores.push(`Revisión ${i + 1}: ${err.join('; ')}`);
      else if (idsRev.has(r.id)) errores.push(`Revisión ${i + 1}: identificador repetido dentro del archivo.`);
      else idsRev.add(r.id);
    });
    return { errores };
  }

  // ------------------------------------------------------------ persistencia
  let usuario = { evaluaciones: [], revisiones: [] };
  let estadoAlmacen = { ok: true, mensaje: '' };
  const avisosFijos = [];
  function nuevoId(pref) { return pref + '-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8); }
  function cargar() {
    let crudo = null;
    try { crudo = localStorage.getItem(CLAVE); }
    catch (e) {
      estadoAlmacen = { ok: false, mensaje: 'El navegador bloquea el almacenamiento local de este archivo.' };
      avisosFijos.push(['error', 'No se pueden guardar datos', 'Este navegador no permite que el artefacto guarde datos. Lo que registre se perderá al cerrar: use «Exportar JSON» antes de salir.']);
      return;
    }
    if (!crudo) return;
    try {
      const o = JSON.parse(crudo);
      const v = validarArchivo(o);
      if (v.errores.length) throw new Error(v.errores[0]);
      usuario = { evaluaciones: o.evaluaciones, revisiones: o.revisiones };
    } catch (e) {
      const respaldo = CLAVE + '.ilegible.' + Date.now();
      try { localStorage.setItem(respaldo, crudo); } catch (_) { estadoAlmacen = { ok: false, mensaje: 'No se pudo respaldar el contenido ilegible.' }; }
      avisosFijos.push(['error', 'Datos guardados ilegibles', `Las evaluaciones guardadas no se pudieron leer (${e.message}). Se conservó una copia con la clave «${respaldo}» y no se cargaron.`]);
    }
  }
  function guardar() {
    if (!estadoAlmacen.ok && estadoAlmacen.mensaje.startsWith('No se pudo respaldar')) return false;
    const obj = { formato: FORMATO, version: 1, guardado_en: ahoraCR(), evaluaciones: usuario.evaluaciones, revisiones: usuario.revisiones };
    try {
      const s = JSON.stringify(obj);
      localStorage.setItem(CLAVE, s);
      if (localStorage.getItem(CLAVE) !== s) throw new Error('la lectura de comprobación no coincide');
      estadoAlmacen = { ok: true, mensaje: '' };
      return true;
    } catch (e) {
      estadoAlmacen = { ok: false, mensaje: 'No se guardó en el navegador (' + e.message + ').' };
      return false;
    }
  }

  // ------------------------------------------------------------ estado de la interfaz
  const DEFECTO = { real: ['A.8.2', 'A.8.15'], demo: ['A.8.2', 'A.5.17', 'A.8.12', 'A.8.20'] };
  const st = { modo: 'real', desde: '', hasta: '', vista: 'resumen', hControl: '', hEstado: '', seleccion: [], detalle: null };
  function seleccionDefecto() {
    st.seleccion = [];
    DEFECTO[st.modo].forEach(c => agregarSerie(c));
  }
  function agregarSerie(c) {
    if (!CAT.has(c) || st.seleccion.some(s => s.control === c) || st.seleccion.length >= MAX_SERIES) return;
    const usados = new Set(st.seleccion.map(s => s.color));
    let color = 1; while (usados.has(color)) color++;
    st.seleccion.push({ control: c, color });
  }
  function conjunto() { return st.modo === 'demo' ? D.demo : D.base.concat(usuario.evaluaciones); }
  const periodoInvalido = () => st.desde && st.hasta && st.desde > st.hasta;
  const enPeriodo = e => (!st.desde || e.fecha >= st.desde) && (!st.hasta || e.fecha <= st.hasta);
  function delPeriodo() { return periodoInvalido() ? [] : ordenar(conjunto().filter(enPeriodo)); }
  // Número de orden dentro del día para un mismo control (distingue evaluaciones del mismo día).
  function ordenDia(lista) {
    const cuenta = new Map(), r = new Map();
    for (const e of ordenar(lista)) { const k = e.control + '|' + e.fecha; const n = (cuenta.get(k) || 0) + 1; cuenta.set(k, n); r.set(e.id, n); }
    return r;
  }

  // ------------------------------------------------------------ cálculos compartidos (matriz, gráfica e indicadores)
  function resumenPorControl(lista) {
    return D.catalogo.map(c => {
      const evs = lista.filter(e => e.control === c.id);
      const ult = evs[evs.length - 1] || null;
      const prev = evs.length > 1 ? evs[evs.length - 2] : null;
      return { c, evs, ult, prev };
    });
  }
  function indicadores(filas) {
    const ev = filas.filter(f => f.ult);
    const conMad = ev.filter(f => Number.isInteger(f.ult.madurez));
    const cuenta = est => ev.filter(f => f.ult.estado === est).length;
    return {
      total: filas.length, evaluados: ev.length, sinEval: filas.length - ev.length,
      cumple: cuenta('Cumple'), parcial: cuenta('Parcial'), no: cuenta('No cumple'),
      promedio: conMad.length ? conMad.reduce((s, f) => s + f.ult.madurez, 0) / conMad.length : null,
      conMad: conMad.length, sinMad: ev.length - conMad.length,
      registros: filas.reduce((s, f) => s + f.evs.length, 0)
    };
  }
  function tendencia(puntos) {
    if (puntos.length < 2) return { clase: '', txt: puntos.length ? 'Información insuficiente (1 evaluación con madurez)' : 'Sin evaluaciones con madurez' };
    const a = puntos[puntos.length - 2].madurez, b = puntos[puntos.length - 1].madurez;
    return b > a ? { clase: 'mejora', txt: `▲ Mejora (${a} → ${b})` } : b < a ? { clase: 'deterioro', txt: `▼ Deterioro (${a} → ${b})` } : { clase: '', txt: `● Estable (${a} → ${b})` };
  }
  function variacion(f) {
    if (!f.ult) return el('span', { class: 'sg-sin' }, '—');
    if (!f.prev) return el('span', { class: 'sg-sin' }, 'Sin evaluación anterior en el período');
    if (!Number.isInteger(f.ult.madurez) || !Number.isInteger(f.prev.madurez)) return el('span', { class: 'sg-sin' }, 'No comparable (madurez no asignada)');
    const d = f.ult.madurez - f.prev.madurez;
    return el('span', { class: 'sg-var sg-tend ' + (d > 0 ? 'mejora' : d < 0 ? 'deterioro' : '') },
      (d > 0 ? '▲ +' + d : d < 0 ? '▼ ' + d : '● 0') + ` (${f.prev.madurez} → ${f.ult.madurez})`);
  }
  const madurezTxt = e => Number.isInteger(e.madurez) ? el('span', { class: 'sg-madurez' }, String(e.madurez)) : el('span', { class: 'sg-sin', title: 'Para este momento no se asignó madurez' }, 'No asignada');
  function evidenciaNodo(e) {
    if (e.origen === 'base' && document.getElementById('txt-' + e.evidencia))
      return el('a', { href: '#', class: 'evlink', onclick: ev => { ev.preventDefault(); window.abrirEvidencia(e.evidencia); } }, e.evidencia);
    return el('span', {}, e.evidencia);
  }
  const fechaHora = e => fmtFecha(e.fecha) + (e.hora ? ' ' + e.hora : '');

  // ------------------------------------------------------------ avisos y barra
  function pintarAvisos() {
    const c = $('#sg-avisos'); c.replaceChildren();
    for (const [tipo, t, m] of avisosFijos) c.append(el('div', { class: 'sg-aviso ' + tipo, role: 'alert' }, el('b', {}, t + ':'), el('span', {}, m)));
    if (!estadoAlmacen.ok) c.append(el('div', { class: 'sg-aviso error', role: 'alert' }, el('b', {}, 'Sin guardar:'),
      el('span', {}, estadoAlmacen.mensaje + ' Exporte las evaluaciones a JSON para no perderlas.')));
    if (st.modo === 'demo') c.append(el('div', { class: 'sg-aviso demo' }, el('b', {}, 'Demostración:'), el('span', {}, D.aviso_demo)));
    const g = $('#sg-guardado');
    g.className = 'sg-guardado' + (estadoAlmacen.ok ? '' : ' error');
    g.textContent = estadoAlmacen.ok ? `Guardado en este navegador: ${usuario.evaluaciones.length} evaluación(es) manual(es) y ${usuario.revisiones.length} revisión(es).` : 'Cambios sin guardar en el navegador.';
    $('#sg-registrar').disabled = st.modo === 'demo';
    $('#sg-registrar').title = st.modo === 'demo' ? 'Cambie a «Resultados reales» para registrar evaluaciones' : '';
    $('#sg-error-periodo').textContent = periodoInvalido() ? 'La fecha «Desde» es posterior a «Hasta». Corrija el período para ver datos.' : '';
  }
  function pintarIndicadores(filas) {
    const n = indicadores(filas), c = $('#sg-ind'); c.replaceChildren();
    const pct = n.evaluados ? Math.round(n.cumple / n.evaluados * 100) + ' %' : '—';
    c.append(
      el('div', {}, el('b', {}, `${n.evaluados} / ${n.total}`), el('span', {}, `controles con evaluación en el período · ${n.sinEval} sin evaluar`)),
      el('div', {}, el('b', {}, pct), el('span', {}, `en Cumple (${n.cumple} cumple · ${n.parcial} parcial · ${n.no} no cumple)`)),
      el('div', {}, el('b', {}, n.promedio == null ? '—' : n.promedio.toFixed(1) + ' / 4'), el('span', {}, `madurez promedio de ${n.conMad} control(es)`)),
      el('div', {}, el('b', {}, String(n.registros)), el('span', {}, 'evaluaciones registradas en el período')));
    $('#sg-ind-nota').textContent = 'Los indicadores usan la última evaluación de cada control dentro del período y del conjunto de datos seleccionados. ' +
      `El porcentaje se calcula sobre los ${n.evaluados} controles evaluados y el promedio sobre los ${n.conMad} que tienen madurez asignada; ` +
      `se excluyen ${n.sinEval} control(es) sin evaluación en el período` + (n.sinMad ? ` y ${n.sinMad} con madurez no asignada.` : '.');
  }

  // ------------------------------------------------------------ vista A: resumen por control (matriz)
  function pintarResumen(filas) {
    const tb = $('#sg-t-resumen tbody'); tb.replaceChildren();
    for (const f of filas) {
      const c = f.c, u = f.ult;
      const crit = el('details', { class: 'sg-det' }, el('summary', {}, u && Number.isInteger(u.madurez) ? `Nivel ${u.madurez} (ver criterios)` : 'Ver criterios'),
        el('ol', { class: 'sg-crit', start: '0' }, c.criterios.map((t, i) => el('li', { class: u && u.madurez === i ? 'actual' : null }, el('b', {}, i + ' '), t))));
      tb.append(el('tr', {},
        el('td', {}, c.tarea), el('td', {}, c.riesgo), el('td', {}, el('b', {}, c.id), el('br'), el('small', {}, c.titulo)), el('td', {}, crit),
        el('td', {}, u ? evidenciaNodo(u) : el('span', { class: 'sg-sin' }, '—')),
        el('td', {}, u ? semaforo(u.estado) : el('span', {}, semaforo('Pendiente'), el('br'), el('small', {}, 'Sin evaluación en el período'))),
        el('td', {}, u ? fechaHora(u) : '—'), el('td', {}, u ? madurezTxt(u) : '—'), el('td', {}, variacion(f)),
        el('td', {}, u ? el('span', {}, u.observaciones) : '—', u ? el('div', {}, origenEtq(u)) : null),
        el('td', {}, el('button', { class: 'sg-btn', type: 'button', onclick: () => irHistorial(c.id) }, `Historial (${f.evs.length})`))));
    }
  }

  // ------------------------------------------------------------ vista B: historial
  function pintarHistorial(lista) {
    const sel = lista.filter(e => (!st.hControl || e.control === st.hControl) && (!st.hEstado || e.estado === st.hEstado)).reverse();
    const od = ordenDia(conjunto());
    const tb = $('#sg-t-historial tbody'); tb.replaceChildren();
    const revs = id => usuario.revisiones.filter(r => r.evaluacion_id === id);
    for (const e of sel) {
      const c = CAT.get(e.control), nr = revs(e.id).length;
      tb.append(el('tr', {},
        el('td', {}, fmtFecha(e.fecha)), el('td', {}, e.hora || el('span', { class: 'sg-sin' }, '—')), el('td', { title: 'Orden dentro del día para este control' }, '#' + od.get(e.id)),
        el('td', {}, el('b', {}, e.control), el('br'), el('small', {}, c ? c.titulo : '')), el('td', {}, madurezTxt(e)), el('td', {}, semaforo(e.estado)),
        el('td', {}, origenEtq(e), e.origen === 'base' && e.resultado_vc ? el('div', {}, el('small', {}, `Script: ${e.resultado_vc} · ejecutado ${e.fecha_ejecucion}`)) : null,
          e.origen === 'manual' ? el('div', {}, el('small', {}, 'Registrada el ' + e.registrado_en)) : null),
        el('td', {}, evidenciaNodo(e)), el('td', {}, e.observaciones), el('td', {}, e.responsable || el('span', { class: 'sg-sin' }, '—')),
        el('td', {}, e.origen === 'manual'
          ? [el('button', { class: 'sg-btn', type: 'button', onclick: () => abrirForm(e) }, 'Corregir'), ' ',
             nr ? el('button', { class: 'sg-btn', type: 'button', onclick: () => verRevisiones(e) }, `Revisiones (${nr})`) : el('small', { class: 'sg-sin' }, 'Sin revisiones')]
          : el('small', { class: 'sg-sin' }, e.origen === 'base' ? 'Solo lectura (se corrige en la fuente y se regenera)' : 'Solo lectura'))));
    }
    $('#sg-h-cuenta').textContent = `${sel.length} evaluación(es)` + (sel.length ? '' : ' para los filtros elegidos');
  }
  function irHistorial(control) {
    st.hControl = control; $('#sg-h-control').value = control; cambiarVista('historial');
  }

  // ------------------------------------------------------------ vista C: evolución
  const tip = el('div', { class: 'sg-tip', hidden: true, role: 'tooltip' });
  document.body.append(tip);
  function fichaEvaluacion(e, color) {
    const c = CAT.get(e.control);
    return [el('div', { class: 't' }, el('span', { class: 'sg-linea', style: `background:var(--cat-${color})` }), `${e.control} · ${c ? c.titulo : ''}`),
      el('dl', {}, el('dt', {}, 'Fecha'), el('dd', {}, fechaHora(e)), el('dt', {}, 'Madurez'), el('dd', {}, `${e.madurez} de 4`),
        el('dt', {}, 'Estado'), el('dd', {}, semaforo(e.estado)), el('dt', {}, 'Origen'), el('dd', {}, origenEtq(e)),
        el('dt', {}, 'Evidencia'), el('dd', {}, evidenciaNodo(e)), el('dt', {}, 'Observaciones'), el('dd', {}, e.observaciones))];
  }
  function mostrarTip(e, color, x, y) {
    tip.replaceChildren(...fichaEvaluacion(e, color)); tip.hidden = false;
    const w = tip.offsetWidth, h = tip.offsetHeight;
    tip.style.left = Math.max(8, Math.min(innerWidth - w - 8, x + 14)) + 'px';
    tip.style.top = Math.max(8, y + h + 20 > innerHeight ? y - h - 14 : y + 14) + 'px';
  }
  function pasoTicks(rango) {
    const pasos = [1, 5, 15, 30, 60, 180, 360, 720, 1440, 2880, 10080, 20160, 43200, 86400, 129600, 525600];
    return pasos.find(p => rango / p <= 7) || pasos[pasos.length - 1];
  }
  function etiquetaTick(m, paso) {
    const d = new Date(m * 60000), dd = String(d.getUTCDate()).padStart(2, '0'), mo = String(d.getUTCMonth() + 1).padStart(2, '0');
    if (paso < 1440) return `${dd}/${mo} ${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`;
    return `${dd}/${mo}/${d.getUTCFullYear()}`;
  }
  function pintarEvolucion(lista) {
    // Selector y chips
    const chips = $('#sg-chips'); chips.replaceChildren();
    for (const s of st.seleccion) {
      const c = CAT.get(s.control);
      chips.append(el('span', { class: 'sg-chip' }, el('span', { class: 'sg-linea', style: `background:var(--cat-${s.color})`, 'aria-hidden': 'true' }),
        el('span', {}, el('b', {}, s.control), ' ', c.titulo),
        el('button', { class: 'sg-quitar', type: 'button', 'aria-label': `Quitar ${s.control} de la gráfica`,
          onclick: () => { st.seleccion = st.seleccion.filter(x => x !== s); if (st.detalle && st.detalle.control === s.control) st.detalle = null; pintar(); } }, 'Quitar ✕')));
    }
    $('#sg-agregar').disabled = st.seleccion.length >= MAX_SERIES;
    $('#sg-limite').textContent = st.seleccion.length >= MAX_SERIES ? `Máximo ${MAX_SERIES} controles a la vez: quite uno para agregar otro.` : '';

    const g = $('#sg-grafica'), msg = $('#sg-msg-grafica'), tend = $('#sg-t-tendencia tbody');
    g.replaceChildren(); msg.replaceChildren(); tend.replaceChildren();
    const mensaje = t => msg.append(el('div', { class: 'sg-mensaje', role: 'status' }, t));
    if (periodoInvalido()) { mensaje('La fecha «Desde» es posterior a «Hasta». Corrija el período.'); pintarDetalle(); return; }
    if (!st.seleccion.length) { mensaje('No hay controles seleccionados. Elija un control y presione «Agregar a la gráfica».'); pintarDetalle(); return; }

    const series = st.seleccion.map(s => {
      const evs = lista.filter(e => e.control === s.control);
      return { ...s, evs, puntos: evs.filter(e => Number.isInteger(e.madurez)) };
    });
    for (const s of series) {
      const t = tendencia(s.puntos), p = s.puntos;
      tend.append(el('tr', {}, el('td', {}, el('span', { class: 'sg-linea', style: `background:var(--cat-${s.color})` }), ' ', el('b', {}, s.control)),
        el('td', {}, String(s.evs.length)), el('td', {}, String(p.length)),
        el('td', {}, p.length ? `${fechaHora(p[0])} · ${p[0].madurez}` : '—'), el('td', {}, p.length ? `${fechaHora(p[p.length - 1])} · ${p[p.length - 1].madurez}` : '—'),
        el('td', {}, el('span', { class: 'sg-tend ' + t.clase }, t.txt))));
    }
    const todos = series.flatMap(s => s.puntos.map(e => ({ e, s })));
    const sinMad = series.reduce((n, s) => n + s.evs.length - s.puntos.length, 0);
    if (sinMad) mensaje(`${sinMad} evaluación(es) del período no tienen madurez asignada y no se grafican; aparecen en la tabla de abajo y en el Historial.`);
    const vacias = series.filter(s => !s.evs.length).map(s => s.control);
    if (vacias.length && vacias.length < series.length) mensaje('Sin evaluaciones en el período para: ' + vacias.join(', ') + '.');
    if (!todos.length) { mensaje('No hay evaluaciones con madurez en el período para los controles seleccionados. Cambie las fechas o use «Restablecer».'); pintarDetalle(); return; }
    if (todos.length === 1) mensaje('Solo existe una evaluación en el período: se muestra el punto, pero no hay información suficiente para determinar una tendencia.');

    // Escalas
    const W = Math.max(320, g.clientWidth || 800), H = 300, m = { i: 46, d: 70, s: 14, b: 40 };
    const xs = todos.map(t => minutos(t.e));
    let x0 = Math.min(...xs), x1 = Math.max(...xs);
    const pad = Math.max((x1 - x0) * 0.06, 2);
    x0 -= pad; x1 += pad;
    const X = v => m.i + (v - x0) / (x1 - x0) * (W - m.i - m.d);
    const Y = v => m.s + (4 - v) / 4 * (H - m.s - m.b);
    const svg = sv('svg', { viewBox: `0 0 ${W} ${H}`, role: 'img', 'aria-label': 'Evolución de la madurez de los controles seleccionados' });
    const rej = sv('g', { class: 'rejilla' }), eje = sv('g', { class: 'eje' });
    for (let v = 0; v <= 4; v++) { rej.append(sv('line', { x1: m.i, x2: W - m.d, y1: Y(v), y2: Y(v) })); eje.append(sv('text', { x: m.i - 10, y: Y(v) + 4, 'text-anchor': 'end' }, String(v))); }
    eje.append(sv('text', { x: 12, y: (H - m.b) / 2, transform: `rotate(-90 12 ${(H - m.b) / 2})`, 'text-anchor': 'middle' }, 'Madurez (0–4)'));
    const paso = pasoTicks(x1 - x0);
    for (let t = Math.ceil(x0 / paso) * paso; t <= x1; t += paso) {
      rej.append(sv('line', { x1: X(t), x2: X(t), y1: m.s, y2: H - m.b, 'stroke-dasharray': '2 4' }));
      eje.append(sv('text', { x: X(t), y: H - m.b + 18, 'text-anchor': 'middle' }, etiquetaTick(t, paso)));
    }
    svg.append(rej, sv('line', { class: 'base', x1: m.i, x2: W - m.d, y1: Y(0), y2: Y(0) }), eje);
    for (const s of series) {
      if (!s.puntos.length) continue;
      const col = `var(--cat-${s.color})`;
      if (s.puntos.length > 1) svg.append(sv('polyline', { class: 'serie', stroke: col, points: s.puntos.map(e => `${X(minutos(e))},${Y(e.madurez)}`).join(' ') }));
      const ult = s.puntos[s.puntos.length - 1];
      svg.append(sv('text', { class: 'sg-etq', x: X(minutos(ult)) + 9, y: Y(ult.madurez) - 7 }, s.control));
      for (const e of s.puntos) {
        const p = sv('g', { class: 'sg-punto' + (st.detalle && st.detalle.id === e.id ? ' activo' : ''), tabindex: '0', role: 'button',
          'aria-label': `${e.control}, ${fechaHora(e)}, madurez ${e.madurez}, ${e.estado}` },
          sv('circle', { class: 'area', cx: X(minutos(e)), cy: Y(e.madurez), r: 13 }),
          sv('circle', { class: 'marca', cx: X(minutos(e)), cy: Y(e.madurez), r: 5.5, fill: col }));
        const abrir = () => { st.detalle = { id: e.id, control: e.control }; pintarEvolucion(lista); };
        p.addEventListener('pointerenter', ev => mostrarTip(e, s.color, ev.clientX, ev.clientY));
        p.addEventListener('pointermove', ev => mostrarTip(e, s.color, ev.clientX, ev.clientY));
        p.addEventListener('pointerleave', () => { tip.hidden = true; });
        p.addEventListener('focus', () => { const r = p.getBoundingClientRect(); mostrarTip(e, s.color, r.right, r.top); });
        p.addEventListener('blur', () => { tip.hidden = true; });
        p.addEventListener('click', abrir);
        p.addEventListener('keydown', ev => { if (ev.key === 'Enter' || ev.key === ' ') { ev.preventDefault(); abrir(); } });
        svg.append(p);
      }
    }
    g.append(svg);
    pintarDetalle(series);
  }
  function pintarDetalle(series) {
    const c = $('#sg-detalle'); c.replaceChildren();
    if (!st.detalle || !series) return;
    const s = series.find(x => x.control === st.detalle.control);
    const e = s && s.puntos.find(x => x.id === st.detalle.id);
    if (!e) return;
    c.append(el('strong', {}, 'Punto seleccionado'), ...fichaEvaluacion(e, s.color));
  }

  // ------------------------------------------------------------ formulario de registro y corrección
  let editando = null;
  function opcionesControl(sel) {
    sel.replaceChildren(el('option', { value: '' }, 'Seleccione un control…'), ...D.catalogo.map(c => el('option', { value: c.id }, `${c.id} — ${c.titulo}`)));
  }
  function guiaCriterios() {
    const c = CAT.get($('#sg-f-control').value), g = $('#sg-f-guia'); g.replaceChildren();
    if (!c) return;
    g.append(el('div', { class: 'sg-ayuda' }, 'Criterios de madurez de este control (guía para evaluar):'),
      el('ol', { class: 'sg-crit', start: '0' }, c.criterios.map((t, i) => el('li', {}, el('b', {}, i + ' '), t))));
  }
  function abrirForm(ev) {
    editando = ev || null;
    const f = $('#sg-form');
    f.reset(); $('#sg-f-errores').replaceChildren();
    $('#sg-f-titulo').textContent = ev ? `Corregir evaluación ${ev.control} del ${fmtFecha(ev.fecha)}` : 'Registrar evaluación';
    $('#sg-f-motivo-campo').hidden = !ev;
    $('#sg-f-motivo').required = !!ev;
    $('#sg-f-control').value = ev ? ev.control : (st.hControl || '');
    $('#sg-f-fecha').value = ev ? ev.fecha : hoyCR();
    $('#sg-f-fecha').max = hoyCR();
    $('#sg-f-hora').value = ev ? ev.hora : '';
    $('#sg-f-madurez').value = ev ? String(ev.madurez) : '';
    $('#sg-f-estado').value = ev ? ev.estado : '';
    $('#sg-f-evidencia').value = ev ? ev.evidencia : '';
    $('#sg-f-observaciones').value = ev ? ev.observaciones : '';
    $('#sg-f-responsable').value = ev ? (ev.responsable || '') : '';
    guiaCriterios();
    $('#sg-dlg-form').showModal();
    $('#sg-f-control').focus();
  }
  function leerForm() {
    const m = $('#sg-f-madurez').value;
    return { control: $('#sg-f-control').value, fecha: $('#sg-f-fecha').value, hora: $('#sg-f-hora').value,
      madurez: m === '' ? null : Number(m), estado: $('#sg-f-estado').value, evidencia: $('#sg-f-evidencia').value.trim(),
      observaciones: $('#sg-f-observaciones').value.trim(), responsable: $('#sg-f-responsable').value.trim() };
  }
  function errores(lista) {
    const ul = $('#sg-f-errores'); ul.replaceChildren(...lista.map(t => el('li', {}, t)));
    if (lista.length) ul.focus();
  }
  function enviarForm(ev) {
    ev.preventDefault();
    const datos = leerForm(), err = validarCampos(datos);
    if (editando) {
      const motivo = $('#sg-f-motivo').value.trim();
      if (motivo.length < 5) err.push('Indique el motivo de la corrección (al menos 5 caracteres).');
      const cambia = CAMPOS.some(k => (datos[k] ?? '') !== (editando[k] ?? ''));
      if (!cambia) err.push('No cambió ningún valor: no hay nada que corregir.');
      if (err.length) return errores(err);
      const anterior = Object.fromEntries(CAMPOS.map(k => [k, editando[k] ?? '']));
      usuario.revisiones.push({ id: nuevoId('rev'), evaluacion_id: editando.id, cambiado_en: ahoraCR(), motivo, anterior, nuevo: { ...datos } });
      Object.assign(editando, datos, { modificado_en: ahoraCR() });
    } else {
      if (err.length) return errores(err);
      usuario.evaluaciones.push({ id: nuevoId('man'), origen: 'manual', ...datos, registrado_en: ahoraCR() });
      if (!st.seleccion.some(s => s.control === datos.control)) agregarSerie(datos.control);
    }
    guardar();
    $('#sg-dlg-form').close();
    pintar();
  }
  function verRevisiones(e) {
    const c = $('#sg-rev-cuerpo'); c.replaceChildren();
    $('#sg-rev-titulo').textContent = `Revisiones de ${e.control} (${fmtFecha(e.fecha)})`;
    const lista = usuario.revisiones.filter(r => r.evaluacion_id === e.id).sort((a, b) => a.cambiado_en < b.cambiado_en ? -1 : 1);
    lista.forEach((r, i) => {
      const filas = CAMPOS.filter(k => String(r.anterior[k] ?? '') !== String(r.nuevo[k] ?? ''))
        .map(k => el('tr', {}, el('td', {}, NOMBRE_CAMPO[k]), el('td', {}, String(r.anterior[k] ?? '')), el('td', {}, String(r.nuevo[k] ?? ''))));
      c.append(el('div', { class: 'sg-rev' }, el('div', {}, el('b', {}, `Revisión ${i + 1}`), ` · cambiada el ${r.cambiado_en}`),
        el('div', {}, 'Motivo: ', el('span', {}, r.motivo)),
        el('table', {}, el('thead', {}, el('tr', {}, el('th', {}, 'Campo'), el('th', {}, 'Valor anterior'), el('th', {}, 'Valor nuevo'))), el('tbody', {}, filas))));
    });
    c.append(el('p', { class: 'sg-ayuda', style: 'margin:0 16px 14px' }, 'Este historial se guarda en el navegador y sirve para rastrear correcciones de captura. No es un registro de auditoría inviolable: quien controle el equipo puede borrarlo o editarlo.'));
    $('#sg-dlg-rev').showModal();
  }

  // ------------------------------------------------------------ exportar / importar
  function datosExportacion() {
    return { formato: FORMATO, version: 1, exportado_en: ahoraCR() + ' (America/Costa_Rica)',
      nota: 'Evaluaciones registradas manualmente en el artefacto y sus revisiones. No incluye los datos base ni los de demostración.',
      evaluaciones: usuario.evaluaciones, revisiones: usuario.revisiones };
  }
  function exportar() {
    const blob = new Blob([JSON.stringify(datosExportacion(), null, 2)], { type: 'application/json' });
    const a = el('a', { href: URL.createObjectURL(blob), download: `evaluaciones-iso27001-${ahoraCR().slice(0, 16).replace(/[-: ]/g, '')}.json` });
    document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  }
  // Fusiona sin reemplazar: los identificadores existentes nunca se sobrescriben.
  function importarTexto(txt) {
    let o;
    try { o = JSON.parse(txt); } catch (e) { return { ok: false, mensaje: 'El archivo no es JSON válido.' }; }
    const v = validarArchivo(o, new Set(usuario.evaluaciones.map(e => e.id)));
    if (v.errores.length) return { ok: false, mensaje: 'Archivo rechazado. ' + v.errores.slice(0, 5).join(' ') + (v.errores.length > 5 ? ` (y ${v.errores.length - 5} error(es) más)` : '') };
    const igual = (a, b) => JSON.stringify(a) === JSON.stringify(b);
    const r = { nuevasE: [], dupE: 0, confE: [], nuevasR: [], dupR: 0, confR: [] };
    for (const e of o.evaluaciones) {
      const ex = usuario.evaluaciones.find(x => x.id === e.id);
      if (!ex) r.nuevasE.push(e); else if (igual(ex, e)) r.dupE++; else r.confE.push(e.id);
    }
    for (const x of o.revisiones) {
      const ex = usuario.revisiones.find(y => y.id === x.id);
      if (!ex) r.nuevasR.push(x); else if (igual(ex, x)) r.dupR++; else r.confR.push(x.id);
    }
    return { ok: true, r };
  }
  function aplicarImportacion(r) {
    usuario.evaluaciones.push(...r.nuevasE.map(e => structuredClone(e)));
    usuario.revisiones.push(...r.nuevasR.map(x => structuredClone(x)));
    // Evaluaciones existentes que el archivo trae con otro contenido: se conservan las locales.
    return guardar();
  }
  function resumenImportacion(r) {
    return `Evaluaciones: ${r.nuevasE.length} nuevas, ${r.dupE} duplicadas (se omiten), ${r.confE.length} en conflicto (se conservan las actuales). ` +
      `Revisiones: ${r.nuevasR.length} nuevas, ${r.dupR} duplicadas, ${r.confR.length} en conflicto.` +
      (r.confE.length ? ' Conflictos: ' + r.confE.join(', ') + '.' : '');
  }
  function mostrarResultado(tipo, titulo, txt) {
    const c = $('#sg-resultado'); c.replaceChildren(el('div', { class: 'sg-aviso ' + tipo, role: 'status' }, el('b', {}, titulo + ':'), el('span', {}, txt)));
  }
  function importarArchivo(file) {
    const lector = new FileReader();
    lector.onload = () => {
      const res = importarTexto(String(lector.result));
      if (!res.ok) return mostrarResultado('error', 'Importación rechazada', res.mensaje);
      const txt = resumenImportacion(res.r);
      if (!res.r.nuevasE.length && !res.r.nuevasR.length) return mostrarResultado('ok', 'Nada que importar', txt);
      if (!confirm('Se agregarán los registros nuevos sin reemplazar los existentes.\n\n' + txt + '\n\n¿Continuar?')) return mostrarResultado('ok', 'Importación cancelada', txt);
      const ok = aplicarImportacion(res.r);
      pintar();
      mostrarResultado(ok ? 'ok' : 'error', ok ? 'Importación completada' : 'Importado, pero sin guardar', txt);
    };
    lector.onerror = () => mostrarResultado('error', 'Importación rechazada', 'No se pudo leer el archivo.');
    lector.readAsText(file);
  }

  // ------------------------------------------------------------ pintar todo con los mismos registros y filtros
  function cambiarVista(v) {
    st.vista = v;
    for (const b of raiz.querySelectorAll('.sg-tab')) { const on = b.dataset.vista === v; b.setAttribute('aria-selected', on); b.tabIndex = on ? 0 : -1; }
    for (const p of raiz.querySelectorAll('[data-panel]')) p.hidden = p.dataset.panel !== v;
    pintar();
  }
  function pintar() {
    const lista = delPeriodo(), filas = resumenPorControl(lista);
    pintarAvisos(); pintarIndicadores(filas);
    if (st.vista === 'resumen') pintarResumen(filas);
    if (st.vista === 'historial') pintarHistorial(lista);
    if (st.vista === 'evolucion') pintarEvolucion(lista);
  }

  // ------------------------------------------------------------ eventos
  cargar();
  opcionesControl($('#sg-f-control'));
  opcionesControl($('#sg-agregar-control'));
  const hc = $('#sg-h-control');
  hc.replaceChildren(el('option', { value: '' }, 'Todos los controles'), ...D.catalogo.map(c => el('option', { value: c.id }, `${c.id} — ${c.titulo}`)));
  $('#sg-generado').textContent = D.generado_en;
  for (const r of raiz.querySelectorAll('input[name="sg-modo"]')) r.addEventListener('change', () => { st.modo = r.value; st.detalle = null; seleccionDefecto(); pintar(); });
  $('#sg-desde').addEventListener('change', e => { st.desde = e.target.value; pintar(); });
  $('#sg-hasta').addEventListener('change', e => { st.hasta = e.target.value; pintar(); });
  $('#sg-restablecer').addEventListener('click', () => {
    st.desde = st.hasta = st.hControl = st.hEstado = ''; st.detalle = null;
    $('#sg-desde').value = $('#sg-hasta').value = $('#sg-h-control').value = $('#sg-h-estado').value = '';
    seleccionDefecto(); pintar();
  });
  hc.addEventListener('change', e => { st.hControl = e.target.value; pintar(); });
  $('#sg-h-estado').addEventListener('change', e => { st.hEstado = e.target.value; pintar(); });
  $('#sg-agregar').addEventListener('click', () => {
    const c = $('#sg-agregar-control').value;
    if (!c) return mostrarResultado('error', 'Agregar a la gráfica', 'Seleccione primero un control.');
    if (st.seleccion.some(s => s.control === c)) return mostrarResultado('ok', 'Agregar a la gráfica', `${c} ya está en la gráfica.`);
    agregarSerie(c); $('#sg-resultado').replaceChildren(); pintar();
  });
  $('#sg-quitar-todos').addEventListener('click', () => { st.seleccion = []; st.detalle = null; pintar(); });
  $('#sg-historial-completo').addEventListener('click', () => {
    st.desde = st.hasta = ''; $('#sg-desde').value = $('#sg-hasta').value = '';
    irHistorial(st.seleccion.length === 1 ? st.seleccion[0].control : '');
  });
  $('#sg-registrar').addEventListener('click', () => abrirForm(null));
  $('#sg-exportar').addEventListener('click', exportar);
  $('#sg-importar').addEventListener('click', () => $('#sg-archivo').click());
  $('#sg-archivo').addEventListener('change', e => { const f = e.target.files[0]; if (f) importarArchivo(f); e.target.value = ''; });
  $('#sg-form').addEventListener('submit', enviarForm);
  $('#sg-f-control').addEventListener('change', guiaCriterios);
  $('#sg-f-cancelar').addEventListener('click', () => $('#sg-dlg-form').close());
  $('#sg-rev-cerrar').addEventListener('click', () => $('#sg-dlg-rev').close());
  const tabs = [...raiz.querySelectorAll('.sg-tab')];
  tabs.forEach((b, i) => {
    b.addEventListener('click', () => cambiarVista(b.dataset.vista));
    b.addEventListener('keydown', ev => {
      const d = ev.key === 'ArrowRight' ? 1 : ev.key === 'ArrowLeft' ? -1 : 0;
      if (d) { const t = tabs[(i + d + tabs.length) % tabs.length]; t.focus(); cambiarVista(t.dataset.vista); }
    });
  });
  let pendiente = 0;
  addEventListener('resize', () => { cancelAnimationFrame(pendiente); pendiente = requestAnimationFrame(() => { if (st.vista === 'evolucion') pintar(); }); });
  // La gráfica necesita el ancho real: se repinta al mostrar la sección.
  new MutationObserver(() => { if (!raiz.closest('.pestana').hidden) pintar(); }).observe(raiz.closest('.pestana'), { attributes: true, attributeFilter: ['hidden'] });
  seleccionDefecto();
  cambiarVista('resumen');

  // Interfaz mínima para las pruebas automatizadas del artefacto (no modifica datos por sí sola).
  window.SG = { st, pintar, cambiarVista, agregarSerie, abrirForm, enviarForm, importarTexto, aplicarImportacion, datosExportacion,
    usuario: () => usuario, estadoAlmacen: () => estadoAlmacen, delPeriodo, resumenPorControl, indicadores, CLAVE };
})();
