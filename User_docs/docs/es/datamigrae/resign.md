---
outline: deep
---

# Re-firmado y Prevención de Fallos

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.37.png)

## Por Qué las Aplicaciones Pueden Fallar Después de la Migración de Datos

El mecanismo de firma de código de macOS (`codesign`) verifica la integridad del paquete de la aplicación, incluyendo la estructura de rutas de archivos. Cuando AppPorts migra el directorio de datos de una aplicación al almacenamiento externo y lo reemplaza con un enlace simbólico, el sello de firma se rompe, causando los siguientes problemas:

- **Bloqueo de Gatekeeper**: `codesign --verify --deep --strict` detecta un fallo de firma; el sistema muestra un diálogo de "Dañado" o "de desarrollador no identificado", bloqueando el inicio de la aplicación
- **Interrupción del Acceso a Keychain**: Las aplicaciones que dependen de grupos de acceso a Keychain no pueden leer las credenciales almacenadas debido a cambios en la identidad de firma
- **Fallo de Entitlements**: Algunos entitlements de aplicaciones están vinculados a la identidad de firma; después de cambios de firma, los entitlements no coinciden

### Tipos de Aplicaciones de Alto Riesgo

| Tipo de App | Nivel de Riesgo | Razón |
|-------------|----------------|-------|
| Apps con auto-actualización Sparkle | **Alto** | El actualizador puede eliminar o reemplazar la app, dañando los enlaces simbólicos |
| Apps con auto-actualización Electron | **Alto** | `electron-updater` también puede interferir con las apps en almacenamiento externo |
| Apps dependientes de Keychain | **Alto** | El firmado Ad-hoc cambia la identidad de firma; los grupos de acceso a Keychain fallan |
| Apps de Mac App Store | **Alto** | Protección SIP; no se pueden re-firmar |
| Apps con auto-actualización nativa (Chrome, Edge) | Medio | La auto-actualización puede reemplazar la copia externa, invalidando la entrada local |
| Apps iOS (versión Mac) | Bajo | Usa Stub Portal o whole symlink; menos problemas de firma |

### Tipos de Directorios de Datos de Alto Riesgo

| Tipo de Datos | Nivel de Riesgo | Razón |
|---------------|----------------|-------|
| `~/Library/Application Support/` | Medio | La app puede usar bloqueos de archivos, registros WAL de SQLite o atributos extendidos; puede comportarse anormalmente a través de enlaces simbólicos |
| `~/Library/Group Containers/` | Medio | Compartido por múltiples apps bajo el mismo Team; los enlaces simbólicos pueden interferir con otras apps |
| `~/Library/Preferences/` | Bajo-Medio | `cfprefsd` cachea archivos plist; los enlaces simbólicos pueden causar lectura de datos obsoletos |
| `~/Library/Caches/` | Bajo | Los cachés son reconstruibles; la mayoría de las apps manejan la ausencia de caché con gracia |

## Mecanismo de Re-firmado

### Firmado Ad-hoc

AppPorts usa **firmado Ad-hoc** (firmado local sin certificado) para corregir las firmas de aplicaciones después de la migración. Comando de ejecución:

```bash
codesign --force --deep --sign - <ruta de la app>
```

Donde `-` indica firmado Ad-hoc (sin certificado de desarrollador).

### Flujo de Firmado

```mermaid
flowchart TD
    A[Iniciar re-firmado] --> B[Hacer copia de seguridad de la identidad de firma original]
    B --> C{¿La app está bloqueada?}
    C -->|Sí| D[Desbloquear temporalmente la bandera uchg]
    C -->|No| E{¿La app es escribible?}
    D --> E
    E =>|No escribible & propiedad root| F[Intentar cambiar propiedad con admin]
    E =>|Escribible| G[Limpiar atributos extendidos]
    F --> G
    F -->|Falló & app MAS| H[Omitir firmado - protección SIP]
    G --> I[Limpiar desorden del directorio raíz del bundle]
    I --> J{¿Contents es un enlace simbólico?}
    J =>|Sí| K[Reemplazar temporalmente con copia real del directorio]
    J =>|No| L[Ejecutar firmado profundo]
    K --> L
    L =>|Falló| M[Fallback a firmado superficial]
    L =>|Éxito| N{¿Contents fue reemplazado temporalmente?}
    M --> N
    N =>|Sí| O[Restaurar enlace simbólico]
    N =>|No| P[Re-bloquear bandera uchg]
    O --> P
    P => Q[Firmado completado]
```

### Pasos Clave

1. **Copia de seguridad de la identidad de firma original**: Antes de firmar, lee la identidad de firma actual de la app (parsea líneas `Authority=` vía `codesign -dvv`), guarda en `~/Library/Application Support/AppPorts/signature-backups/<BundleID>.plist`

2. **Limpiar atributos extendidos**: Ejecuta `xattr -cr` para eliminar resource forks, info de Finder, etc., evitando errores "detritus not allowed" durante el firmado

3. **Limpiar directorio raíz del bundle**: Elimina `.DS_Store`, `__MACOSX`, `.git`, `.svn` y otro desorden

4. **Manejar enlace simbólico Contents**: Si `Contents/` es un enlace simbólico (estrategia Deep Contents Wrapper), lo reemplaza temporalmente con una copia real del directorio, luego restaura el enlace simbólico después del firmado

5. **Firmado profundo → fallback a firmado superficial**: Prefiere firmado `--deep` (cubriendo todos los componentes anidados); si falla por permisos o problemas de resource fork, hace fallback a firmado superficial sin `--deep`

6. **Mecanismo de reintento**: Cuando `codesign` produce "internal error" o es terminado por SIGKILL, reintenta hasta 2 veces

## Copia de Seguridad y Restauración de Firma

### Copia de Seguridad

Los archivos de copia de seguridad se almacenan en el directorio `~/Library/Application Support/AppPorts/signature-backups/`, con el nombre `BundleID.plist`:

| Campo | Descripción |
|-------|-------------|
| `bundleIdentifier` | Bundle ID de la app |
| `signingIdentity` | Identidad de firma original (ej., `Developer ID Application: ...` o `ad-hoc`) |
| `originalPath` | Ruta original de la app |
| `backupDate` | Marca de tiempo de la copia de seguridad |

Las copias de seguridad se activan en estos momentos:

- Antes de la migración del directorio de datos (si el re-firmado automático está habilitado)
- Antes de cualquier operación de firmado (idempotente; no sobrescribe copias de seguridad existentes)

### Restauración

Al restaurar una firma, AppPorts ejecuta diferentes estrategias basadas en la identidad de firma respaldada:

| Identidad de Firma Respaldada | Comportamiento de Restauración |
|------------------------------|-------------------------------|
| `ad-hoc` o vacío | Ejecuta `codesign --remove-signature` para eliminar la firma; elimina la copia de seguridad |
| Identidad de certificado de desarrollador válido | Verifica si el certificado existe en Keychain. Si está presente, re-firma con la identidad original |
| Identidad de certificado de desarrollador válido pero el certificado no está en esta máquina | **Fallback a firmado Ad-hoc**; la firma original no puede restaurarse completamente |

### Escenarios de Fallo de Restauración

Los siguientes escenarios causan fallo o incompletitud en la restauración de firma:

| Escenario | Resultado |
|-----------|-----------|
| El archivo plist de copia de seguridad no existe | Lanza error `noBackupFound`; no se puede restaurar |
| El certificado de desarrollador original no está en el Keychain local | Hace fallback a firmado Ad-hoc. La app puede iniciarse pero los grupos de acceso a Keychain y algunos entitlements pueden fallar |
| Apps de Mac App Store (protección SIP) | Silenciosamente omitidas. SIP previene cualquier modificación a las firmas de apps del sistema |
| Directorio de app no escribible & propiedad root | Intenta cambiar la propiedad mediante privilegios de admin. Falla si el usuario cancela el prompt de autorización |
| Destino del enlace simbólico Contents perdido | `copyItem` falla en el paso de reemplazo temporal; no se puede ejecutar el firmado |
| El usuario cancela la autorización de admin | Lanza `codesignFailed("User cancelled authorization")` |
| Firmado profundo y superficial fallaron | Error propagado hacia arriba; la operación de firmado falla |

::: warning ⚠️ Sobre Certificados de Desarrollador Perdidos
El escenario de fallo de restauración más común en el mundo real es: la app original fue firmada por un desarrollador de terceros (ej., `Developer ID Application: Google LLC`), pero el Keychain de la máquina actual no tiene la clave privada correspondiente. En este caso, la operación de restauración solo puede generar una firma Ad-hoc; **la identidad de firma original no puede restaurarse completamente**. Para apps que dependen de identidades de firma específicas para grupos de acceso a Keychain o perfiles de configuración empresarial, esto puede causar anomalías funcionales.
:::
