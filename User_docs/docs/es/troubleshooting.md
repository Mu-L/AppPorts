---
outline: deep
---

# Solución de Problemas

## Interrupción de Migración

### Síntomas

Migración interrumpida debido a desconexión del almacenamiento externo, fallo del sistema o cierre forzado de la aplicación.

### Solución

AppPorts tiene un mecanismo de recuperación automática integrado. Después de reiniciar AppPorts:

1. Detecta datos de migración residuales (copia externa existe pero el enlace simbólico local no fue creado)
2. Compara automáticamente los tamaños de directorios local y externo (umbral del 90%)
3. Si los datos están completos, completa automáticamente la migración (elimina directorio local original, crea enlace simbólico)
4. Si los datos están incompletos, limpia la copia externa residual y restaura el estado original

::: tip 💡 No Se Necesita Intervención Manual
El mecanismo de recuperación automática de AppPorts maneja las migraciones interrumpidas en el siguiente inicio. Si la recuperación automática falla, puede ver el estado "Necesita Normalización" o "Necesita Revinculación" en la lista de directorios de datos — simplemente ejecute la operación correspondiente manualmente.
:::

## Almacenamiento Externo Desconectado

### Síntomas

Después de desconectar o desenchufar el almacenamiento externo, las aplicaciones migradas no pueden iniciarse y los directorios de datos muestran estado de error rojo.

### Solución

1. Reconecte el almacenamiento externo
2. El `FolderMonitor` de AppPorts detecta automáticamente el montaje del volumen de almacenamiento y activa un re-escaneo
3. Las aplicaciones y directorios de datos reanudan el uso normal

::: warning ⚠️ Nota
Mientras el almacenamiento externo está desconectado, las entradas locales (Stub Portal) que llaman a `open` fallarán; las apps no pueden iniciarse pero no fallarán. Los enlaces simbólicos de directorios de datos apuntan a rutas inválidas; las apps asociadas podrían no poder leer datos.
:::

## Fallo de Restauración de Firma

### Síntomas

Intentar restaurar la firma original falla, o la app aún muestra "Dañado" después de la restauración.

### Causas Posibles y Solución

| Causa | Solución |
|-------|----------|
| El archivo de copia de seguridad no existe | No se puede restaurar la firma original; ejecute el re-firmado Ad-hoc como alternativa |
| El certificado de desarrollador original no está en el Keychain local | AppPorts automáticamente hace fallback a firmado Ad-hoc; la app puede iniciarse pero el acceso a Keychain puede ser anormal |
| App de Mac App Store (protección SIP) | No se puede re-firmar; SIP previene cualquier modificación a las firmas de apps del sistema |
| El directorio de la app es propiedad de root | AppPorts intenta cambiar la propiedad mediante privilegios de admin; autorice en la ventana emergente |
| Destino del enlace simbólico Contents perdido | No se puede firmar; debe restaurar los datos externos o restaurar la app primero |

Para mecanismos detallados, consulte [Re-firmado y Prevención de Fallos](/es/datamigrae/resign).

## Las Apps de App Store No Pueden Migrar a Disco Externo

### Versiones de macOS Inferiores a 15.1

Las versiones de macOS anteriores a 15.1 no soportan la instalación de apps de App Store en discos externos. Necesita:

1. Habilitar "Migración de Apps App Store" en la configuración de AppPorts
2. Después de la migración, las actualizaciones de apps requieren re-migración manual para sobrescribir

### macOS 15.1 y Superiores

Si App Store no puede actualizar apps en discos externos:

1. Abra la configuración de App Store
2. Habilite "Descargar e instalar aplicaciones grandes en un disco externo"
3. Seleccione el mismo almacenamiento externo que la biblioteca de almacenamiento externo de AppPorts

## La App No Puede Iniciarse Después de la Migración

### Pasos de Solución de Problemas

1. **Verifique la conexión del almacenamiento externo**: Confirme que el almacenamiento externo esté conectado y accesible
2. **Verifique los marcadores de estado de la app**:
   - "Enlace Huérfano" → App externa perdida; se requiere desvinculación manual
   - "Dañado" → Ejecute el re-firmado
3. **Verifique el estado de bloqueo**: Si la app está bloqueada (uchg), el auto-actualizador podría no poder ejecutarse
4. **Verifique los registros**: Barra de menú → Registros → Ver en Finder; busque mensajes de error relevantes
5. **Mover de vuelta a local**: En la biblioteca de Aplicaciones Externas, seleccione "Mover de Vuelta a Local" para confirmar si es un problema del almacenamiento externo

## Problemas de Visualización de Directorios de Datos

### Síntomas

La lista de directorios de datos muestra estado incompleto o incorrecto.

### Solución

1. AppPorts usa `FolderMonitor` para monitorear cambios del sistema de archivos; generalmente se actualiza automáticamente
2. Si no se actualiza automáticamente, cambie a otra pestaña y vuelva para activar un re-escaneo
3. Si el problema persiste, verifique los mensajes de error de escaneo en los registros
