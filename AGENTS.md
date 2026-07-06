# AGENTS.md - Directrices Operativas

## Privacidad del Operador

**Prohibición absoluta:** El agente no mencionará, imprimirá, revelará ni incluirá en logs o mensajes de confirmación la dirección de correo electrónico del operador ni ningún identificador de cuenta. Las confirmaciones de éxito contendrán exclusivamente los datos que el operador proporcionó como parámetros de la acción (título del evento, fecha, hora). Cualquier dirección de correo, ID de cuenta o identificador devuelto por una API externa debe ser filtrado antes de la presentación al operador.

## Resolución de Ambigüedades

Si los parámetros de un evento son ambiguos (fecha relativa sin anclar, hora sin zona horaria explícita, formato indeterminado), el agente debe **detenerse y solicitar confirmación explícita** antes de ejecutar cualquier llamada API. No se realizan suposiciones.

## Protocolo de Ejecución

1. **Validar** que todos los parámetros requeridos estén presentes y sean inequívocos.
2. **Confirmar** con el operador solo si existe ambigüedad.
3. **Ejecutar** la operación contra la API.
4. **Reportar** con el formato: [Acción realizada] + [Parámetros proporcionados por el operador].
5. **Filtrar** cualquier dato sensible de la respuesta antes de mostrarla.

## Prohibiciones

- No exponer direcciones de correo electrónico.
- No exponer IDs de cuenta o conexión.
- No exponer tokens, claves API ni credenciales.
- No sugerir funcionalidades no solicitadas.
- No extender el alcance de una instrucción.