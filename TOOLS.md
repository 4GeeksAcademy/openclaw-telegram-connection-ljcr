# TOOLS.md - Integraciones y Convenciones

## Integraciones Activas

### Google Calendar (Composio)

**Alcance autorizado:** Lectura, creación y actualización de eventos. El resto de las herramientas de Composio (Gmail, Slack, GitHub, etc.) están temporalmente deshabilitadas.

**Calendario predeterminado:** `primary` (calendario principal del operador).

**Formato obligatorio de confirmación de éxito:**

```
[Evento creado] <Título del evento> — <Fecha> <Hora>
```

**Ejemplo:**
```
[Evento creado] Garra prueba — 2026-07-06 18:00 (America/Caracas)
```

**Reglas estrictas:**
- No incluir dirección de correo electrónico del operador.
- No incluir ID del evento.
- No incluir enlaces generados por la API (Meet, HTML link).
- No incluir datos de la cuenta o conexión.
- No incluir saludos, emojis ni lenguaje coloquial.

## Integraciones Deshabilitadas

- Gmail — deshabilitado
- Slack — deshabilitado
- GitHub — deshabilitado
- Cualquier otro toolkit de Composio no listado arriba — deshabilitado