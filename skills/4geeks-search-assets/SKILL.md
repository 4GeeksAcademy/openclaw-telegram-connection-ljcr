---
name: 4geeks-search-assets
description: Busca lecciones y material de estudio en 4Geeks Academy por tecnología
metadata: {}
---

# 4geeks-search-assets

Skill para buscar material de estudio (lecciones, ejercicios, proyectos) en el repositorio educativo de 4Geeks Academy, filtrado por tecnología.

## Autenticación

- **Token:** variable de entorno `BREATHECODE_TOKEN`
- **Header:** `Authorization: Token ${BREATHECODE_TOKEN}`

## Endpoint

```
GET https://breathecode.herokuapp.com/v1/registry/asset
Authorization: Token ${BREATHECODE_TOKEN}
```

### Parámetros de query

| Parámetro       | Tipo     | Descripción                              |
|-----------------|----------|------------------------------------------|
| `asset_type`    | string   | `LESSON`, `EXERCISE`, `PROJECT`          |
| `technologies`  | string   | Slug de tecnología (`python`, `react`, `javascript`, `tailwind`, `html`, `css`, `flask`, `docker`, `typescript`, etc.) |
| `difficulty`    | string   | `BEGINNER`, `EASY`, `INTERMEDIATE`, `HARD` |
| `like`          | string   | Búsqueda por texto en título/descripción |
| `limit`         | int      | Límite de resultados                     |
| `lang`          | string   | Idioma (`en`, `es`)                      |

### Estructura de cada asset en la respuesta

La respuesta es paginada: `{ count, results: [...], next, previous }`.

Cada item en `results` contiene:

| Campo          | Tipo   | Descripción                                      |
|----------------|--------|--------------------------------------------------|
| `title`        | string | Título de la lección/material                    |
| `slug`         | string | Identificador slug del asset                     |
| `url`          | string | URL del repositorio/readme del contenido         |
| `readme_url`   | string | URL directa al README                            |
| `technologies` | array  | Lista de tecnologías asociadas (slugs)           |
| `difficulty`   | string | Nivel de dificultad                              |
| `lang`         | string | Idioma (`en`, `es`)                              |
| `asset_type`   | string | LESSON, EXERCISE, PROJECT                        |
| `duration`     | int    | Duración estimada                                |
| `visibility`   | string | `PUBLIC` o `PRIVATE`                             |

## Procedimiento

1. Leer `BREATHECODE_TOKEN` de variable de entorno. Si no existe, informar error y detener.
2. Recibir como parámetro la tecnología a buscar (slug, ej. `python`, `react`, `typescript`).
3. Hacer GET a `/v1/registry/asset` con:
   - `asset_type=LESSON` (por defecto; puede configurarse)
   - `technologies={tecnología}`
   - `limit=20` (máximo por página)
4. Parsear JSON de respuesta.
5. Extraer del array `results` los campos `title` y `url` de cada asset.
6. Presentar lista numerada con título y enlace.

## Parámetros de entrada

| Parámetro     | Requerido | Defecto   | Descripción                         |
|---------------|-----------|-----------|-------------------------------------|
| `technologia` | sí        | —         | Slug de tecnología a buscar         |
| `asset_type`  | no        | `LESSON`  | Tipo de asset (LESSON, EXERCISE, PROJECT) |
| `limit`       | no        | `20`      | Número máximo de resultados         |

## Formato de presentación

```
=== Material de estudio para <tecnología> ===

<N>. <título>
   URL: <url>
   Dificultad: <dificultad>
   Idioma: <idioma>
```

## Reglas estrictas

- **NUNCA** imprimir, loguear, ni incluir en la respuesta el campo `email` del usuario.
- **NUNCA** incluir IDs de usuario, cuenta o conexión.
- **NUNCA** incluir el valor del token en logs o mensajes de salida.
- La respuesta debe contener exclusivamente los títulos y URLs del material encontrado.

## Manejo de errores

| Situación                              | Acción                                                |
|----------------------------------------|-------------------------------------------------------|
| `BREATHECODE_TOKEN` no definido        | Informar que falta la variable de entorno             |
| API responde 401/403                   | Informar que el token es inválido o expiró            |
| Respuesta sin `results` o vacía        | Informar que no se encontró material para esa tecnología |
| Error de red/timeout                   | Informar que la API no respondió                      |