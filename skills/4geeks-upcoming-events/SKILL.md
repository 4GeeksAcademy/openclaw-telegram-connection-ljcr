---
name: 4geeks-upcoming-events
description: Lista los próximos eventos académicos de 4Geeks Academy con fecha, título y detalles
metadata: {}
---

# 4geeks-upcoming-events

Skill para consultar los próximos eventos disponibles en 4Geeks Academy y mostrar título, fecha y detalles relevantes.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`
- **Academy header:** `Academy: 7` (4Geeks Latam)

## Endpoint

```
GET https://breathecode.herokuapp.com/v1/events/all?upcoming=true
Authorization: Token ${BREATHECODE_TOKEN}
Academy: 7
```

### Parámetros de query útiles

| Parámetro   | Tipo    | Descripción                        |
|-------------|---------|------------------------------------|
| `upcoming`  | bool    | `true` para solo eventos futuros   |
| `academy`   | int     | ID de academia para filtrar        |
| `limit`     | int     | Límite de resultados               |

### Estructura de cada evento en la respuesta

| Campo          | Tipo   | Descripción                          |
|----------------|--------|--------------------------------------|
| `title`        | string | Título del evento                    |
| `starting_at`  | string | Fecha/hora inicio (ISO 8601)         |
| `ending_at`    | string | Fecha/hora fin (ISO 8601)            |
| `slug`         | string | Identificador URL del evento         |
| `online_event` | bool   | Si es virtual                        |
| `event_type`   | object | `{id, slug, name}` — tipo de evento  |
| `status`       | string | ACTIVE, DRAFT, etc.                  |
| `url`          | string | URL del evento (si aplica)           |
| `excerpt`      | string | Descripción breve                     |
| `banner`       | string | URL del banner/imagen                |
| `host`         | string | Anfitrión del evento                 |
| `recording_url`| string | URL de grabación (si disponible)     |

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Hacer GET a `/v1/events/all?upcoming=true` con headers `Authorization` y `Academy: 7`.
3. Parsear JSON de respuesta (array de eventos).
4. Para cada evento, extraer y mostrar:
   - Título
   - Fecha y hora de inicio (formato legible)
   - Fecha y hora de fin
   - Tipo de evento
   - Si es online o presencial
   - Enlace o slug
5. Presentar lista numerada.

## Formato de presentación

```
=== Próximos eventos en 4Geeks ===

<N>. <título>
    Inicio: <fecha> <hora> UTC
    Fin:    <fecha> <hora> UTC
    Tipo:   <tipo>
    Online: <sí/no>
    Slug:   <slug>
```

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario.
- **NUNCA** incluir IDs de usuario, cuenta o conexión.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La respuesta debe contener exclusivamente la información de los eventos.

## Manejo de errores

| Situación                              | Acción                                                |
|----------------------------------------|-------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido        | Informar que falta la variable de entorno             |
| API responde 401/403                   | Informar que el token es inválido o expiró            |
| Respuesta vacía o sin resultados       | Informar que no hay próximos eventos                  |
| Error de red/timeout                   | Informar que la API no respondió                      |