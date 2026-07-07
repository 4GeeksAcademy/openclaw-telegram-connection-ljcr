# Registro de Skills - 4Geeks API

## Skill 1: Autenticar Sesión
* **Prompt inicial:** "Quiero darte la habilidad de autenticarte en mi cuenta de 4Geeks..."
* **Descripción:** Verifica la validez del token alojado en el entorno y recupera el estado del cohorte activo mediante los endpoints de Admissions.
* **Endpoint principal descubierto:** `GET /v1/admissions/user/me` — devuelve array `cohorts` con `educational_status`, `role` y objeto `cohort` anidado.
* **Endpoint alternativo descartado:** `GET /v1/admissions/academy/cohort/me` — devuelve objetos cohort directos sin `educational_status`.
* **Resultado de prueba:**
  ```
  [Sesión 4Geeks verificada] Models training & RAG — ACTIVE
  ```
  — Sin exposición de correo electrónico ni ID de cuenta. Se filtraron 24 cohorts; el cohorte activo principal se determinó por `educational_status=ACTIVE` y `created_at` descendente.
* **Archivo de skill:** `skills/4geeks-cohort-status/SKILL.md`

---

## Skill 2: Listar Proyectos
* **Prompt inicial:** "Quiero crear una nueva skill para consultar mis proyectos asignados en 4Geeks..."
* **Descripción:** Obtiene los proyectos (task_type=PROJECT) asignados al operador y muestra título y task_status actual.
* **Endpoint:** `GET /v1/assignment/user/me/task?task_type=PROJECT`
* **Resultado de prueba:**
  ```
  66 proyectos obtenidos
   1. [DONE      ] Instagram Photo Feed with Bootstrap
   2. [DONE      ] Todolist Application Using React
  ...
  17. [PENDING   ] Code an Excuse Generator in Javascript
  26. [PENDING   ] Final Project User Stories & Wireframes
  ...
  66. [PENDING   ] My 4Geeks Assistant — Teaching OpenClaw to Track Your Progress
  ```
  — 55 proyectos DONE, 11 PENDING. Sin exposición de datos sensibles.
* **Archivo de skill:** `skills/4geeks-projects-list/SKILL.md`

---

## Skill 3: Tareas Pendientes y Rechazadas
* **Prompt inicial:** "Necesito una skill para ver mi trabajo pendiente en 4Geeks..."
* **Descripción:** Consulta las tareas con task_status=PENDING y task_status=REJECTED para identificar qué falta completar o corregir.
* **Endpoint:** `GET /v1/assignment/user/me/task`
* **Nota técnica importante:** La API no acepta múltiples valores para un mismo parámetro de query (ej. `task_status=PENDING&task_status=REJECTED` devuelve 0 resultados). El skill implementa **dos llamadas separadas** y combina los resultados.
* **Resultado de prueba:**
  ```
  PENDING: 88 tareas
  REJECTED: 0 tareas
  
  Proyectos pendientes (solo PROJECT):
    - Code an Excuse Generator in Javascript
    - Final Project User Stories & Wireframes
    - Showcase your friend's artist talent with a website
    - Command Line Challenge
    - My first collaborative professional project
    - Todo List CLI with Python
    - Milestone 1 — Your Company's Public Website
    - A simple Dashboard with Tailwind CSS
    - Cinema Seat Manager in TypeScript
    - Onboarding Agent with Memory
    - My 4Geeks Assistant — Teaching OpenClaw to Track Your Progress
  ```
* **Archivo de skill:** `skills/4geeks-pending-tasks/SKILL.md`

---

## Skill 4: Resumen de Progreso General
* **Prompt inicial:** "Construye una skill para darme un resumen de mi progreso general en el curso..."
* **Descripción:** Combina datos de cohorts (estado, completitud) y tareas globales para presentar un panorama general del avance académico.
* **Endpoints consultados:**
  - `GET /v1/admissions/user/me` — cohorts y su `completion.overall`
  - `GET /v1/assignment/user/me/task` — todas las tareas agrupadas por estado y tipo
* **Endpoint descartado:** `GET /v1/activity/me` — requiere permiso `read_activity` no disponible para el operador.
* **Resultado de prueba:**
  ```
  Cohorte activo principal: Models training & RAG
  Cohorts: 17 activos, 4 graduados
  
  Frontend development with Coding Agents:    4/4 (100%)
  Web UI Fundamentals with Tailwind CSS:       3/3 (100%)
  Command line - Git & Github:                2/2 (100%)
  Coding fundamentals with Typescript:        3/4 (75%)
  ...
  
  Tareas totales: 327
    DONE:    239 (73%)
    PENDING:  88 (27%)
    LESSON:   105 | EXERCISE: 148 | PROJECT: 66 | QUIZ: 8
  ```
* **Archivo de skill:** `skills/4geeks-progress-summary/SKILL.md`

---

## Skill 5: Próximos Eventos
* **Prompt inicial:** "Quiero una skill para ver los próximos eventos de 4Geeks..."
* **Descripción:** Consulta eventos futuros disponibles en la plataforma y muestra título, fecha, tipo y enlace.
* **Endpoint:** `GET /v1/events/all?upcoming=true` (requiere header `Academy: 7`)
* **Resultado de prueba:**
  ```
  1. Turn Data into Strategies that Drive Growth
     Inicio: 2026-07-09 17:00 UTC  |  Fin: 2026-07-09 18:00 UTC
     Tipo: AI Trends  |  Online: Sí  |  Slug: turn-data-into-strategies-that-drive-growth

  2. Build An AI Powered B2B Growth Machine
     Inicio: 2026-07-16 16:00 UTC  |  Fin: 2026-07-16 17:00 UTC
     Tipo: AI Trends  |  Online: Sí  |  Slug: build-an-ai-powered-b2b-growth-machine
  ```
* **Archivo de skill:** `skills/4geeks-upcoming-events/SKILL.md`

---

## Skill 6: Buscar Material de Estudio
* **Prompt inicial:** "Crea una skill que me permita buscar material de estudio en 4Geeks..."
* **Descripción:** Busca lecciones/material en el repositorio educativo filtrado por tecnología (asset_type y technologies). Acepta un parámetro de tecnología (slug) como entrada.
* **Endpoint:** `GET /v1/registry/asset?asset_type=LESSON&technologies={slug}`
* **Estructura de respuesta:** Paginada: `{ count, results: [...], next, previous }`
* **Ejemplo con `technologies=python`:** 194 resultados.
* **Resultado de prueba:**
  ```
  1. Exploring Random Forest
     URL: https://github.com/4GeeksAcademy/machine-learning-content
  2. Exploring Boosting Algorithm
     URL: https://github.com/4GeeksAcademy/machine-learning-content/blob/master/06-ml_algos/exploring-boosting.ipynb
  3. Explorando el algoritmo de boosting
     URL: N/A
  ```
* **Archivo de skill:** `skills/4geeks-search-assets/SKILL.md`

---

## Resumen General de Skills Creados

| # | Skill                       | Endpoint clave                              | Archivo                                        |
|---|-----------------------------|---------------------------------------------|------------------------------------------------|
| 1 | Autenticar Sesión           | `GET /v1/admissions/user/me`                | `skills/4geeks-cohort-status/SKILL.md`         |
| 2 | Listar Proyectos            | `GET /v1/assignment/user/me/task`           | `skills/4geeks-projects-list/SKILL.md`         |
| 3 | Tareas Pendientes/Rechazadas| `GET /v1/assignment/user/me/task`           | `skills/4geeks-pending-tasks/SKILL.md`         |
| 4 | Resumen de Progreso         | `/v1/admissions/user/me` + `/v1/assignment/user/me/task` | `skills/4geeks-progress-summary/SKILL.md` |
| 5 | Próximos Eventos            | `GET /v1/events/all?upcoming=true`          | `skills/4geeks-upcoming-events/SKILL.md`       |
| 6 | Buscar Material             | `GET /v1/registry/asset`                    | `skills/4geeks-search-assets/SKILL.md`         |

**Total de skills creados:** 6
**Skills previos existentes en el workspace:** qmd, deep-work, server-maintenance
**Variable de entorno utilizada en todos:** `BREATHECODE_TOKEN`
**Headers comunes:** `Authorization: Token ${BREATHECODE_TOKEN}` y `Academy: 7` (para endpoints que lo requieren)
**Nota de implementación:** Ningún endpoint expuso el email del operador en los mensajes de éxito.