---
outline: deep
---

# Preguntas Frecuentes

## Instalación y Autorización

### ¿Qué permisos necesita AppPorts?

AppPorts necesita permiso de **Acceso Total al Disco** para leer y modificar el directorio `/Applications`. En el primer inicio, le guiará a través de la autorización. También puede agregarlo manualmente en Configuración del Sistema → Privacidad y Seguridad → Acceso Total al Disco.

### ¿Qué versiones de macOS son compatibles?

El soporte mínimo es macOS 12.0 (Monterey). macOS 15.1 (Sequoia) y posteriores además soportan la instalación de apps de App Store en discos externos con actualizaciones in situ.

## Migración de Aplicaciones

### ¿Qué hago si la app no abre después de la migración?

1. Confirme que el almacenamiento externo esté conectado y accesible
2. Verifique el marcador de estado de la app: Si "Enlace Huérfano", la app externa se perdió; se requiere desvinculación manual
3. Si aparece un mensaje de "Dañado", haga clic derecho en la app y seleccione "Re-firmar"
4. Si aún no se resuelve, seleccione "Mover de Vuelta a Local" en la biblioteca de Aplicaciones Externas

### ¿Qué hago si veo un mensaje de "Dañado"?

El mecanismo de firma de código de macOS detectó un cambio en la estructura del paquete de la app. Solución:

1. Haga clic derecho en la app en AppPorts
2. Seleccione "Re-firmar"
3. AppPorts hará automáticamente una copia de seguridad de la firma original y ejecutará el re-firmado Ad-hoc

Para mecanismos detallados, consulte [Re-firmado y Prevención de Fallos](/es/datamigrae/resign).

### ¿La app fallará si se desconecta el almacenamiento externo?

La entrada local (Stub Portal) intentará llamar a `open` para iniciar la app externa. Si el almacenamiento externo no está conectado, la app no puede iniciarse pero no fallará. El uso normal se reanuda después de reconectar el almacenamiento externo.

### ¿Se pueden actualizar las apps después de la migración?

Depende del tipo de app:

| Tipo de App | Puede Auto-Actualizar | Notas |
|-------------|:---:|-------|
| Apps nativas (sin auto-actualización) | ✓ | Actualizaciones normales |
| Chrome, Edge (actualizador personalizado) | ✓ | Las actualizaciones se instalan en local; AppPorts detecta diferencia de versión y etiqueta "Migración Pendiente" |
| Apps Sparkle / Electron | ✗ | El bloqueo previene actualizaciones en la app; debe restaurar a local vía AppPorts antes de actualizar |
| Apps App Store (macOS 15.1+) | ✓ | App Store puede actualizar in situ en el disco externo |
| Apps App Store (macOS <15.1) | ✗ | Se requiere re-migración manual |

### ¿Cómo migrar apps de App Store al disco externo?

**macOS 15.1+**: En la configuración de App Store, habilite "Descargar e instalar aplicaciones grandes en un disco externo", seleccionando el mismo almacenamiento externo que AppPorts.

**macOS <15.1**: En la configuración de AppPorts, habilite "Migración de Apps App Store". Después de la migración manual, las actualizaciones de apps requieren re-migración.

### La migración está lenta/atascada. ¿Qué hacer?

- Al 100% de progreso de migración, puede haber una pausa de 1-2 segundos mientras se crean las entradas locales
- Las apps grandes (ej., Xcode, Adobe) tardan más en migrar — esto es normal
- Si está atascada por mucho tiempo, verifique la estabilidad de la conexión del almacenamiento externo
- USB 2.0 es lento; se recomienda usar USB 3.0 o superior, o Thunderbolt

## Migración de Directorios de Datos

### ¿Se perderán datos después de la migración del directorio de datos?

No. AppPorts usa la estrategia de enlace simbólico: los datos se copian completamente al almacenamiento externo primero; solo después de confirmar la copia exitosa se elimina el directorio local original. Cualquier paso fallido activa un rollback automático.

### ¿Cuándo la migración del directorio de datos puede causar problemas en la app?

- Apps que usan bloqueos de archivos o registros WAL de SQLite
- Los atributos extendidos pueden perderse a través de enlaces simbólicos
- Directorios de Group Containers compartidos por múltiples apps bajo el mismo Team

### ¿Cómo restaurar directorios de datos migrados?

En la interfaz de gestión de directorios de datos de AppPorts, seleccione el directorio migrado y haga clic en "Restaurar". AppPorts eliminará el enlace simbólico y copiará los datos del almacenamiento externo de vuelta a local.

## Otros

### ¿AppPorts recopila mis datos?

No. AppPorts se ejecuta completamente sin conexión y no recopila ni sube ningún dato del usuario. Los archivos de registro se almacenan localmente en `~/Library/Application Support/AppPorts/`.

### ¿Cómo reportar problemas?

Por favor envíelos en la página de [Issues](https://github.com/wzh4869/AppPorts/issues) del proyecto. Se recomienda incluir un paquete de diagnóstico (Barra de menú → Registros → Exportar Paquete de Diagnóstico) para agilizar la resolución del problema.
