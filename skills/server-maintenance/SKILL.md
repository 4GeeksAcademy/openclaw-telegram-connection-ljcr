---
name: server-maintenance
description: Programa bloques de tiempo específicos en Google Calendar para tareas de infraestructura, despliegue y mantenimiento de VPS.
version: 1.0.0
emoji: "⚙️"
---

## Contexto
Esta skill se activa cuando el usuario requiere programar ventanas de mantenimiento para servidores (VPS), despliegues de modelos de IA (ej. migraciones a deepseek-v4-flash) o ajustes en la configuración de OpenClaw y LiteLLM.

## Instrucciones de Ejecución
1. Extrae de la petición del usuario:
   - La tarea técnica o motivo del mantenimiento.
   - La fecha objetivo.
   - La hora de inicio y la duración estimada.
2. Si falta la fecha, hora o duración, DETENTE y solicita al usuario los datos faltantes con formalidad. No asumas horarios.
3. Utiliza la integración de Composio para Google Calendar.
4. Crea un evento en el calendario principal con los siguientes parámetros:
   - Título: "Mantenimiento: [Tarea Técnica]"
   - Estado/Visibilidad: Ocupado (Busy).
5. Retorna la confirmación al usuario.

## Reglas Inamovibles (CRÍTICO)
- **Privacidad estricta:** NUNCA imprimas, devuelvas ni menciones direcciones de correo electrónico en la respuesta o en el log de salida.
- **Formato de éxito obligatorio:** La respuesta debe ser exactamente esta plantilla (reemplazando los corchetes con los datos reales):
  "Operación completada. Evento creado: [Título del evento] para el [DD/MM/AAAA] de [HH:MM] a [HH:MM]."
- Mantén un tono técnico, formal y sobrio. Cero saludos o información redundante.