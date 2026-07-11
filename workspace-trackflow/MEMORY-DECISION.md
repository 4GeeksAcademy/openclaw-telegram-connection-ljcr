# MEMORY-DECISION.md — Arquitectura de Memoria para Onboarding

## Justificación: MEMORY.md vs. `/memory/` con QMD

### MEMORY.md — Memoria central (larga duración)

`MEMORY.md` es un archivo único en la raíz del workspace que funciona como memoria de largo plazo: decisiones estratégicas, lecciones aprendidas, preferencias del usuario y resúmenes diarios. Se carga en contexto al inicio de cada sesión principal.

**Ventajas:**
- Siempre disponible en el prompt del agente (contexto inline)
- Ideal para datos universales y pocos cambios diarios
- Se consolida automáticamente mediante la rutina EOD

**Limitaciones para onboarding:**
- Si se mezclan allí todos los empleados, el archivo crece linealmente con cada nuevo onboarding
- No hay búsqueda semántica — el agente debe escanear secuencialmente
- Un empleado en estado `AUTENTICACIÓN` entre 50 empleados sería difícil de localizar sin herramientas externas

### `/memory/` — Archivos individuales por empleado (estado transaccional)

La carpeta `/memory/` contiene un archivo por empleado con los campos estructurados (Nombre, Correo, Estado, Código, Entregables). Es el modelo de datos transaccional del sistema de onboarding.

### QMD — Motor de búsqueda semántica y BM25

QMD indexa todo el workspace (incluyendo `MEMORY.md` y `/memory/`) y permite tres modos de búsqueda:

| Modo | Descripción | Cuándo usarlo |
|------|-------------|---------------|
| `qmd search "término"` | BM25 (búsqueda por palabras clave) | Buscar por nombre exacto o código |
| `qmd vsearch "término"` | Búsqueda por similitud semántica (vectores) | Buscar por concepto ("empleados en autenticación") |
| `qmd query "término"` | Híbrido BM25 + vectores + rerank | Lo mejor de ambos mundos |

**¿Por qué QMD es la estrategia más coherente?**

1. **Persistencia nativa:** Los archivos individuales en `/memory/` ya existen como markdown plano. QMD los indexa sin necesidad de base de datos externa.
2. **Búsqueda por código de verificación:** `qmd search "X7K9M2"` encuentra instantáneamente el archivo del empleado asociado a ese código.
3. **Clasificación por estado:** `qmd vsearch "empleado en estado autenticación pendiente"` encuentra semánticamente todos los archivos en ese estado.
4. **Sin dependencia de contexto:** El agente no necesita tener el contenido del archivo en su prompt inmediato — QMD lo recupera bajo demanda.
5. **Escalable:** 50, 100 o 200 empleados no degradan el rendimiento porque el índice usa BM25 + embeddings locales (sin API externa).

---

## Amnesia de Contexto

**¿Qué debe recordar el agente si reinicia mañana?**

Si el agente se reinicia y pierde el contexto de la sesión anterior, debe poder reconstruir el estado completo del sistema de onboarding. Aquí está exactamente qué datos persisten y cómo recuperarlos.

### Datos persistentes

| Dato | Dónde se guarda | Cómo lo recupera QMD | Ejemplo de consulta |
|------|-----------------|----------------------|---------------------|
| Nombre del empleado | `/memory/<slug>.md` → campo `Nombre` | BM25 por nombre | `qmd search "Ana García López"` |
| Correo electrónico | `/memory/<slug>.md` → campo `Correo` | BM25 por correo | `qmd search "ana.garcia@trackflow.com"` |
| Departamento asignado | `/memory/<slug>.md` → campo `Departamento` | Búsqueda semántica | `qmd vsearch "departamento atención al cliente"` |
| Estado actual del flujo | `/memory/<slug>.md` → campo `Estado` | Búsqueda semántica | `qmd vsearch "empleados en autenticación"` |
| Código de verificación | `/memory/<slug>.md` → campo `Código de Verificación` | BM25 exacto | `qmd search "X7K9M2"` |
| Entregables recibidos/pendientes | `/memory/<slug>.md` → sección `Entregables` | BM25 + semántica | `qmd search "NDA PENDIENTE"` |
| Resumen diario consolidado | `MEMORY.md` → sección `[YYYY-MM-DD]` | Precargado en contexto | — |
| Log de aprobaciones | `logs/pairing-audit.log` | — | Lectura directa del archivo |

### Verificación post-reinicio

Para confirmar que la memoria se recuperó correctamente tras un reinicio, el agente debe ejecutar estas comprobaciones:

```bash
# 1. Verificar que QMD tiene el índice actualizado
qmd status

# 2. Buscar un empleado conocido por nombre
qmd search "Ana García López"

# 3. Buscar empleados en un estado específico
qmd vsearch "empleados en autenticación pendientes"

# 4. Buscar por código de verificación
qmd search "X7K9M2"

# 5. Leer el archivo de un empleado específico
qmd get qmd://trackflow-memory/ana-garcia.md

# 6. Verificar el log de aprobaciones
tail -5 logs/pairing-audit.log
```

Si todas las consultas devuelven los resultados esperados, la recuperación fue exitosa. De lo contrario, ejecutar `qmd update` para reindexar.

---

## Instalación y Activación de QMD

### Estado actual (ya instalado)

QMD ya está instalado como binario (`/usr/bin/qmd v2.5.3`) y configurado en `openclaw.json`. Sin embargo, es necesario sincronizar la configuración con el workspace trackflow.

### Configuración en `openclaw.json`

```json
{
  "memory": {
    "backend": "qmd",
    "qmd": {
      "command": "/usr/bin/qmd",
      "searchMode": "search",
      "update": {
        "interval": "5m",
        "startup": "idle"
      },
      "paths": [
        {
          "name": "trackflow",
          "path": "/root/.openclaw/workspace-trackflow",
          "pattern": "**/*.md"
        }
      ]
    },
    "citations": "auto"
  }
}
```

### Colecciones a crear

```bash
# Colección para el workspace trackflow
qmd collection add /root/.openclaw/workspace-trackflow \
  --name trackflow \
  --mask "**/*.md"

# Colección específica para memoria de empleados
qmd collection add /root/.openclaw/workspace-trackflow/memory \
  --name trackflow-memory \
  --mask "**/*.md"

# Actualizar el índice
qmd update

# Generar embeddings (búsqueda semántica)
qmd embed
```

### Verificación de funcionamiento

```bash
# Estado del índice
qmd status

# Debe mostrar:
# - Documents: Total: ~15 files indexed
# - Vectors: ~15 embedded
# - Collections: trackflow, trackflow-memory
```

---

## Consulta de Prueba Simulada

### Escenario

El agente necesita encontrar el estado actual del empleado **Ana García López**, quien está en proceso de onboarding con código de verificación **X7K9M2**.

### Consulta BM25 (por palabras clave)

```bash
qmd search "Ana García"
```

**Resultado esperado:**

```
📄 qmd://trackflow-memory/ana-garcia.md
# Estado de Empleado

- **Nombre:** Ana García López
- **Correo:** ana.garcia@trackflow.com
- **Departamento:** Atención al Cliente
- **Estado:** AUTENTICACIÓN
- **Código de Verificación:** X7K9M2
- **Entregables:**
  - NDA: PENDIENTE
  - ERP: PENDIENTE
  - SGA/Tickets: PENDIENTE
- **Fecha de Creación:** 2026-07-11
- **Última Actualización:** 2026-07-11 14:00:00 UTC
```

### Consulta semántica (por concepto)

```bash
qmd vsearch "empleados esperando verificación de código"
```

**Resultado esperado:**

```
1. qmd://trackflow-memory/ana-garcia.md (score: 0.89)
   - **Estado:** AUTENTICACIÓN
   - **Código de Verificación:** X7K9M2

2. qmd://trackflow-memory/carlos-mendez.md (score: 0.87)
   - **Estado:** AUTENTICACIÓN
   - **Código de Verificación:** A3B8C1
```

### Consulta por código exacto

```bash
qmd search "X7K9M2"
```

**Resultado esperado:**

```
📄 qmd://trackflow-memory/ana-garcia.md
  Contiene: 'Código de Verificación: X7K9M2'
```

### Lectura directa del archivo

```bash
qmd get qmd://trackflow-memory/ana-garcia.md -l 20
```

**Resultado esperado:** Las primeras 20 líneas del archivo, mostrando todos los campos del empleado.

---

## Flujo completo de memoria post-reinicio

```
Sesión iniciada → QMD status (verificar índice)
               → qmd vsearch "empleados activos y pendientes"
               → qmd get para cada empleado encontrado
               → Reporte matutino a RRHH
               → Continuar flujo de onboarding
```
