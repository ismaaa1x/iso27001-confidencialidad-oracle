#!/usr/bin/env bash
# =====================================================================
# demo.sh - Demostración en vivo para la presentación.
#
# Ejecuta, una por una y con pausa, pruebas y verificaciones que NO
# modifican el laboratorio: solo consultan, o intentan operaciones que
# Oracle debe rechazar. La salida se muestra en pantalla y NO se guarda
# en evidencias/ (las evidencias registradas no se tocan).
#
# Uso:  bash herramientas/demo.sh
# Requisito: contenedor iso27001-oracle encendido.
# =====================================================================
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"
CONTENEDOR="${CONTENEDOR:-iso27001-oracle}"

AZUL=$'\e[1;34m'; VERDE=$'\e[1;32m'; GRIS=$'\e[0;37m'; NORMAL=$'\e[0m'

# Las contraseñas del laboratorio se ocultan de la salida por precaución.
mapfile -t CLAVES < <(sed -n 's/^DEFINE pwd_[a-z_]* = "\(.*\)"$/\1/p' .secrets/lab_defines.sql)
ocultar() {
  local linea c
  while IFS= read -r linea; do
    for c in "${CLAVES[@]}"; do linea="${linea//"$c"/********}"; done
    printf '%s\n' "$linea"
  done
}

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTENEDOR"; then
  echo "El contenedor $CONTENEDOR no está encendido. Ejecute: docker start $CONTENEDOR"
  read -rp "Presione Enter para salir..." _; exit 1
fi

PASOS=(
  "ninguno|sql/30_pruebas/PR-01_vpd_vendedor_juan.sql|PR-01 · VPD: JUAN solo ve sus propios clientes|Se espera: 10 filas, todas con vendedor JUAN."
  "ninguno|sql/30_pruebas/PR-02_vpd_aislamiento_ana.sql|PR-02 · VPD: ANA no puede ver ni usar los clientes de JUAN|Se espera: el cliente 1 no existe para ANA y la venta se rechaza (ORA-20002)."
  "ninguno|sql/30_pruebas/PR-03_redaction_vendedor.sql|PR-03 · Data Redaction: el vendedor ve la tarjeta enmascarada|Se espera: cédula y correo visibles; tarjeta ****-****-****-NNNN."
  "ninguno|sql/30_pruebas/PR-04_redaction_soporte.sql|PR-04 · Data Redaction: soporte ve todo enmascarado|Se espera: cédula, correo y tarjeta enmascarados."
  "ninguno|sql/30_pruebas/PR-05_borrado_denegado.sql|PR-05 · Mínimo privilegio: JUAN no puede borrar ni modificar clientes|Se espera: rechazo por falta de privilegio (ORA-41900 en 26ai)."
  "ninguno|sql/30_pruebas/PR-07_soporte_sin_ventas.sql|PR-07 · Mínimo privilegio: soporte no tiene acceso a VENTAS|Se espera: ORA-00942 (la tabla no existe para soporte)."
  "system|sql/20_verificacion/VC-07_acceso_privilegiado.sql|VC-07 · Verificación A.8.2: cuentas con privilegios ANY|Se espera: CUMPLE (la cuenta APP_RIESGO ya fue corregida en Actuar)."
  "system|sql/20_verificacion/VC-15_seguridad_red.sql|VC-15 · Verificación A.8.20: cifrado de la conexión|Se espera: CUMPLE (AES256 / SHA256 obligatorios)."
)

clear
echo "${AZUL}=================================================================${NORMAL}"
echo "${AZUL} Demostración en vivo · Controles ISO/IEC 27001:2022 en Oracle${NORMAL}"
echo "${AZUL} Laboratorio con datos ficticios · contenedor $CONTENEDOR${NORMAL}"
echo "${AZUL}=================================================================${NORMAL}"
echo "${GRIS}La salida se muestra en pantalla; no se modifican las evidencias.${NORMAL}"
echo

total=${#PASOS[@]}; n=0
for paso in "${PASOS[@]}"; do
  IFS='|' read -r modo script titulo esperado <<<"$paso"
  n=$((n + 1))
  read -rp "[$n/$total] Presione Enter para ejecutar: $titulo " _
  echo
  echo "${AZUL}>>> $titulo${NORMAL}"
  echo "${VERDE}    $esperado${NORMAL}"
  echo "${GRIS}    Script: $script${NORMAL}"
  echo "-----------------------------------------------------------------"
  bash herramientas/ejecutar.sh "$modo" "$script" 2>&1 | ocultar
  echo "-----------------------------------------------------------------"
  echo
done

echo "${VERDE}Demostración terminada.${NORMAL}"
read -rp "Presione Enter para cerrar..." _
