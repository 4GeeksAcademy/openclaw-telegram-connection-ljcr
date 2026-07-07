---
name: 4geeks-cohort-status
description: Verifica sesión 4Geeks Academy y reporta cohorte activo sin exponer el email del operador
metadata: {}
---

# 4geeks-cohort-status

Skill para autenticarse en la API de 4Geeks Academy y verificar el estado del cohorte activo del operador.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`
- **Academy header (opcional):** `Academy: <id>` (para filtrar por academia)

## Endpoint principal

```
GET https://breathecode.herokuapp.com/v1/admissions/user/me
Authorization: Token ${BREATHECODE_TOKEN}
```

### Estructura de la respuesta

La respuesta incluye un array `cohorts` donde cada elemento contiene:

| Campo                        | Tipo   | Descripción                          |
|------------------------------|--------|--------------------------------------|
| `cohort.name`                | string | Nombre del cohorte                   |
| `cohort.slug`                | string | Slug del cohorte                     |
| `educational_status`         | string | ACTIVE, GRADUATED, SUSPENDED, DROPPED |
| `role`                       | string | Rol (ej. STUDENT)                    |
| `created_at`                 | string | ISO timestamp de creación             |

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Hacer GET a `https://breathecode.herokuapp.com/v1/admissions/user/me` con header `Authorization: Token ${BREATHECODE_TOKEN}`.
3. Parsear JSON de respuesta.
4. Recorrer el array `cohorts` y filtrar elementos con:
   - `educational_status === "ACTIVE"`
   - `role === "STUDENT"`
5. Ordenar por `created_at` descendente y seleccionar el primero como cohorte activo principal.
6. Reportar nombre del cohorte activo y su `educational_status`.

## Endpoint alternativo (cohortes por academia)

```
GET https://breathecode.herokuapp.com/v1/admissions/academy/cohort/me?academy=<id>&educational_status=ACTIVE
Authorization: Token ${BREATHECODE_TOKEN}
Academy: <id>
```

**Nota:** Este endpoint devuelve objetos de cohorte directamente (sin `educational_status`). Úselo solo para listar cohortes, no para obtener el estado educativo.

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario, su ID de cuenta, ni ningún identificador personal.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La confirmación de éxito debe contener únicamente: nombre del cohorte activo y su `educational_status`.

## Formato de confirmación

```
[Sesión 4Geeks verificada] <Nombre del cohorte activo> — <educational_status>
```

## Manejo de errores

| Situación                                    | Acción                                                                 |
|----------------------------------------------|------------------------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido              | Informar que falta la variable de entorno                              |
| API responde 401/403                         | Informar que el token es inválido o expiró                             |
| No se encuentra cohorte con `educational_status: ACTIVE` | Listar cohorts disponibles (sin emails) y preguntar al operador |
| `cohorts` ausente en la respuesta            | Informar error de parseo                                               |
| Error de red/timeout                         | Informar que la API no respondió                                       |