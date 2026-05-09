---
outline: deep
---

# Compatibilité et limitations

## Configuration système requise

| Prérequis | Description |
|-----------|-------------|
| Version minimale du système | macOS 12.0 (Monterey) |
| Architecture | Intel x86_64 / Apple Silicon (arm64) |
| Permissions | Accès complet au disque |
| Stockage externe | Au moins un périphérique de stockage externe requis |

## Compatibilité des fonctionnalités

### Par version de macOS

| Fonctionnalité | macOS 12.0 - 15.0 | macOS 15.1+ |
|----------------|:---:|:---:|
| Migration d'applications (Stub Portal) | ✓ | ✓ |
| Migration des répertoires de données | ✓ | ✓ |
| Gestion des signatures de code | ✓ | ✓ |
| Migration d'applications App Store vers disque externe | ✗ | ✓ |
| Mise à jour in situ d'applications App Store sur disque externe | ✗ | ✓ |
| Migration d'applications iOS | ✓ | ✓ |

::: warning ⚠️ Applications App Store sur les versions macOS inférieures à 15.1
Les versions macOS antérieures à 15.1 (Sequoia) ne supportent pas l'installation d'applications App Store sur des disques externes. Vous devez activer manuellement « Migration des applications App Store » dans les réglages d'AppPorts, et les mises à jour d'applications nécessitent une re-migration manuelle pour écraser.
:::

### Par type d'application

| Type d'application | Migration | Restauration | Mise à jour auto | Notes |
|---------------------|:---:|:---:|:---:|-------|
| Application macOS native | ✓ | ✓ | ✓ | Meilleure compatibilité |
| Application Sparkle | ✓ | ✓ | Nécessite un verrouillage | Le verrouillage empêche les mises à jour dans l'application ; doit restaurer pour mettre à jour |
| Application Electron | ✓ | ✓ | Nécessite un verrouillage | Identique à Sparkle |
| Chrome / Edge (mise à jour auto personnalisée) | ✓ | ✓ | ✓ | Le programme de mise à jour installe en local ; n'endommage pas la copie externe |
| Application App Store (macOS 15.1+) | ✓ | ✓ | ✓ | Installation externe native ; l'App Store peut mettre à jour directement |
| Application App Store (macOS <15.1) | ✓ | ✓ | Manuel | Les mises à jour nécessitent une re-migration |
| Application iOS (version Mac) | ✓ | ✓ | ✓ | Utilise iOS Stub Portal |
| Applications système | ✗ | — | — | Protection SIP ; ne peut pas être migrée |

### Par type de répertoire de données

| Type de répertoire de données | Migration | Risque |
|-------------------------------|:---:|--------|
| `~/Library/Application Support/` | ✓ | Moyen — peut utiliser des verrous de fichiers ou des journaux SQLite WAL |
| `~/Library/Preferences/` | ✓ | Faible-Moyen — la mise en cache `cfprefsd` peut provoquer des lectures obsolètes |
| `~/Library/Containers/` | ✓ | Moyen — partagé par des applications sous la même équipe |
| `~/Library/Group Containers/` | ✓ | Moyen — les données partagées peuvent interférer avec d'autres applications |
| `~/Library/Caches/` | ✓ | Faible — les caches sont reconstituables |
| `~/Library/Logs/` | ✓ | Faible — fichiers journaux uniquement |
| `~/Library/WebKit/` | ✓ | Moyen — stockage local WebKit |
| `~/Library/HTTPStorages/` | ✓ | Faible — stockage de sessions réseau |
| `~/Library/Application Scripts/` | ✓ | Faible — scripts d'extension |
| `~/Library/Saved Application State/` | ✓ | Faible — restauration de l'état des fenêtres |
| `~/.npm`, `~/.m2` etc. dot-folder | ✓ | Faible — caches d'outils de développement |

## Contenu non migrable

### Protégé par SIP

| Chemin | Raison |
|--------|--------|
| Applications système macOS (Safari, Finder, etc.) | Protection de l'intégrité du système |
| Répertoire de premier niveau `~/Library/Containers/` | Protection système macOS |

### Contient des références de chemin

| Chemin | Raison |
|--------|--------|
| `~/.local` | Contient des références de chemin exécutables ; les outils en ligne de commande peuvent échouer après la migration |
| `~/.config` | Contient des configurations de chemin absolu ; les configurations des outils peuvent échouer après la migration |

## Exigences du stockage externe

| Prérequis | Description |
|-----------|-------------|
| Système de fichiers | APFS, HFS+, exFAT supportés |
| Espace minimum | Dépend de la taille des applications migrées |
| Interface | USB, Thunderbolt, NVMe tous supportés |
| Resté connecté | Le stockage externe doit rester connecté après la migration ; sinon les applications ne peuvent pas se lancer |

::: tip 💡 Recommandations de système de fichiers
- **APFS** : Recommandé ; supporte les clones, les instantanés, meilleures performances
- **HFS+** : Bonne compatibilité ; adapté aux anciens Macs
- **exFAT** : Compatible multi-plateforme ; ne supporte pas les liens durs et les clones
:::
