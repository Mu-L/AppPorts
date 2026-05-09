---
outline: deep
---

# Implementación Básica de Migración de Datos

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.05.png)

La función de migración de datos de AppPorts migra los directorios de datos asociados a las aplicaciones (como `~/Library/Application Support`, `~/Library/Caches`, etc.) al almacenamiento externo para liberar espacio en el disco local.

## Estrategia Principal: Enlace Simbólico

La migración del directorio de datos utiliza la estrategia **Whole Symlink**:

1. Copia el directorio local original completo al almacenamiento externo
2. Escribe metadatos de enlace gestionado (`.appports-link-metadata.plist`) en el directorio externo
3. Elimina el directorio local original
4. Crea un enlace simbólico en la ruta original apuntando a la copia externa

```
~/Library/Application Support/SomeApp
    → /Volumes/External/AppPortsData/SomeApp  (symlink)
```

## Flujo de Migración

```mermaid
flowchart TD
    A[Seleccionar directorio de datos] --> B{Verificación de permisos y protección}
    B -->|Falló| Z[Terminar]
    B -->|Aprobado| C{Detección de conflicto de ruta destino}
    C -->|Tiene metadatos gestionados| D[Modo de recuperación automática]
    C -->|Sin conflicto| E[Copiar al almacenamiento externo]
    D --> E
    E --> F[Escribir metadatos de enlace gestionado]
    F --> G[Eliminar directorio local]
    G -->|Falló| H[Rollback: eliminar copia externa]
    G -->|Éxito| I[Crear enlace simbólico]
    I -->|Falló| J[Rollback de emergencia: copiar de vuelta a local]
    I -->|Éxito| K[Migración completada]
```

## Metadatos de Enlace Gestionado

AppPorts escribe un archivo `.appports-link-metadata.plist` en el directorio externo para identificar que el directorio es gestionado por AppPorts. Los metadatos incluyen:

| Campo | Descripción |
|-------|-------------|
| `schemaVersion` | Número de versión de metadatos (actualmente 1) |
| `managedBy` | Identificador del gestor (`com.shimoko.AppPorts`) |
| `sourcePath` | Ruta local original |
| `destinationPath` | Ruta destino del almacenamiento externo |
| `dataDirType` | Tipo de directorio de datos |

Estos metadatos se utilizan durante el escaneo para distinguir los enlaces gestionados por AppPorts de los enlaces simbólicos creados por el usuario, y soportan la recuperación automática cuando la migración se interrumpe.

## Tipos de Directorios de Datos Soportados

| Tipo | Ejemplo de Ruta |
|------|----------------|
| `applicationSupport` | `~/Library/Application Support/` |
| `preferences` | `~/Library/Preferences/` |
| `containers` | `~/Library/Containers/` |
| `groupContainers` | `~/Library/Group Containers/` |
| `caches` | `~/Library/Caches/` |
| `webKit` | `~/Library/WebKit/` |
| `httpStorages` | `~/Library/HTTPStorages/` |
| `applicationScripts` | `~/Library/Application Scripts/` |
| `logs` | `~/Library/Logs/` |
| `savedState` | `~/Library/Saved Application State/` |
| `dotFolder` | `~/.npm`, `~/.vscode`, etc. |
| `custom` | Ruta definida por el usuario |

## Flujo de Restauración

1. Verificar que la ruta local es un enlace simbólico que apunta a un directorio externo válido
2. Eliminar el enlace simbólico local
3. Copiar el directorio externo de vuelta a local
4. Eliminar el directorio externo (mejor esfuerzo)

Si la copia falla, se reconstruye automáticamente el enlace simbólico para mantener la consistencia.

## Manejo de Errores y Rollback

Cada paso crítico en el proceso de migración incluye mecanismos de rollback:

- **Fallo en la copia**: No se toman más acciones; se limpian los archivos externos copiados
- **Fallo al eliminar directorio local**: Se elimina la copia externa, se restaura el estado original
- **Fallo al crear enlace simbólico**: Se copian los datos del externo de vuelta a local, se elimina la copia externa

Este diseño garantiza que no se pierdan datos y que el estado del sistema sea consistente en caso de fallo en cualquier etapa.
