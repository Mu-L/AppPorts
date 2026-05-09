---
outline: deep
---

# Compatibilidad y Limitaciones

## Requisitos del Sistema

| Requisito | Descripción |
|-----------|-------------|
| Versión mínima del SO | macOS 12.0 (Monterey) |
| Arquitectura | Intel x86_64 / Apple Silicon (arm64) |
| Permisos | Acceso Total al Disco |
| Almacenamiento Externo | Se requiere al menos un dispositivo de almacenamiento externo |

## Compatibilidad de Características

### Por Versión de macOS

| Característica | macOS 12.0 - 15.0 | macOS 15.1+ |
|----------------|:---:|:---:|
| Migración de Apps (Stub Portal) | ✓ | ✓ |
| Migración de Directorios de Datos | ✓ | ✓ |
| Gestión de Firma de Código | ✓ | ✓ |
| Migración de Apps App Store a Disco Externo | ✗ | ✓ |
| Actualización In Situ de Apps App Store en Disco Externo | ✗ | ✓ |
| Migración de Apps iOS | ✓ | ✓ |

::: warning ⚠️ Apps de App Store en Versiones de macOS Inferiores a 15.1
Las versiones de macOS anteriores a 15.1 (Sequoia) no soportan la instalación de apps de App Store en discos externos. Necesita habilitar manualmente "Migración de Apps App Store" en la configuración de AppPorts, y las actualizaciones de apps requieren re-migración manual para sobrescribir.
:::

### Por Tipo de App

| Tipo de App | Migración | Restauración | Auto-Actualización | Notas |
|-------------|:---:|:---:|:---:|-------|
| App macOS nativa | ✓ | ✓ | ✓ | Mejor compatibilidad |
| App Sparkle | ✓ | ✓ | Requiere bloqueo | El bloqueo previene actualizaciones en la app; debe restaurar para actualizar |
| App Electron | ✓ | ✓ | Requiere bloqueo | Igual que Sparkle |
| Chrome / Edge (actualizador personalizado) | ✓ | ✓ | ✓ | El actualizador instala en local; no daña la copia externa |
| App Store (macOS 15.1+) | ✓ | ✓ | ✓ | Instalación externa nativa; App Store puede actualizar directamente |
| App Store (macOS <15.1) | ✓ | ✓ | Manual | Las actualizaciones requieren re-migración |
| App iOS (versión Mac) | ✓ | ✓ | ✓ | Usa iOS Stub Portal |
| Apps del sistema | ✗ | — | — | Protección SIP; no se pueden migrar |

### Por Tipo de Directorio de Datos

| Tipo de Directorio de Datos | Migración | Riesgo |
|-----------------------------|:---:|------|
| `~/Library/Application Support/` | ✓ | Medio — puede usar bloqueos de archivos o registros WAL de SQLite |
| `~/Library/Preferences/` | ✓ | Bajo-Medio — el caché de `cfprefsd` puede causar lecturas obsoletas |
| `~/Library/Containers/` | ✓ | Medio — compartido por apps bajo el mismo Team |
| `~/Library/Group Containers/` | ✓ | Medio — datos compartidos pueden interferir con otras apps |
| `~/Library/Caches/` | ✓ | Bajo — los cachés son reconstruibles |
| `~/Library/Logs/` | ✓ | Bajo — solo archivos de registro |
| `~/Library/WebKit/` | ✓ | Medio — almacenamiento local de WebKit |
| `~/Library/HTTPStorages/` | ✓ | Bajo — almacenamiento de sesiones de red |
| `~/Library/Application Scripts/` | ✓ | Bajo — scripts de extensiones |
| `~/Library/Saved Application State/` | ✓ | Bajo — restauración de estado de ventanas |
| `~/.npm`, `~/.m2` etc. dot-folder | ✓ | Bajo — cachés de herramientas de desarrollo |

## Contenido No Migrable

### Protegido por SIP

| Ruta | Razón |
|------|-------|
| Apps del sistema macOS (Safari, Finder, etc.) | Protección de Integridad del Sistema |
| Directorio de nivel superior `~/Library/Containers/` | Protección del sistema macOS |

### Contiene Referencias de Rutas

| Ruta | Razón |
|------|-------|
| `~/.local` | Contiene referencias de rutas ejecutables; las herramientas de línea de comandos pueden fallar después de la migración |
| `~/.config` | Contiene configuraciones de rutas absolutas; las configuraciones de herramientas pueden fallar después de la migración |

## Requisitos de Almacenamiento Externo

| Requisito | Descripción |
|-----------|-------------|
| Sistema de Archivos | APFS, HFS+, exFAT soportados |
| Espacio Mínimo | Depende del tamaño de las aplicaciones migradas |
| Interfaz | USB, Thunderbolt, NVMe todos soportados |
| Mantener Conectado | El almacenamiento externo debe permanecer conectado después de la migración; de lo contrario las apps no pueden iniciarse |

::: tip 💡 Recomendaciones de Sistema de Archivos
- **APFS**: Recomendado; soporta clones, snapshots, mejor rendimiento
- **HFS+**: Buena compatibilidad; adecuado para Macs más antiguos
- **exFAT**: Compatible multiplataforma; no soporta enlaces duros ni clones
:::
