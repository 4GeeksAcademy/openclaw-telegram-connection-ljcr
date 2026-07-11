#!/usr/bin/env bash
# =============================================================================
# close-onboarding.sh — Lógica de cierre de proceso de onboarding
#
# Verifica que se hayan recibido todos los entregables de un empleado y,
# de ser así, cambia su estado a TERMINADO. Puede ejecutarse:
#   - Manualmente: close-onboarding.sh "Nombre Completo"
#   - Como barrido: close-onboarding.sh --scan
#   - Por entregable: close-onboarding.sh "Nombre" --deliverable "NDA"
#
# Dependencias: Bash 4.0+
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MEMORY_DIR="$WORKSPACE_DIR/memory"
LOG_DIR="$WORKSPACE_DIR/logs"
LOG_FILE="$LOG_DIR/onboarding-audit.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$MEMORY_DIR" "$LOG_DIR"
touch "$LOG_FILE"

# --- Funciones auxiliares ----------------------------------------------------

log_event() {
    local level="$1" msg="$2"
    echo "$TIMESTAMP | $level | $msg" >> "$LOG_FILE"
    echo "$TIMESTAMP | $level | $msg"
}

fail() { log_event "ERROR" "$1"; exit 1; }

slugify() {
    echo "$1" \
        | sed 's/[áàäâ]/a/g; s/[éèëê]/e/g; s/[íìïî]/i/g; s/[óòöô]/o/g; s/[úùüû]/u/g; s/[ñ]/n/g; s/[ç]/c/g' \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]/-/g' \
        | sed 's/--*/-/g' \
        | sed 's/^-//;s/-$//'
}

employee_file() {
    local name="$1"
    local file="$MEMORY_DIR/$(slugify "$name").md"
    if [ ! -f "$file" ]; then
        # Fallback: buscar por nombre en todo /memory/
        while IFS= read -r -d '' f; do
            stored_name=$(grep -E "^\*\*Nombre:\*\*|^- \*\*Nombre:\*\*" "$f" 2>/dev/null \
                | sed -E 's/^[-*] \*\*Nombre:\*\*[[:space:]]*(.*)[[:space:]]*$/\1/' \
                | xargs)
            if [ "$stored_name" = "$name" ]; then
                echo "$f"
                return
            fi
        done < <(find "$MEMORY_DIR" -name '*.md' -print0 2>/dev/null)
        echo "$file"  # devuelve ruta aunque no exista, fail() atrapará luego
    else
        echo "$file"
    fi
}

read_field() {
    local file="$1" field="$2"
    grep -E "^[-*] \*\*$field:\*\*" "$file" 2>/dev/null \
        | sed -E 's/^[-*] \*\*[^:]+:\*\*[[:space:]]*(.*)[[:space:]]*$/\1/' \
        | xargs
}

write_field() {
    local file="$1" field="$2" value="$3"
    if grep -qE "^[-*] \*\*$field:\*\*" "$file" 2>/dev/null; then
        sed -i -E "s/^[-*] \*\*$field:\*\*.*$/- **$field:** $value/" "$file"
    fi
}

read_deliverable() {
    local file="$1" deliv="$2"
    grep -E "^\s+- $deliv:" "$file" 2>/dev/null \
        | sed -E 's/^\s+- [^:]+:[[:space:]]*(.*)[[:space:]]*$/\1/' \
        | xargs
}

write_deliverable() {
    local file="$1" deliv="$2" value="$3"
    if grep -qE "^[[:space:]]+- $deliv:" "$file" 2>/dev/null; then
        # Usar | como delimitador de sed para evitar conflictos con / en el nombre
        sed -i -E "s|^([[:space:]]+- $deliv:).*$|\1 $value|" "$file"
    fi
}

# =============================================================================
# Verificar entregables de un empleado
# =============================================================================
#
# Lee cada entregable del archivo y retorna 0 si todos están RECIBIDO.
# Si algún entregable está PENDIENTE, retorna 1 e imprime los pendientes.

check_deliverables() {
    local file="$1" name="$2"
    local all_received=true
    local pendientes=()

    for deliv in NDA ERP "SGA/Tickets"; do
        status=$(read_deliverable "$file" "$deliv")
        case "$status" in
            "RECIBIDO") ;;
            "PENDIENTE"|"")
                all_received=false
                pendientes+=("$deliv")
                ;;
            *)
                all_received=false
                pendientes+=("$deliv ($status)")
                ;;
        esac
    done

    if $all_received; then
        return 0
    else
        echo "PENDIENTES: ${pendientes[*]}"
        return 1
    fi
}

# =============================================================================
# COMANDO: close "Nombre Completo"
#
# Verifica si todos los entregables del empleado están RECIBIDO.
# Si es así, actualiza el estado a TERMINADO y registra en log.

cmd_close() {
    local name="$1"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no encontrado en $MEMORY_DIR"

    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "ACTIVO" ] && [ "$estado" != "TERMINADO" ] && \
        fail "Empleado '$name' debe estar ACTIVO o TERMINADO (actual: $estado)"

    if [ "$estado" = "TERMINADO" ]; then
        log_event "INFO" "Empleado '$name' ya está TERMINADO — sin cambios"
        return 0
    fi

    if check_deliverables "$file" "$name"; then
        write_field "$file" "Estado" "TERMINADO"
        write_field "$file" "Última Actualización" "$TIMESTAMP"

        log_event "CIERRE" "Empleado '$name' completó todos los entregables → TERMINADO"

        echo "✅ '$name' ha completado todos los entregables."
        echo "Estado actualizado a: TERMINADO"

        # Mostrar resumen final
        echo ""
        echo "═══════════════════════════════════════════════════"
        echo "  CERTIFICADO DE ONBOARDING COMPLETO"
        echo "═══════════════════════════════════════════════════"
        echo "  Empleado:    $name"
        echo "  Fecha cierre: $TIMESTAMP"
        echo "───────────────────────────────────────────────────"
        echo "  ✓ NDA: RECIBIDO"
        echo "  ✓ ERP: RECIBIDO"
        echo "  ✓ SGA/Tickets: RECIBIDO"
        echo "═══════════════════════════════════════════════════"

        return 0
    else
        log_event "INFO" "Empleado '$name' aún tiene entregables pendientes"
        return 1
    fi
}

# =============================================================================
# COMANDO: deliverable "Nombre Completo" --deliverable "NDA" [--value RECIBIDO]
#
# Actualiza el estado de un entregable específico.
# Si tras la actualización todos los entregables están completos, ejecuta
# automáticamente el cierre.

cmd_deliverable() {
    local name="$1" deliv="$2" new_value="${3:-RECIBIDO}"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no encontrado"

    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "ACTIVO" ] && [ "$estado" != "TERMINADO" ] && \
        fail "Empleado '$name' debe estar ACTIVO o TERMINADO (actual: $estado)"

    local current; current=$(read_deliverable "$file" "$deliv")
    [ "$current" = "$new_value" ] && log_event "INFO" "Entregable '$deliv' de '$name' ya está $new_value" && return 0

    write_deliverable "$file" "$deliv" "$new_value"
    write_field "$file" "Última Actualización" "$TIMESTAMP"
    log_event "ENTREGABLE" "Empleado '$name' — $deliv: $current → $new_value"
    echo "✅ $deliv de '$name' actualizado a: $new_value"

    # Verificar si ya puede cerrarse
    if [ "$estado" = "ACTIVO" ]; then
        if check_deliverables "$file" "$name" >/dev/null 2>&1; then
            echo "🎉 Todos los entregables completos. Cerrando onboarding..."
            cmd_close "$name" || true
        else
            pendings=$(check_deliverables "$file" "$name" 2>&1 || true)
            echo "📋 Entregables aún pendientes: $pendings"
        fi
    fi
}

# =============================================================================
# COMANDO: --scan
#
# Barre todos los empleados ACTIVOS, verifica entregables y cierra los que
# estén completos. Útil como rutina programada (cron/heartbeat).

cmd_scan() {
    local cerrados=0
    local total=0

    echo "═══════════════════════════════════════════════════"
    echo "  BARRIDO DE CIERRE — $(date -u +'%Y-%m-%d %H:%M UTC')"
    echo "═══════════════════════════════════════════════════"
    echo ""

    while IFS= read -r -d '' file; do
        name=$(read_field "$file" "Nombre")
        estado=$(read_field "$file" "Estado")

        if [ "$estado" != "ACTIVO" ]; then
            continue
        fi

        total=$((total + 1))

        if check_deliverables "$file" "$name" >/dev/null 2>&1; then
            echo "🔍 $name — Todos los entregables completos"
            cmd_close "$name" || true
            cerrados=$((cerrados + 1))
        else
            pendings=$(check_deliverables "$file" "$name" 2>&1 || true)
            echo "⏳ $name — Pendientes: $pendings"
        fi
    done < <(find "$MEMORY_DIR" -name '*.md' -type f -print0 2>/dev/null)

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  RESUMEN"
    echo "───────────────────────────────────────────────────"
    echo "  Empleados activos revisados: $total"
    echo "  Cerrados (→ TERMINADO):      $cerrados"
    echo "═══════════════════════════════════════════════════"

    log_event "BARRIDO" "Scan completado — $total revisados, $cerrados cerrados"
}

# =============================================================================
# Main: dispatch
# =============================================================================

case "${1:-help}" in
    --scan)
        cmd_scan
        ;;
    --deliverable|-d)
        shift
        [ $# -lt 2 ] && fail "Uso: close-onboarding.sh --deliverable \"Nombre\" \"NDA\" [RECIBIDO]"
        name="$1"; deliv="$2"; val="${3:-RECIBIDO}"
        cmd_deliverable "$name" "$deliv" "$val"
        ;;
    help|--help|-h)
        cat <<HELP
Uso: $(basename "$0") <comando> [argumentos]

Comandos:

  "Nombre Completo"                          Verificar y cerrar onboarding
  --deliverable "Nombre" "NDA" [RECIBIDO]    Actualizar entregable
  --scan                                     Barrer todos los empleados activos

Ejemplos:
  close-onboarding.sh "Laura Pérez Sánchez"
  close-onboarding.sh --deliverable "Ana García" "NDA" RECIBIDO
  close-onboarding.sh --scan
HELP
        ;;
    *)
        cmd_close "$1"
        ;;
esac