---
name: 4geeks-projects-list
description: Lista los proyectos asignados en 4Geeks Academy con su estado actual
metadata: {}
---

# 4geeks-projects-list

Skill para consultar los proyectos (PROJECT) asignados al operador en 4Geeks Academy y mostrar su título y `task_status` actual.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`

## Endpoint

```
GET https://breathecode.herokuapp.com/v1/assignment/user/me/task?task_type=PROJECT
Authorization: Token ${BREATHECODE_TOKEN}
```

### Parámetros de query útiles

| Parámetro     | Valor                    | Descripción                     |
|---------------|--------------------------|---------------------------------|
| `task_type`   | `PROJECT`                | Filtra solo proyectos           |
| `task_status` | `PENDING`, `DONE`, etc.  | Filtra por estado               |
| `cohort`      | id del cohorte           | Filtra por cohorte              |
| `limit`       | número                   | Límite de resultados            |
| `offset`      | número                   | Desplazamiento para paginación  |

### task_status posibles

- `PENDING` — Pendiente
- `DONE` — Completado
- `APPROVED` — Aprobado
- `REJECTED` — Rechazado

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Hacer GET a `https://breathecode.herokuapp.com/v1/assignment/user/me/task` con:
   - Header `Authorization: Token ${BREATHECODE_TOKEN}`
   - Query param `task_type=PROJECT`
3. Parsear JSON de respuesta (es un array directo).
4. Para cada proyecto, extraer:
   - `title` — título del proyecto
   - `task_status` — estado actual
5. Presentar lista numerada con formato:

   ```
   <N>. [<task_status>] <title>
   ```

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario ni ningún identificador de cuenta.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La respuesta debe contener únicamente la lista de proyectos y sus estados.

## Manejo de errores

| Situación                              | Acción                                                |
|----------------------------------------|-------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido        | Informar que falta la variable de entorno             |
| API responde 401/403                   | Informar que el token es inválido o expiró            |
| Respuesta no es un array               | Informar error de parseo                              |
| Error de red/timeout                   | Informar que la API no respondió                      |