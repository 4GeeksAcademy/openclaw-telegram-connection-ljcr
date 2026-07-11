#!/usr/bin/env bash
# =============================================================================
# morning-report.sh — Resumen matutino de onboarding
#
# Escanea /memory/, clasifica empleados y calcula cambios de estado respecto
# al día anterior. Diseñado para ser ejecutado como tarea programada (cron)
# o desde OpenClaw Heartbeat.
#
# Salida: Reporte estructurado listo para enviar a RRHH por Telegram.
#
# Dependencias: Bash 4.0+, jq (para formato JSON del snapshot)
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MEMORY_DIR="$WORKSPACE_DIR/memory"
LOG_DIR="$WORKSPACE_DIR/logs"
LOG_FILE="$LOG_DIR/onboarding-audit.log"
SNAPSHOT_DIR="$WORKSPACE_DIR/.snapshots"
SNAPSHOT_FILE="$SNAPSHOT_DIR/onboarding-previous.json"
DAILY_LOG="$LOG_DIR/morning-report.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TODAY=$(date -u +"%Y-%m-%d")

mkdir -p "$MEMORY_DIR" "$LOG_DIR" "$SNAPSHOT_DIR"
touch "$DAILY_LOG" "$LOG_FILE"

# --- Funciones auxiliares ----------------------------------------------------

log_event() {
    local level="$1" msg="$2"
    echo "$TIMESTAMP | $level | $msg" >> "$DAILY_LOG"
}

read_field() {
    local file="$1" field="$2"
    grep -E "^[-*] \*\*$field:\*\*" "$file" 2>/dev/null \
        | sed -E 's/^[-*] \*\*[^:]+:\*\*[[:space:]]*(.*)[[:space:]]*$/\1/' \
        | xargs
}

read_deliverable() {
    local file="$1" deliverable="$2"
    grep -E "^\s+- $deliverable:" "$file" 2>/dev/null \
        | sed -E 's/^\s+- [^:]+:[[:space:]]*(.*)[[:space:]]*$/\1/' \
        | xargs
}

# --- Escanear estado actual de empleados ------------------------------------

declare -A CURRENT
declare -A CURRENT_ENTREGABLES

NO_INICIADOS=()
AUTENTICACION=()
ACTIVOS=()
TERMINADOS=()

while IFS= read -r -d '' file; do
    name=$(read_field "$file" "Nombre")
    [ -z "$name" ] && continue

    estado=$(read_field "$file" "Estado")
    departamento=$(read_field "$file" "Departamento")

    CURRENT["$name"]="$estado"

    # Leer entregables
    nda=$(read_deliverable "$file" "NDA")
    erp=$(read_deliverable "$file" "ERP")
    sga=$(read_deliverable "$file" "SGA/Tickets")
    CURRENT_ENTREGABLES["$name"]="NDA:$nda|ERP:$erp|SGA:$sga"

    case "$estado" in
        "NO_INICIADO")   NO_INICIADOS+=("$name") ;;
        "AUTENTICACIÓN") AUTENTICACION+=("$name") ;;
        "ACTIVO")        ACTIVOS+=("$name") ;;
        "TERMINADO")     TERMINADOS+=("$name") ;;
    esac
done < <(find "$MEMORY_DIR" -name '*.md' -type f -print0 2>/dev/null || true)

# --- Comparar con snapshot del día anterior ----------------------------------

CAMBIOS_ESTADO=0
DETALLE_CAMBIOS=""

if [ -f "$SNAPSHOT_FILE" ]; then
    while IFS= read -r line; do
        prev_name="${line%%|*}"
        prev_state="${line##*|}"
        prev_name="${prev_name#name=}"
        prev_state="${prev_state#state=}"

        current_state="${CURRENT[$prev_name]-}"
        if [ -n "$current_state" ] && [ "$current_state" != "$prev_state" ]; then
            CAMBIOS_ESTADO=$((CAMBIOS_ESTADO + 1))
            DETALLE_CAMBIOS+="    • $prev_name: $prev_state → $current_state"$'\n'
        fi
    done < <(jq -r 'to_entries[] | "name=\(.key)|state=\(.value)"' "$SNAPSHOT_FILE" 2>/dev/null || true)

    while IFS= read -r -d '' file; do
        name=$(read_field "$file" "Nombre")
        [ -z "$name" ] && continue
        if ! jq -e "has(\"$name\")" "$SNAPSHOT_FILE" >/dev/null 2>&1; then
            CAMBIOS_ESTADO=$((CAMBIOS_ESTADO + 1))
            DETALLE_CAMBIOS+="    → $name: NUEVO (estado: ${CURRENT[$name]})"$'\n'
        fi
    done < <(find "$MEMORY_DIR" -name '*.md' -type f -print0 2>/dev/null || true)
else
    DETALLE_CAMBIOS="    (No hay snapshot previo — primera ejecución)"$'\n'
fi

# --- Guardar snapshot actual para mañana ------------------------------------
# Formato JSON para preservar nombres con espacios
{
    printf '{'
    first=true
    for name in "${!CURRENT[@]}"; do
        $first || printf ', '
        first=false
        # Escapar caracteres especiales para JSON
        safe_name=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
        safe_state=$(printf '%s' "${CURRENT[$name]}" | sed 's/\\/\\\\/g; s/"/\\"/g')
        printf '"%s": "%s"' "$safe_name" "$safe_state"
    done
    printf '}\n'
} > "$SNAPSHOT_FILE"

# --- Generar reporte estructurado -------------------------------------------

build_report() {
    printf '%s\n' "═══ REPORTE MATUTINO DE ONBOARDING ═══"
    printf '%s\n' "📅 $TODAY"
    printf '%s\n' ""

    printf '%s\n' "📋 No iniciados: ${#NO_INICIADOS[@]}"
    for n in "${NO_INICIADOS[@]}"; do
        printf '  • %s\n' "$n"
    done

    printf '%s\n' ""
    printf '%s\n' "🔐 Autenticación: ${#AUTENTICACION[@]}"
    for n in "${AUTENTICACION[@]}"; do
        printf '  • %s\n' "$n"
    done

    printf '%s\n' ""
    printf '%s\n' "✅ Activos: ${#ACTIVOS[@]}"
    for n in "${ACTIVOS[@]}"; do
        entregas="${CURRENT_ENTREGABLES[$n]}"
        progreso=""
        IFS='|' read -ra items <<< "$entregas"
        for item in "${items[@]}"; do
            key="${item%%:*}"
            val="${item##*:}"
            case "$val" in
                "RECIBIDO") progreso+=" ✅$key" ;;
                "PENDIENTE") progreso+=" ⏳$key" ;;
                "") progreso+=" ⏳$key" ;;
                *) progreso+=" ❓$key" ;;
            esac
        done
        printf '  • %s —%s\n' "$n" "$progreso"
    done

    printf '%s\n' ""
    printf '%s\n' "🏁 Terminados: ${#TERMINADOS[@]}"
    for n in "${TERMINADOS[@]}"; do
        printf '  • %s\n' "$n"
    done

    printf '%s\n' ""
    printf '%s\n' "📊 Cambios de estado desde ayer: $CAMBIOS_ESTADO"
    printf '%s' "$DETALLE_CAMBIOS"

    printf '%s\n' "═══════════════════════════════"
}

# --- Emitir reporte ----------------------------------------------------------
REPORTE=$(build_report)
echo "$REPORTE"
log_event "REPORTE" "Reporte matutino generado — $TODAY — Cambios: $CAMBIOS_ESTADO"

# --- Guardar copia del reporte en log diario --------------------------------
{
    echo "═══════════════════════════════════════════════════"
    echo "MORNING REPORT — $TIMESTAMP"
    echo "═══════════════════════════════════════════════════"
    echo "$REPORTE"
    echo ""
} >> "$DAILY_LOG"
