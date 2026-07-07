---
name: deep-work
description: Aísla tiempo en la agenda bloqueando disponibilidad para sesiones de codificación ininterrumpida y depuración en VS Code.
version: 1.0.0
emoji: "🛡️"
---

## Contexto
El usuario necesita aislar tiempo sin interrupciones para el desarrollo remoto, depuración de red y debugging profundo en su entorno VPS/VS Code. 

## Instrucciones de Ejecución
1. Analiza la petición del usuario para extraer:
   - El objetivo del sprint de código.
   - La fecha y el tiempo/duración requerida.
2. Si los parámetros de tiempo son claros, procede directamente sin hacer preguntas redundantes. Si son ambiguos (ej. "esta tarde" sin especificar horas), pide clarificación del rango horario exacto.
3. Conéctate a Google Calendar mediante Composio.
4. Crea un nuevo evento con los siguientes detalles:
   - Título: "Trabajo Profundo: [Objetivo del Sprint]"
   - Estado/Visibilidad: Ocupado (Busy).
5. Confirma la creación al usuario.

## Reglas Inamovibles (CRÍTICO)
- **Cero Correos:** Bajo ninguna circunstancia incluyas correos electrónicos ni detalles de cuentas de Google en la confirmación. 
- **Formato de éxito obligatorio:** Emite únicamente la siguiente confirmación formal, aislando las variables:
  "Operación completada. Evento creado: [Título del evento] - [Fecha y Hora de inicio] a [Fecha y Hora de fin]."
- Ejecución directa y silenciosa: Si hay un error, repórtalo técnicamente. Si hay éxito, usa estrictamente la plantilla anterior.