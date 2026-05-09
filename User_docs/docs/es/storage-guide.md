---
outline: deep
---

# Guía de Almacenamiento Externo

## Configuración Recomendada

| Configuración | Valor Recomendado | Descripción |
|---------------|-------------------|-------------|
| Capacidad | 256 GB o superior | Depende del número de aplicaciones migradas |
| Interfaz | USB 3.0 o superior / Thunderbolt | USB 2.0 es lento; la migración de apps grandes tarda más |
| Sistema de Archivos | APFS | Soporta clones, snapshots, mejor rendimiento |

## Comparación de Rendimiento de Interfaces

| Interfaz | Velocidad Teórica | Velocidad Real de Migración | Caso de Uso |
|----------|-------------------|---------------------------|-------------|
| USB 2.0 | 480 Mbps | ~30 MB/s | No recomendado; demasiado lento |
| USB 3.0 (USB-A) | 5 Gbps | ~350 MB/s | Básicamente suficiente |
| USB 3.1 Gen 2 (USB-C) | 10 Gbps | ~700 MB/s | Recomendado |
| Thunderbolt 3/4 | 40 Gbps | ~2500 MB/s | Mejor rendimiento |
| NVMe (Thunderbolt) | 40 Gbps | ~2800 MB/s | Mejor rendimiento |

## Recomendaciones de Sistema de Archivos

### APFS (Recomendado)

- Soporta clones, snapshots, compartición de espacio
- Mejor rendimiento, especialmente para SSDs
- Soporte nativo de macOS

### HFS+

- Buena compatibilidad; adecuado para Macs más antiguos
- No soporta clones ni snapshots
- Adecuado para discos duros mecánicos

### exFAT

- Compatible multiplataforma (macOS + Windows)
- No soporta enlaces duros ni clones
- Rendimiento relativamente menor
- Adecuado para escenarios que requieren uso en múltiples sistemas

## Planificación de Capacidad

El uso de almacenamiento externo de AppPorts después de la migración depende del tamaño de las aplicaciones y directorios de datos migrados. A continuación se muestran tamaños de referencia para apps comunes:

| Tipo de App | Tamaño |
|-------------|--------|
| Chrome | ~500 MB |
| Microsoft Office | ~5 GB |
| Adobe Creative Cloud | ~20-50 GB |
| Xcode | ~15 GB |
| Final Cut Pro | ~5 GB |
| Modelos de lenguaje grandes locales (Ollama) | ~4-30 GB |

::: tip 💡 Recomendaciones de Capacidad
- Uso ligero (5-10 apps): 128 GB
- Uso medio (10-20 apps): 256 GB
- Uso intensivo (20+ apps + directorios de datos): 512 GB o superior
:::

## Notas

- El almacenamiento externo debe permanecer conectado; las aplicaciones y directorios de datos migrados no pueden usarse sin conexión
- Haga copias de seguridad periódicas de los datos en el almacenamiento externo
- Evite desconectar el almacenamiento externo durante la migración
- Si el almacenamiento externo falla, puede mover las apps de vuelta a local vía AppPorts
