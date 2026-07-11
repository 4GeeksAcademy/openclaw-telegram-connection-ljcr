#!/usr/bin/env bash
# =============================================================================
# trackflow-onboarding.sh — Gestión del flujo de onboarding de empleados
#
# Este script implementa los 7 pasos del flujo de onboarding de TrackFlow,
# desde el registro inicial hasta la activación completa del empleado.
#
# Dependencias: Bash 4.0+, curl, openssl
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
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

generate_code() {
    openssl rand -hex 4 | tr '[:lower:]' '[:upper:]'
}

employee_file() {
    local name="$1"
    echo "$MEMORY_DIR/$(slugify "$name").md"
}

employee_exists() {
    local file; file=$(employee_file "$1")
    [ -f "$file" ]
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
    else
        echo "- **$field:** $value" >> "$file"
    fi
}

send_telegram() {
    local chat_id="$1" message="$2"
    # Implementación delegada al canal de OpenClaw
    log_event "TELEGRAM" "Para $chat_id: ${message:0:80}..."
    echo "[TELEGRAM] Mensaje encolado para $chat_id:"
    echo "$message"
}

# =============================================================================
# PASO 1: Registrar nuevo empleado (disparado por mensaje de RRHH en Telegram)
# =============================================================================
#
# Uso: trackflow-onboarding.sh step1 "Nombre Completo" "email@dominio.com" "Departamento"
#
# Crea el archivo de empleado en /memory/ con estado NO_INICIADO.

step1_register() {
    local name="$1" email="$2" department="$3"
    local file; file=$(employee_file "$name")

    if [ -f "$file" ]; then
        log_event "ERROR" "Empleado '$name' ya registrado en $file"
        exit 1
    fi

    cat > "$file" <<EOF
# Estado de Empleado

- **Nombre:** $name
- **Correo:** $email
- **Departamento:** $department
- **Estado:** NO_INICIADO
- **Código de Verificación:** —
- **Entregables:**
  - NDA: PENDIENTE
  - ERP: PENDIENTE
  - SGA/Tickets: PENDIENTE
- **Fecha de Creación:** $(date -u +"%Y-%m-%d")
- **Última Actualización:** $TIMESTAMP
EOF

    log_event "REGISTRO" "Empleado '$name' creado en $file (NO_INICIADO)"
    echo "$file"
}

# =============================================================================
# PASO 2: Enviar email de bienvenida
# =============================================================================
#
# Uso: trackflow-onboarding.sh step2 "Nombre Completo"
#
# Envía un email de bienvenida al empleado instruyéndole contactar a FlowBot
# por Telegram para continuar el proceso.

step2_welcome_email() {
    local name="$1"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no registrado"

    local email; email=$(read_field "$file" "Correo")
    local current_state; current_state=$(read_field "$file" "Estado")
    [ "$current_state" != "NO_INICIADO" ] && fail "Empleado '$name' no está en estado NO_INICIADO (actual: $current_state)"

    local telegram_bot="@TrackFlowBot"
    local subject="Bienvenido a TrackFlow — Inicia tu proceso de incorporación"
    local body=$(cat <<EMAIL
Hola $name,

Bienvenido a TrackFlow. Para completar tu proceso de incorporación, 
es necesario que te pongas en contacto con nuestro asistente virtual 
a través de Telegram.

Pasos a seguir:

1. Abre Telegram y busca $telegram_bot
2. Inicia una conversación con el asistente
3. Identifícate con tu nombre completo
4. Recibirás un código de seguridad que deberás entregar a RRHH

Una vez que RRHH confirme tu identidad mediante el código, 
recibirás las instrucciones para completar tus entregables 
(NDA, accesos al sistema, etc.).

Si tienes alguna duda, contacta con el departamento de RRHH.

Atentamente,
FlowBot 🤖 — TrackFlow Tech
EMAIL
)

    log_event "EMAIL" "Enviado a $email: '$subject'"
    echo "[EMAIL] Para: $email"
    echo "[EMAIL] Asunto: $subject"
    echo "[EMAIL] Cuerpo:"
    echo "-------------------"
    echo "$body"
    echo "-------------------"

    log_event "INFO" "Email de bienvenida enviado a '$name' — estado permanece NO_INICIADO"
}

# =============================================================================
# PASO 3: Generar código de seguridad (disparado cuando el empleado escribe)
# =============================================================================
#
# Uso: trackflow-onboarding.sh step3 "Nombre Completo" "<telegram_chat_id>"
#
# Actualiza el estado a AUTENTICACIÓN, genera un código y lo envía al empleado.

step3_generate_code() {
    local name="$1" tg_chat_id="$2"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no registrado"

    local current_state; current_state=$(read_field "$file" "Estado")
    [ "$current_state" != "NO_INICIADO" ] && \
        [ "$current_state" != "AUTENTICACIÓN" ] && \
        fail "Empleado '$name' debe estar en NO_INICIADO o AUTENTICACIÓN (actual: $current_state)"

    local code; code=$(generate_code)
    write_field "$file" "Código de Verificación" "$code"
    write_field "$file" "Estado" "AUTENTICACIÓN"
    write_field "$file" "Última Actualización" "$TIMESTAMP"

    local message=$(cat <<MSG
🔐 Código de verificación: $code

$name, este es tu código de seguridad personal.

Debes entregarlo al departamento de RRHH para que confirmen tu identidad.
Una vez que lo verifiquen, recibirás las instrucciones para completar tu incorporación.

⚠️ No compartas este código con nadie que no sea RRHH de TrackFlow.

Atentamente,
FlowBot 🤖
MSG
)
    send_telegram "$tg_chat_id" "$message"
    log_event "CÓDIGO" "Generado código '$code' para '$name' — enviado por Telegram"
}

# =============================================================================
# PASO 4: Reenviar código (si el empleado lo solicita)
# =============================================================================
#
# Uso: trackflow-onboarding.sh step4 "Nombre Completo" "<telegram_chat_id>"

step4_resend_code() {
    local name="$1" tg_chat_id="$2"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no registrado"

    local code; code=$(read_field "$file" "Código de Verificación")
    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "AUTENTICACIÓN" ] && fail "Empleado '$name' no está en AUTENTICACIÓN"

    local message=$(cat <<MSG
🔄 Tu código de verificación sigue siendo válido:

🔐 $code

Entrégalo a RRHH para continuar con el proceso.
MSG
)
    send_telegram "$tg_chat_id" "$message"
    log_event "REENVÍO" "Código '$code' reenviado a '$name'"
}

# =============================================================================
# PASO 5: Verificar código enviado por RRHH
# =============================================================================
#
# Uso: trackflow-onboarding.sh step5 "Nombre Completo" "<CODIGO>"

step5_verify_code() {
    local name="$1" received_code="$2"
    local file; file=$(employee_file "$name")

    if [ ! -f "$file" ]; then
        # Si no se encuentra por nombre, buscar por código en toda la carpeta
        local found=false
        while IFS= read -r -d '' f; do
            local stored; stored=$(read_field "$f" "Código de Verificación")
            if [ "$stored" = "$received_code" ]; then
                file="$f"
                name=$(read_field "$f" "Nombre")
                found=true
                break
            fi
        done < <(find "$MEMORY_DIR" -name '*.md' -print0 2>/dev/null)
        $found || fail "Código '$received_code' no coincide con ningún empleado"
    fi

    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "AUTENTICACIÓN" ] && fail "Empleado '$name' no está en AUTENTICACIÓN (actual: $estado)"

    local expected; expected=$(read_field "$file" "Código de Verificación")
    [ "$received_code" != "$expected" ] && fail "Código incorrecto para '$name'"

    log_event "VERIFICADO" "Código '$received_code' válido para '$name' — listo para aprobar"
    echo "$name"
}

# =============================================================================
# PASO 6: Ejecutar script de aprobación de pairing
# =============================================================================
#
# Uso: trackflow-onboarding.sh step6 "Nombre Completo"
#
# Llama al script approve-pairing.sh y marca al empleado como ACTIVO.

step6_approve() {
    local name="$1"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no registrado"

    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "AUTENTICACIÓN" ] && fail "Empleado '$name' no está en AUTENTICACIÓN (actual: $estado)"

    local code; code=$(read_field "$file" "Código de Verificación")
    local pairing_script="$SCRIPT_DIR/approve-pairing.sh"

    if [ -f "$pairing_script" ]; then
        bash "$pairing_script" --code "$code" --employee "$name"
    else
        # Fallback: aprobar directamente
        write_field "$file" "Estado" "ACTIVO"
        write_field "$file" "Última Actualización" "$TIMESTAMP"
        log_event "APROBADO" "Empleado '$name' activado (aprobación directa)"
    fi

    echo "$file"
}

# =============================================================================
# PASO 7: Saludar y entregar instrucciones de onboarding
# =============================================================================
#
# Uso: trackflow-onboarding.sh step7 "Nombre Completo" "<telegram_chat_id>"
#
# Envía el saludo final con los entregables requeridos según el departamento.

step7_greeting() {
    local name="$1" tg_chat_id="$2"
    local file; file=$(employee_file "$name")
    [ ! -f "$file" ] && fail "Empleado '$name' no registrado"

    local estado; estado=$(read_field "$file" "Estado")
    [ "$estado" != "ACTIVO" ] && fail "Empleado '$name' no está ACTIVO (actual: $estado)"

    local department; department=$(read_field "$file" "Departamento")

    # Entregables base (obligatorios para todos)
    local deliverables="• **NDA (Acuerdo de Confidencialidad):** Firmar y enviar escaneado a RRHH
• **Acceso al ERP corporativo:** Se te enviarán credenciales por email corporativo"

    # Entregables adicionales según departamento
    case "$(echo "$department" | tr '[:upper:]' '[:lower:]')" in
        *"almacén"*|*"operaciones"*)
            deliverables="$deliverables
• **Acceso al SGA (Sistema de Gestión de Almacén):** Recibirás credenciales y enlace al portal correspondiente según tu ubicación (Los Ángeles/Zaragoza)"
            ;;
        *"logística inversa"*|*"devoluciones"*)
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** Portal de gestión de devoluciones y panel de inspección"
            ;;
        *"última milla"*|*"transportistas"*)
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** Panel de tracking y asignación de transportistas"
            ;;
        *"atención"*|*"cliente"*|*"cx"*)
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** Sistema de tickets de atención al cliente"
            ;;
        *"comercial"*|*"ventas"*)
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** CRM y panel de clientes"
            ;;
        *"tecnología"*|*"tech"*|*"ingeniería"*)
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** Repositorios, CI/CD y herramientas de desarrollo"
            ;;
        *)
            # Por defecto: asignar acceso estándar
            deliverables="$deliverables
• **Acceso al SGA/Tickets:** Portal de seguimiento de incidencias"
            ;;
    esac

    local message=$(cat <<MSG
✅ ¡Bienvenido a TrackFlow, $name!

Tu identidad ha sido verificada y tu proceso de incorporación está activo.

📋 **Tus entregables pendientes:**

$deliverables

📌 **Próximos pasos:**
1. Completa y entrega el NDA a RRHH
2. Revisa tu email corporativo para las credenciales de acceso
3. Confirma recepción de cada entregable respondiendo a este mensaje

Si tienes dudas sobre algún entregable, escribe "ayuda" seguido del nombre del entregable.

¡Mucho éxito en tu incorporación!

FlowBot 🤖 — TrackFlow Tech
MSG
)
    send_telegram "$tg_chat_id" "$message"
    log_event "ACTIVACIÓN" "Instrucciones de onboarding enviadas a '$name' (Depto: $department)"
}

# =============================================================================
# Utilidad: Reporte diario de estado de onboarding
# =============================================================================
#
# Uso: trackflow-onboarding.sh report

report() {
    echo "═══════════════════════════════════════════════════"
    echo "  REPORTE DIARIO DE ONBOARDING"
    echo "  $(date -u +'%Y-%m-%d %H:%M UTC')"
    echo "═══════════════════════════════════════════════════"

    local no_iniciados=()
    local autenticacion=()
    local activos=()
    local terminados=()

    while IFS= read -r -d '' file; do
        local name estado
        name=$(read_field "$file" "Nombre")
        estado=$(read_field "$file" "Estado")
        case "$estado" in
            "NO_INICIADO")   no_iniciados+=("$name") ;;
            "AUTENTICACIÓN") autenticacion+=("$name") ;;
            "ACTIVO")        activos+=("$name") ;;
            "TERMINADO")     terminados+=("$name") ;;
        esac
    done < <(find "$MEMORY_DIR" -name '*.md' -print0 2>/dev/null)

    echo ""
    echo "📋 No iniciados:  ${#no_iniciados[@]}"
    for n in "${no_iniciados[@]}"; do echo "    • $n"; done

    echo ""
    echo "🔐 Autenticación: ${#autenticacion[@]}"
    for n in "${autenticacion[@]}"; do echo "    • $n"; done

    echo ""
    echo "✅ Activos:        ${#activos[@]}"
    for n in "${activos[@]}"; do echo "    • $n"; done

    echo ""
    echo "🏁 Terminados:     ${#terminados[@]}"
    for n in "${terminados[@]}"; do echo "    • $n"; done

    echo ""
    echo "═══════════════════════════════════════════════════"
}

# =============================================================================
# Main: dispatch de comandos
# =============================================================================

case "${1:-help}" in
    step1) shift; step1_register "$@" ;;
    step2) shift; step2_welcome_email "$@" ;;
    step3) shift; step3_generate_code "$@" ;;
    step4) shift; step4_resend_code "$@" ;;
    step5) shift; step5_verify_code "$@" ;;
    step6) shift; step6_approve "$@" ;;
    step7) shift; step7_greeting "$@" ;;
    report) report ;;
    help|--help|-h)
        cat <<HELP
Uso: $(basename "$0") <comando> [argumentos]

Comandos:

  step1 "Nombre" "email@..." "Departamento"   Registrar nuevo empleado
  step2 "Nombre"                               Enviar email de bienvenida
  step3 "Nombre" "<chat_id>"                   Generar y enviar código de seguridad
  step4 "Nombre" "<chat_id>"                   Reenviar código de seguridad
  step5 "Nombre" "<CODIGO>"                    Verificar código recibido de RRHH
  step6 "Nombre"                               Aprobar pairing (ejecuta approve-pairing.sh)
  step7 "Nombre" "<chat_id>"                   Saludar y entregar instrucciones
  report                                       Mostrar reporte diario de onboarding
HELP
        ;;
    *) fail "Comando desconocido: $1. Usa --help para ver los comandos disponibles."
esac