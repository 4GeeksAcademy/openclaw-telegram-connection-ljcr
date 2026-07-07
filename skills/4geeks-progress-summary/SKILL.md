---
name: 4geeks-progress-summary
description: Resumen general del progreso académico en 4Geeks Academy, combinando estado de cohorts, tareas y completitud
metadata: {}
---

# 4geeks-progress-summary

Skill para presentar un resumen general del progreso académico del operador en 4Geeks Academy. Combina datos de cohorts (estado, completitud de proyectos), tareas (estados por tipo) y avance por cohorte activo.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`
- **Academy header (para endpoints que lo requieran):** `Academy: 7` (4Geeks Latam)

## Endpoints consultados

### 1. Perfil de usuario y cohorts

```
GET https://breathecode.herokuapp.com/v1/admissions/user/me
Authorization: Token ${BREATHECODE_TOKEN}
```

Devuelve:

| Campo                    | Descripción                                          |
|--------------------------|------------------------------------------------------|
| `first_name`             | Nombre del operador                                  |
| `cohorts`                | Array de inscripciones a cohortes                    |
| `cohorts[].cohort.name`  | Nombre del cohorte                                   |
| `cohorts[].educational_status` | ACTIVE, GRADUATED, SUSPENDED, DROPPED          |
| `cohorts[].role`         | Rol (ej. STUDENT)                                    |
| `cohorts[].created_at`   | Fecha de inscripción                                 |
| `cohorts[].completion.overall` | `{total, completed, percent}` — progreso     |

### 2. Todas las tareas

```
GET https://breathecode.herokuapp.com/v1/assignment/user/me/task
Authorization: Token ${BREATHECODE_TOKEN}
```

Devuelve array de tareas. Cada ítem contiene:

| Campo         | Descripción                          |
|---------------|--------------------------------------|
| `title`       | Título de la tarea                   |
| `task_status` | PENDING, DONE, APPROVED, REJECTED    |
| `task_type`   | LESSON, EXERCISE, PROJECT, QUIZ      |

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Hacer GET a `/v1/admissions/user/me` para obtener perfil y cohorts.
3. Hacer GET a `/v1/assignment/user/me/task` para obtener todas las tareas.
4. Procesar cohorts:
   - Separar cohorts con `educational_status: ACTIVE` vs `GRADUATED`.
   - Ordenar ACTIVE por `created_at` descendente.
   - Extraer `completion.overall` para cada uno (total, completed, percent).
5. Procesar tareas:
   - Agrupar por `task_status` y contar.
   - Agrupar por `task_type` y contar.
6. Presentar resumen formal con:
   - Nombre del cohorte activo principal (el más reciente con ACTIVE).
   - Cohorts activos vs graduados.
   - Progreso por cohorte activo (solo los que tengan `total > 0`).
   - Estadísticas globales de tareas.

## Formato de presentación

```
=== Resumen de progreso — 4Geeks Academy ===

Cohorte activo principal: <nombre>

Cohorts:
  Activos: <N>
  Graduados: <N>

Progreso por cohorte activo:
  <nombre>: <completed>/<total> (<percent>%)
  ...

Tareas totales: <N>
  DONE:    <N> (<pct>%)
  PENDING: <N> (<pct>%)

  LESSON:   <N>
  EXERCISE: <N>
  PROJECT:  <N>
  QUIZ:     <N>
```

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario.
- **NUNCA** incluir IDs de usuario, cuenta o conexión.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La respuesta debe contener exclusivamente estadísticas de progreso y nombres de cohortes.

## Manejo de errores

| Situación                              | Acción                                                |
|----------------------------------------|-------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido        | Informar que falta la variable de entorno             |
| API responde 401/403                   | Informar que el token es inválido o expiró            |
| Error de red/timeout                   | Informar que la API no respondió                      |
| Campos esperados ausentes              | Informar error de parseo                              |