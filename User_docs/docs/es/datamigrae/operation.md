---
outline: deep
---

# Guía de Operación de Migración de Datos

Esta página cubre el flujo de trabajo práctico para la migración de directorios de datos. Para detalles de implementación técnica, consulte [Implementación Básica](/es/datamigrae/baseinfo).

## Encontrar Directorios de Datos Asociados a Aplicaciones

1. Cambie a la pestaña "Directorios de Datos" en la ventana principal de AppPorts
2. El panel izquierdo muestra todas las aplicaciones instaladas
3. Haga clic en una aplicación; el panel derecho muestra sus directorios de datos asociados bajo `~/Library/`

AppPorts escanea automáticamente los siguientes directorios, haciendo coincidir por Bundle ID o nombre de la aplicación:

| Ruta de Escaneo | Método de Coincidencia |
|-----------------|----------------------|
| `~/Library/Application Support/` | Bundle ID o nombre de app |
| `~/Library/Preferences/` | Bundle ID o nombre de app |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID o nombre de app |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | Nombre de app |
| `~/Library/Saved Application State/` | Nombre de app |

## Directorios de Herramientas (Dot-Folders)

AppPorts puede detectar automáticamente dot-folders creados por herramientas de desarrollo comunes en el directorio home del usuario:

1. Cambie a la subpestaña "Directorios de Herramientas" en la pestaña Directorios de Datos
2. La página lista todos los directorios de herramientas detectados con sus tamaños
3. Cada directorio muestra un marcador de prioridad (recommended/optional) y estado

Para la lista completa soportada, consulte [Detección de Directorios de Herramientas](/es/datamigrae/tools).

## Operaciones de Migración

### Migración de Directorio Individual

1. Encuentre el directorio a migrar en la lista de directorios de datos
2. Haga clic en el botón "Migrar" a la derecha
3. AppPorts ejecuta los siguientes pasos:
   - Copia el directorio al almacenamiento externo
   - Escribe metadatos de enlace gestionado
   - Elimina el directorio local original
   - Crea un enlace simbólico

### Migración por Lotes

1. Marque múltiples directorios en la lista de directorios de herramientas
2. Haga clic en el botón "Migración por Lotes" en la parte inferior
3. AppPorts ejecuta la migración secuencialmente

::: tip 💡 Recomendaciones de Prioridad
Los directorios de datos se clasifican en tres niveles de prioridad:

- **Crítico** (`critical`): Debe funcionar después de la migración; afecta la funcionalidad principal de la aplicación
- **Recomendado** (`recommended`): Gran ahorro de espacio; alto beneficio de migración
- **Opcional** (`optional`): Tamaño pequeño o reconstruible

Se recomienda priorizar la migración de directorios marcados como "Recomendado".
:::

## Operaciones de Restauración

1. Encuentre el directorio migrado en la lista de directorios de datos (estado: "Vinculado")
2. Haga clic en el botón "Restaurar" a la derecha
3. AppPorts ejecuta los siguientes pasos:
   - Elimina el enlace simbólico local
   - Copia los datos del almacenamiento externo de vuelta a local
   - Elimina el directorio externo (mejor esfuerzo)

## Manejo de Estados Anormales

### Necesita Normalización

El directorio es gestionado por AppPorts, pero la ruta externa no está en la ubicación canónica. Haga clic en "Normalizar"; AppPorts moverá los datos externos a la ruta canónica y reconstruirá el enlace simbólico.

### Necesita Revinculación

Los datos del almacenamiento externo aún existen, pero el enlace simbólico local se perdió. Haga clic en "Revincular"; AppPorts recreará el enlace simbólico.

### Enlace Suave Existente

Un enlace simbólico creado por el usuario, no por AppPorts. Puede elegir "Tomar Control"; AppPorts escribirá metadatos de enlace gestionado y lo gestionará en adelante.

## Vista de Árbol

Para directorios de datos que contienen subdirectorios (ej., múltiples directorios de aplicaciones bajo `Application Support`), AppPorts proporciona una vista de agrupación en árbol:

- El directorio principal muestra flechas de expandir/colapsar a la izquierda
- Los subdirectorios muestran indentación jerárquica
- Cada nodo muestra independientemente el tamaño y estado
- Las operaciones de migración/restauración pueden realizarse en subdirectorios individuales
