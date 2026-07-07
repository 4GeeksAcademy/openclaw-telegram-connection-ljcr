---
name: 4geeks-pending-tasks
description: Consulta tareas pendientes y rechazadas en 4Geeks Academy con resumen formal
metadata: {}
---

# 4geeks-pending-tasks

Skill para consultar las tareas pendientes (PENDING) y rechazadas (REJECTED) del operador en 4Geeks Academy y presentar un resumen formal de lo que falta por completar o corregir.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`

## Endpoint

```
GET https://breathecode.herokuapp.com/v1/assignment/user/me/task
Authorization: Token ${BREATHECODE_TOKEN}
```

### Parámetros de query

| Parámetro     | Valor                    | Descripción                       |
|---------------|--------------------------|-----------------------------------|
| `task_status` | `PENDING`, `REJECTED`    | Filtra por estado (uno a la vez) |
| `task_type`   | `PROJECT`, `EXERCISE`, `LESSON`, `QUIZ` | Filtra por tipo |
| `limit`       | número                   | Límite de resultados              |
| `offset`      | número                   | Desplazamiento para paginación    |

> **Nota:** La API no acepta múltiples valores para un mismo parámetro de query. Para obtener PENDING y REJECTED deben realizarse dos llamadas separadas y combinarse los resultados.

### task_status posibles

- `PENDING` — Pendiente
- `DONE` — Completado
- `APPROVED` — Aprobado
- `REJECTED` — Rechazado

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Realizar dos peticiones GET:
   - `GET /v1/assignment/user/me/task?task_status=PENDING`
   - `GET /v1/assignment/user/me/task?task_status=REJECTED`
3. Parsear ambas respuestas JSON (arrays directos).
4. Combinar los resultados. Para cada tarea extraer:
   - `title` — título
   - `task_status` — estado actual
   - `task_type` — tipo (LESSON, EXERCISE, PROJECT, QUIZ)
5. Presentar resumen con:
   - Total de tareas pendientes
   - Total de tareas rechazadas
   - Lista numerada con formato `[<task_status>] <title>`

## Formato de presentación

```
=== Tareas pendientes (PENDING) ===

<N>. [PENDING] <title>

=== Tareas rechazadas (REJECTED) ===

<N>. [REJECTED] <title>
```

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario ni ningún identificador de cuenta.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La respuesta debe contener únicamente las tareas y sus estados, sin adornos ni sugerencias.

## Manejo de errores

| Situación                              | Acción                                                |
|----------------------------------------|-------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido        | Informar que falta la variable de entorno             |
| API responde 401/403                   | Informar que el token es inválido o expiró            |
| Respuesta no es un array               | Informar error de parseo                              |
| Error de red/timeout                   | Informar que la API no respondió                      |