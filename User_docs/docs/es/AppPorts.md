---
outline: deep
---

# Guía del Usuario de AppPorts

Esta guía presenta de forma sistemática las características, principios de diseño e implementación técnica de AppPorts. Para más detalles técnicos, consulte [DeepWiki](https://deepwiki.com/wzh4869/AppPorts). Para sugerencias de mejora, envíelas a los [Issues](https://github.com/wzh4869/AppPorts/issues) del proyecto.

## Visión General

AppPorts es una herramienta de migración y vinculación de aplicaciones diseñada para [macOS](https://www.apple.com/macos/), que admite la migración de aplicaciones grandes a dispositivos de almacenamiento externo manteniendo toda la funcionalidad y consistencia del sistema.

### Filosofía de AppPorts

| Principio | Descripción |
|-----------|-------------|
| **Experiencia Transparente** | Garantiza que la experiencia del usuario y el sistema operativo perciban la aplicación como si aún se ejecutara desde el almacenamiento interno |
| **Estrategia Estable** | Prioriza enfoques de migración probados y más estables |
| **Baja Carga del Sistema** | Sin demonios, evita el consumo continuo de recursos del sistema |
| **Amplia Internacionalización** | Prioriza cubrir más idiomas; amplitud de traducción sobre precisión |
| **Accesible** | Soporte integral de accesibilidad |

## Características Principales

- **Migración sin Marcadores**: Migración con un solo clic de aplicaciones grandes a discos externos. Localmente solo se retiene un shell lanzador ligero; Finder no muestra flechas de acceso directo; Launchpad y el menú de aplicaciones de macOS funcionan normalmente.
- **Protección de Actualización Automática**: Detecta automáticamente aplicaciones con soporte de actualización automática (Sparkle, Electron, Chrome, etc.), proporcionando una opción de "Migración Bloqueada" para evitar que los actualizadores automáticos eliminen o sobrescriban aplicaciones en el disco externo.
- **Gestión de Firma de Código**: Después de la migración, si aparece un mensaje de "Dañado", se puede volver a firmar con un solo clic mediante el menú contextual. Admite copia de seguridad y restauración de firmas originales; refirmado automático después de la migración del directorio de datos.
- **Soporte App Store en macOS 15.1+**: Admite la instalación de aplicaciones de App Store directamente en discos externos con actualizaciones in situ en el disco externo.
- **Restauración con Un Solo Clic**: Admite la migración de aplicaciones de vuelta al almacenamiento local con eliminación automática de enlaces. Recuperación automática en caso de migración interrumpida.
- **Gestión del Directorio de Datos**: Admite la migración de directorios de datos de aplicaciones (subdirectorios de `~/Library/`, `~/.npm`, etc.) al almacenamiento externo, con vista de árbol, búsqueda y ordenación.

## Glosario

### Estrategias de Migración

#### Deep Contents Wrapper (Migración del Directorio Contents)

La estructura estándar de archivos de una aplicación macOS es la siguiente:

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

La estrategia Deep Contents Wrapper migra todo el contenido de la aplicación al almacenamiento externo, creando un directorio `.app` vacío localmente con solo un enlace simbólico que apunta al directorio `Contents` externo. Dado que macOS detecta un paquete `.app` completo (en lugar de un acceso directo), Finder no muestra marcadores de flecha; los iconos, Launchpad y los menús de aplicaciones funcionan normalmente.

::: warning ⚠️ Esta estrategia está obsoleta en la versión actual
El principal defecto de Deep Contents Wrapper es que los actualizadores automáticos siguen los enlaces simbólicos y modifican directamente los archivos en el almacenamiento externo, lo que puede corromper la aplicación.
:::

#### Stub Portal

El enfoque Stub Portal crea un shell `.app` mínimo localmente, que contiene solo estos cuatro elementos:

| Componente | Descripción |
|-----------|-------------|
| `Contents/MacOS/launcher` | Script de lanzamiento Bash que ejecuta `open "/Volumes/External/SomeApp.app"` |
| `Contents/Resources/` | Archivo de icono copiado de la aplicación externa |
| `Contents/Info.plist` | Simplificado del `Info.plist` de la aplicación externa, con `CFBundleExecutable` establecido en `launcher`, `LSUIElement=true` (no se muestra en el Dock), y todas las claves de configuración relacionadas con actualizaciones eliminadas |
| `Contents/PkgInfo` | Archivo identificador estándar de 4 bytes |

Cuando el usuario hace clic en este shell, macOS ejecuta el script `launcher`, abriendo la aplicación real en el disco externo mediante el comando `open`. No hay enlaces simbólicos presentes localmente; los actualizadores automáticos no pueden penetrar.

##### Stub Portal de iOS

El principio básico es el mismo que el Stub Portal estándar, pero el manejo de iconos es diferente. Los iconos de aplicaciones iOS no se especifican en `Info.plist`, sino que se almacenan como múltiples archivos `AppIcon.png` en los directorios `Wrapper/` o `WrappedBundle/`. El proceso es:

1. Encontrar el archivo `AppIcon.png` de mayor resolución
2. Usar `sips` para escalar a 256×256 píxeles
3. Usar `sips` para convertir al formato `.icns`
4. Generar `Info.plist` desde `iTunesMetadata.plist` (las aplicaciones iOS no incluyen un `Info.plist` estándar)

#### Whole Symlink

Crea el directorio `.app` completo como un enlace simbólico al almacenamiento externo:

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

Solo se retiene un enlace simbólico localmente sin archivos reales. macOS puede abrir la aplicación normalmente, pero Finder muestra marcadores de flecha de acceso directo en el icono, y Launchpad ocasionalmente tiene problemas de compatibilidad. Los actualizadores automáticos también pueden operar en los archivos de la aplicación externa a través del enlace simbólico. Esta es la estrategia de migración de respaldo de AppPorts.
