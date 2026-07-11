# trackflow-pairing — Aprobación de Pairing vía Código de Verificación

## Descripción

Gestiona la aprobación de pairing de nuevos empleados en TrackFlow mediante un
código de verificación alfanumérico. El flujo completo es:

1. **RRHH** notifica a FlowBot por Telegram con el nombre y correo del nuevo empleado.
2. **FlowBot** envía al empleado un email de bienvenida y genera un código de verificación.
3. **FlowBot** entrega el código al empleado por Telegram.
4. **RRHH** recibe el código del empleado y se lo pasa a FlowBot.
5. **FlowBot** ejecuta el script `approve-pairing.sh` con el código como argumento
   para aprobar el pairing automáticamente.

## Requisitos

- Bash 4.0+
- Directorio `/memory/` en el workspace con archivos de estado de empleados
- Directorio `logs/` en el workspace para registro de aprobaciones

## Uso

```bash
./scripts/approve-pairing.sh --code <VERIFICATION_CODE>
```

## Formato del archivo de empleado en `/memory/`

Cada empleado tiene un archivo en `/memory/` con el siguiente formato:

```markdown
# Estado de Empleado

- **Nombre:** [Nombre Completo]
- **Correo:** [email@dominio.com]
- **Departamento:** [Departamento]
- **Estado:** [NO_INICIADO | AUTENTICACIÓN | ACTIVO | TERMINADO]
- **Código de Verificación:** [código alfanumérico]
- **Entregables:**
  - NDA: [PENDIENTE / RECIBIDO]
  - ERP: [PENDIENTE / RECIBIDO]
  - SGA/Tickets: [PENDIENTE / RECIBIDO]
- **Fecha de Creación:** [YYYY-MM-DD]
- **Última Actualización:** [YYYY-MM-DD HH:MM:SS UTC]
```

## Estados

| Estado | Descripción |
|--------|-------------|
| NO_INICIADO | Empleado registrado por RRHH, email de bienvenida enviado |
| AUTENTICACIÓN | Código generado y entregado al empleado, esperando confirmación |
| ACTIVO | Pairing aprobado, entregables enviados |
| TERMINADO | Todos los entregables recibidos |
