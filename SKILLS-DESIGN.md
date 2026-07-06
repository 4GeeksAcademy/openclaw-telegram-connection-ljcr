Skill 1: Ventanas de Despliegue y Mantenimiento de Servidores

1. ¿Qué hace esta skill?
Programa y estructura bloques de tiempo en Google Calendar dedicados específicamente a tareas de infraestructura, como actualizaciones en el VPS, configuración de LiteLLM o transiciones entre modelos (ej. de deepseek-v3.2 a v4-flash).

2. ¿Qué input necesita el agente?

    Input del usuario: Una instrucción en lenguaje natural indicando la tarea técnica, la fecha y la duración estimada (ej. "Programa una ventana de mantenimiento de 2 horas mañana a las 23:00 para actualizar la configuración de OpenClaw en el servidor").

    Qué ya sabe (Contexto): Gracias a USER.md, sabe que se trata de tareas críticas de backend que requieren concentración. Por AGENTS.md y TOOLS.md, sabe que debe usar Google Calendar y que la confirmación debe ser aséptica y libre de datos personales.

3. ¿Cómo es un buen output?

    Destino: Un evento creado en Google Calendar (marcado como "Ocupado").

    Formato de respuesta (Terminal/Telegram): Un mensaje de confirmación estrictamente formal que cumpla con las reglas de privacidad.

    Criterio de éxito: La respuesta debe verse exactamente así: "Operación completada. Evento creado: [Mantenimiento: Actualización OpenClaw] para el [DD/MM/AAAA] de [HH:MM] a [HH:MM].", sin incluir direcciones de correo en el log o mensaje.

Skill 2: Bloques de Trabajo Profundo (Deep Work) para Desarrollo

1. ¿Qué hace esta skill?
Aisla tiempo en la agenda para sesiones ininterrumpidas de codificación remota en VS Code, bloqueando la disponibilidad para evitar interrupciones durante el desarrollo complejo.

2. ¿Qué input necesita el agente?

    Input del usuario: El objetivo del sprint de código y el tiempo requerido (ej. "Bloquea 3 horas esta tarde para depurar la ruta de red entre el orquestador y el LLM").

    Qué ya sabe (Contexto): Por SOUL.md, sabe que no debe hacer preguntas redundantes y debe ejecutar la acción directamente si los parámetros de tiempo son claros.

3. ¿Cómo es un buen output?

    Destino: Un evento en Google Calendar.

    Formato de respuesta (Terminal/Telegram): Confirmación directa y concisa.

    Criterio de éxito: Creación del evento y una notificación de la forma: "Operación completada. Evento creado: [Trabajo Profundo: Depuración de red] - [Fecha y Hora de inicio] a [Fecha y Hora de fin].", validando que el correo electrónico del usuario se ha omitido por completo de la salida.