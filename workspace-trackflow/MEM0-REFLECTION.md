# MEM0-REFLECTION.md — Memoria de Grafos para el Flujo de Onboarding

## Contexto

El flujo de onboarding de TrackFlow gestiona la incorporación de nuevos empleados a través de 4 estados (NO_INICIADO → AUTENTICACIÓN → ACTIVO → TERMINADO). Cada empleado tiene entregables (NDA, ERP, SGA/Tickets) que deben ser recibidos para avanzar al estado final.

Actualmente, la memoria se implementa con una arquitectura híbrida de tres capas:

| Capa | Propósito | Formato |
|------|-----------|---------|
| `MEMORY.md` | Decisiones estratégicas, resúmenes diarios | Markdown plano |
| `/memory/*.md` | Estado transaccional por empleado | Markdown con campos fijos |
| QMD (BM25 + vectores + rerank) | Búsqueda semántica sobre ambos | Índice SQLite con embeddings |

### Lo que esta arquitectura resuelve bien

- **Persistencia portable:** Archivos markdown legibles por humanos, sin dependencia de base de datos externa.
- **Búsqueda híbrida:** QMD ofrece BM25 (búsqueda exacta por código/nombre) y búsqueda semántica (empleados en "autenticación", "pendientes de firma").
- **Auditabilidad:** Logs planos con timestamp de cada transición de estado.

### Lo que NO resuelve bien (y donde mem0 entra)

- **Relaciones implícitas:** La relación "RRHH aprueba a Empleado" no está modelada como una entidad; es un campo `Código de Verificación` que se compara.
- **Proveniencia de datos:** Si un entregable se marca como RECIBIDO, no hay registro de quién lo confirmó, cuándo ni mediante qué canal (email, Telegram, formulario).
- **Dependencias entre empleados:** Un empleado de Tecnología necesita que RRHH haya procesado su NDA antes de recibir acceso al SGA. Esta dependencia secuencial no está explícita.
- **Contexto recurrente:** Si un empleado pregunta "¿cuándo llega mi acceso al ERP?" después de varios pasos, el agente debe recomponer el historial desde archivos planos, sin una representación del recorrido temporal.
- **Consultas transversales:** "¿Cuántos empleados de Atención al Cliente están activos cuyo NDA ya se recibió?" requiere escanear múltiples archivos y unir en memoria del script.

---

## Cómo mem0 Mejoraría el Flujo

[mem0](https://github.com/mem0ai/mem0) añade una capa de **memoria de grafos** donde las entidades (personas, departamentos, acciones) y sus relaciones se almacenan como un grafo dirigido, consultable en lenguaje natural.

### 1. Modelado de Relaciones como Grafo

```
[RRHH] ──aprueba──> [Empleado: Ana García]
[Empleado] ──recibe──> [Código: X7K9M2]
[Empleado] ──entrega──> [Entregable: NDA]
[Entregable: NDA] ──estado──> [Estado: RECIBIDO]
[Empleado] ──pertenece──> [Departamento: Atención al Cliente]
[RRHH] ──confirma──> [Entregable: NDA] ──fecha──> [2026-07-11]
```

Cada arista puede tener atributos: timestamp, canal, actor. Esto permite responder preguntas como:

- "¿RRHH confirmó el NDA de Ana García?"
- "¿Qué códigos de verificación ha recibido RRHH hoy?"
- "¿Cuánto tiempo tardó Laura en pasar de ACTIVO a TERMINADO?"

### 2. Trazabilidad de Acciones

Con `MEMORY.md + /memory/ + QMD`, un cambio de estado se registra como una línea en log plano. Con mem0:

```json
{
  "action": "deliverable_updated",
  "actor": "FlowBot",
  "source": "telegram",
  "employee": "Laura Pérez Sánchez",
  "deliverable": "NDA",
  "previous": "PENDIENTE",
  "new": "RECIBIDO",
  "timestamp": "2026-07-11T14:55:00Z",
  "session_id": "tg-12345"
}
```

Esto permite reconstruir el timeline completo de onboarding de cualquier empleado con una consulta: *"Muéstrame el historial de entregables de Laura"*.

### 3. Detección de Patrones y Anomalías

Con relaciones explícitas, mem0 puede detectar:

- **Cuellos de botella:** Si 3 empleados de Almacén llevan 48h en AUTENTICACIÓN porque RRHH no ha enviado el código.
- **Entregables olvidados:** Si un empleado lleva 5 días ACTIVO sin que ningún entregable se haya marcado como RECIBIDO.
- **Secuencia incorrecta:** Si alguien marca SGA/Tickets como RECIBIDO antes que el NDA.

### 4. Consultas en Lenguaje Natural

mem0 permite al agente preguntar directamente:

> "¿Qué empleados de Logística Inversa tienen el NDA pendiente?"
> → Devuelve: `[{name: "Carlos Méndez Ruiz", status: "AUTENTICACIÓN", nda: "PENDIENTE"}]`

Esto elimina la necesidad de scripts bash que escanean archivos, parsean grep y construyen arrays asociativos manualmente.

---

## Trade-offs y Complejidad

### Complejidad de infraestructura

| Aspecto | MEMORY.md + /memory/ + QMD | Con mem0 |
|---------|---------------------------|----------|
| Dependencias | Bash, grep, sed, jq, QMD (binario SQLite) | Python/Node, mem0 (Redis/PostgreSQL/MongoDB) + LLM para embeddings + servidor de grafos |
| Instalación | 0 pasos (sistema de archivos) | pip install mem0 + configurar base de datos |
| Estado | Sin estado externo | Requiere conexión persistente a Redis/PostgreSQL |
| Consultas | Scripts + QMD CLI | API REST o librería Python |
| Respaldo | `cp -r memory/` backup | `pg_dump` o snapshot de Redis |
| Portabilidad | Se mueve con `rsync` o `git clone` | Requiere migrar la base de datos del grafo |

### Rendimiento

- **Archivos planos:** Escanear 1000 archivos de ~400 bytes cada uno con `find + grep`: ~20-50ms.
- **QMD:** Búsquedas BM25 sobre miles de documentos: ~10-100ms.
- **mem0:** Cada consulta requiere al menos 2 llamadas a LLM (embedding de la query + generación de respuesta sobre el grafo) + consulta a la base de datos de grafos. Latencia típica: 500ms-3s por consulta.

**Ganador en rendimiento:** MEMORY.md + /memory/ — no requiere red, no requiere LLM, es esencialmente I/O de disco.

### Mantenibilidad

- **Archivos planos:** Cualquier persona con un editor de texto puede entender y modificar el estado. Zero mantenimiento.
- **QMD:** Mantener el índice actualizado requiere re-indexar al crear/modificar archivos. Un hook de `write` o cron es suficiente.
- **mem0:** Requiere mantenimiento de la base de datos (backups, índices, migraciones de esquema), actualización de la versión de mem0, gestión de claves API de LLM.

### Costo

- **MEMORY.md + QMD:** Costo cero de infraestructura. Solo ocupa ~1-2MB en disco para cientos de empleados.
- **mem0:** Cada operación de escritura y lectura consume tokens de LLM. Para un flujo de onboarding con ~10 interacciones por empleado y ~100 empleados/año, estamos hablando de ~1M-2M tokens adicionales al año solo para mantener el grafo sincronizado.

---

## Cuándo Tiene Sentido Migrar a mem0

**SÍ migrar cuando:**

- El volumen de empleados supera los 100 activos simultáneos (consultas transversales complejas).
- Se requiere trazabilidad completa de quién-hizo-qué-y-cuándo con fines de auditoría (SOC2, ISO 27001).
- El agente necesita responder preguntas ad-hoc en lenguaje natural sobre el estado del proceso.
- El equipo de RRHH quiere un dashboard que muestre relaciones y dependencias entre equipos y entregables.
- Se integran múltiples fuentes de datos: RRHH (empleados), SGA (accesos), ERP (credenciales) — el grafo unifica todas.

**NO migrar cuando:**

- El proceso es lineal y secuencial (como lo es hoy).
- Menos de 50 empleados en onboarding concurrente.
- No se requiere auditoría granular por actor.
- El equipo valora la simplicidad de archivos markdown editables a mano.
- El presupuesto de tokens de LLM es ajustado.

---

## Conclusión

| Dimensión | MEMORY.md + /memory/ + QMD | mem0 |
|-----------|---------------------------|------|
| Modelado de relaciones | Implícito (campos en archivos) | Explícito (grafo con aristas nominadas) |
| Trazabilidad | Líneas de log plano | Eventos estructurados con metadatos |
| Consultas ad-hoc | Scripts bash o QMD CLI | Lenguaje natural vía LLM |
| Portabilidad | `cp -r .` | Dump de base de datos |
| Latencia por consulta | 10-100ms | 500ms-3s |
| Costo operativo | ~0 | Tokens de LLM + mantenimiento DB |
| Complejidad técnica | Baja (shell scripting) | Media-alta (Python + Redis/PostgreSQL + LLM) |
| **Recomendación para TrackFlow hoy** | ✅ Adecuado | ❌ Sobredimensionado |
| **Recomendación a 12 meses** | ✅ Adecuado | ✅ Evaluar si el volumen lo justifica |

La arquitectura actual con MEMORY.md + archivos en `/memory/` + QMD es la solución correcta para el estado actual de TrackFlow: proceso lineal, volumen manejable (< 50 empleados), sin requisitos de auditoría granular. Migrar a mem0 añadiría complejidad de infraestructura y costos de LLM que no se justifican hoy.

Si TrackFlow escala a cientos de empleados, integra múltiples sistemas (ERP, SGA, CRM) y requiere trazabilidad de auditoría, entonces mem0 sería la evolución natural. Hasta entonces, los archivos markdown y QMD proporcionan la flexibilidad, portabilidad y simplicidad que un equipo pequeño de tecnología necesita para operar sin dependencias externas.