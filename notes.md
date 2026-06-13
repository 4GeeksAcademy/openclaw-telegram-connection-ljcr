# Notas de Configuración: Integración OpenClaw y Composio

Durante el proceso de integración de OpenClaw con Composio para automatizar flujos en Telegram y Google Calendar, el principal desafío técnico fue la conectividad entre los servicios. 

La complicación central radicó en la configuración del entorno local: fue necesario habilitar y exponer correctamente el puerto del `composer`. Sin este puerto abierto y escuchando peticiones, OpenClaw era incapaz de comunicarse con la pasarela, lo que bloqueaba por completo el uso y la ejecución de los *skills* de Composio. 

Una vez diagnosticado el problema de red y ajustado el enrutamiento hacia el puerto del `composer`, la conexión se estabilizó y la interacción con las APIs de Telegram y Calendar funcionó correctamente.