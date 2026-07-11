#!/usr/bin/env bash
# =============================================================================
# approve-pairing.sh — Aprobación de Pairing vía Código de Verificación
#
# Uso:  ./approve-pairing.sh --code <VERIFICATION_CODE> [--employee <NAME>]
#
# Este script busca en /memory/ todos los empleados en estado AUTENTICACIÓN,
# verifica si el código proporcionado coincide con el registrado y, de ser
# así, actualiza el estado a ACTIVO y registra la aprobación en el log.
#
# Compatibilidad: Linux (Bash 4.0+, coreutils)
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
MEMORY_DIR="$WORKSPACE_DIR/memory"
LOG_DIR="$WORKSPACE_DIR/logs"
LOG_FILE="$LOG_DIR/pairing-audit.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Funciones ---------------------------------------------------------------

usage() {
    cat <<EOF
Uso: $(basename "$0") --code <VERIFICATION_CODE> [--employee <NAME>]

Obligatorio:
  --code <CODE>    Código de verificación a validar

Opcional:
  --employee <NAME> Nombre del empleado (si se omite, busca en todos los
                     archivos /memory/ en estado AUTENTICACIÓN)

Ejemplo:
  $(basename "$0") --code X7K9M2
  $(basename "$0") --code X7K9M2 --employee "Ana García"
EOF
    exit 1
}

log_event() {
    local level="$1"
    local message="$2"
    local entry="$TIMESTAMP | $level | $message"
    echo "$entry" >> "$LOG_FILE"
    echo "$entry"
}

fail() {
    log_event "ERROR" "$1"
    exit 1
}

extract_field() {
    local file="$1"
    local field="$2"
    grep -E "^[-*] \*\*$field:\*\*" "$file" 2>/dev/null \
        | sed -E 's/^[-*] \*\*[^:]+:\*\*[[:space:]]*(.*)[[:space:]]*$/\1/' \
        | xargs
}

update_field() {
    local file="$1"
    local field="$2"
    local value="$3"
    if grep -qE "^[-*] \*\*$field:\*\*" "$file" 2>/dev/null; then
        sed -i -E "s/^[-*] \*\*$field:\*\*.*$/- **$field:** $value/" "$file"
    fi
}

find_employees_in_state() {
    local state="$1"
    local results=()
    if [ ! -d "$MEMORY_DIR" ]; then
        echo ""
        return
    fi
    while IFS= read -r -d '' file; do
        local estado
        estado=$(extract_field "$file" "Estado")
        if [ "$estado" = "$state" ]; then
            results+=("$file")
        fi
    done < <(find "$MEMORY_DIR" -name '*.md' -print0 2>/dev/null)
    printf '%s\n' "${results[@]}"
}

approve_employee() {
    local file="$1"
    local name
    name=$(extract_field "$file" "Nombre")

    update_field "$file" "Estado" "ACTIVO"
    update_field "$file" "Última Actualización" "$TIMESTAMP"
    log_event "APROBADO" "Empleado '$name' — Pairing verificado y activado"
}

# --- Parseo de argumentos ----------------------------------------------------

CODE=""
EMPLOYEE_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        --code)
            shift
            [ $# -eq 0 ] && fail "Falta valor para --code"
            CODE="$1"
            shift
            ;;
        --employee)
            shift
            [ $# -eq 0 ] && fail "Falta valor para --employee"
            EMPLOYEE_NAME="$1"
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            fail "Argumento desconocido: $1"
            ;;
    esac
done

# --- Validaciones ------------------------------------------------------------

[ -z "$CODE" ] && fail "Se requiere --code <VERIFICATION_CODE>"

# Crear directorios si no existen
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

[ ! -d "$MEMORY_DIR" ] && fail "Directorio /memory/ no encontrado en $MEMORY_DIR"

# --- Búsqueda de empleado  ---------------------------------------------------

candidates=()
if [ -n "$EMPLOYEE_NAME" ]; then
    # Buscar por nombre exacto
    while IFS= read -r -d '' file; do
        name=$(extract_field "$file" "Nombre")
        if [ "$name" = "$EMPLOYEE_NAME" ]; then
            candidates=("$file")
            break
        fi
    done < <(find "$MEMORY_DIR" -name '*.md' -print0 2>/dev/null)
    [ ${#candidates[@]} -eq 0 ] && fail "Empleado '$EMPLOYEE_NAME' no encontrado en /memory/"
else
    # Buscar todos en estado AUTENTICACIÓN
    mapfile -t candidates < <(find_employees_in_state "AUTENTICACIÓN")
fi

[ ${#candidates[@]} -eq 0 ] && fail "No hay empleados en estado AUTENTICACIÓN pendientes de verificación"

# --- Verificación de código y aprobación -------------------------------------

approved_count=0
rejected_count=0

for file in "${candidates[@]}"; do
    name=$(extract_field "$file" "Nombre")
    stored_code=$(extract_field "$file" "Código de Verificación")

    if [ -z "$stored_code" ]; then
        log_event "ERROR" "Empleado '$name' — No tiene código de verificación registrado"
        rejected_count=$((rejected_count + 1))
        continue
    fi

    if [ "$stored_code" != "$CODE" ]; then
        log_event "RECHAZADO" "Empleado '$name' — Código '$CODE' no coincide con el esperado"
        rejected_count=$((rejected_count + 1))
        continue
    fi

    approve_employee "$file"
    approved_count=$((approved_count + 1))
done

# --- Resumen final -----------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════"
echo "  RESUMEN DE APROBACIÓN DE PAIRING"
echo "═══════════════════════════════════════════════════"
echo "  Código ingresado:         $CODE"
echo "  Aprobados:                $approved_count"
echo "  Rechazados (código inválido o sin código): $rejected_count"
echo "═══════════════════════════════════════════════════"
echo ""

[ "$approved_count" -eq 0 ] && exit 1 || exit 0