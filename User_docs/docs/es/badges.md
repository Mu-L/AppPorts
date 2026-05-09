---
outline: deep
---

# Marcadores de Estado

AppPorts muestra el estado actual de las aplicaciones y directorios de datos mediante marcadores de colores en forma de cápsula. Algunos marcadores son clicables para obtener información detallada.

## Marcadores de Estado de Aplicaciones

### Estado de Vinculación

| Marcador | Icono | Color | Significado |
|----------|-------|-------|-------------|
| Vinculado | `link` | Verde | Aplicación migrada al almacenamiento externo con entrada local |
| Migración Bloqueada | `lock.fill` | Verde | Vinculada y bloqueada con `uchg`, evitando que las auto-actualizaciones dañen la aplicación externa |
| Migración Desbloqueada | `lock.open` | Naranja | Vinculada pero no bloqueada; las actualizaciones dentro de la app pueden eliminar la aplicación externa |
| Vinculación Parcial | `link.badge.plus` | Amarillo | Componentes parciales de la app vinculados (ej., algunos archivos `.app` en un directorio) |
| Enlace Huérfano | `link.badge.exclamationmark` | Rojo | Aplicación del almacenamiento externo perdida pero la entrada local aún existe |
| Desvinculado | `externaldrive.badge.xmark` | Naranja | Aplicación en almacenamiento externo pero no vinculada localmente |
| Externo | `externaldrive` | Naranja | Aplicación en almacenamiento externo sin entrada local |
| Local | `macmini` | Color secundario | Aplicación local regular, no migrada; se muestra cuando no hay otras etiquetas |

### Etiquetas de Framework

| Marcador | Icono | Color | Significado | Acción al Hacer Clic |
|----------|-------|-------|-------------|---------------------|
| Sparkle | `arrow.triangle.2.circlepath` | Cian | Usa el framework Sparkle para actualizaciones automáticas | Después de migrar al almacenamiento externo, las actualizaciones dentro de la app pueden causar pérdida de la aplicación externa; se recomienda migración bloqueada |
| Electron | `atom` | Índigo | Basado en el framework Electron con soporte de actualización automática | Después de migrar al almacenamiento externo, las actualizaciones dentro de la app pueden causar pérdida de la aplicación externa; se recomienda migración bloqueada |

### Etiquetas de Tipo

| Marcador | Icono | Color | Significado |
|----------|-------|-------|-------------|
| En Ejecución | `play.fill` | Púrpura | Aplicación actualmente en ejecución |
| Sistema | `lock.fill` | Gris | Aplicación del sistema macOS |
| No Nativa | `iphone` | Rosa | Aplicación iOS/iPadOS (ejecutándose vía Apple Silicon) |
| Store | `applelogo` | Azul | Aplicación de Mac App Store |

### Etiquetas Especiales

| Marcador | Icono | Color | Significado |
|----------|-------|-------|-------------|
| Re-firmada | `seal.fill` | Cian | La aplicación ha sido re-firmada Ad-hoc (se ejecuta cuando aparece "Dañado" después de la migración) |

::: tip 💡 Nota Especial sobre la Etiqueta Store
Cuando una aplicación cumple las siguientes condiciones, la etiqueta "Store" se vuelve clicable y muestra instrucciones de instalación nativa de macOS 15.1+:
- La aplicación está ubicada en el directorio `/Volumes/{drive}/Applications/` del almacenamiento externo
- Gestionada nativamente por macOS; App Store puede realizar actualizaciones incrementales directamente en este directorio
:::

## Marcadores de Estado de Directorios de Datos

| Estado | Color | Significado |
|--------|-------|-------------|
| Local | Color secundario | Directorio en almacenamiento local, no migrado |
| Vinculado | Verde | Migrado al almacenamiento externo; local es un enlace simbólico |
| Necesita Normalización | Amarillo | Enlace gestionado por AppPorts, pero la ruta externa no está en la ubicación canónica; se recomienda la operación "Normalizar" |
| Necesita Revinculación | Naranja | Datos del almacenamiento externo existen pero el enlace simbólico local se perdió; se recomienda la operación "Revincular" |
| Enlace Suave Existente | Azul | Enlace simbólico creado por el usuario (no creado por AppPorts); opción de tomar el control de la gestión |

## Combinaciones de Estado de Aplicaciones

Una aplicación puede mostrar múltiples marcadores simultáneamente:

```text
[Vinculado] [Sparkle] [En Ejecución]
```
Significado: Aplicación migrada al almacenamiento externo, usa el framework de actualización automática Sparkle, actualmente en ejecución.

```text
[Externo] [Store] [No Nativa]
```
Significado: Aplicación iOS (versión Mac) en almacenamiento externo, instalada vía App Store.

```text
[Enlace Huérfano]
```
Significado: Aplicación del almacenamiento externo perdida o eliminada, pero la entrada local aún se mantiene. Se requiere desvinculación manual.
