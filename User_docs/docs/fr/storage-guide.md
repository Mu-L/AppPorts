---
outline: deep
---

# Guide du stockage externe

## Configuration recommandée

| Configuration | Valeur recommandée | Description |
|---------------|-------------------|-------------|
| Capacité | 256 Go ou plus | Dépend du nombre d'applications migrées |
| Interface | USB 3.0 ou plus / Thunderbolt | L'USB 2.0 est lent ; la migration d'applications volumineuses prend plus de temps |
| Système de fichiers | APFS | Supporte les clones, les instantanés, meilleures performances |

## Comparaison des performances d'interface

| Interface | Vitesse théorique | Vitesse de migration réelle | Cas d'utilisation |
|-----------|-------------------|---------------------------|-------------------|
| USB 2.0 | 480 Mbps | ~30 Mo/s | Non recommandé ; trop lent |
| USB 3.0 (USB-A) | 5 Gbps | ~350 Mo/s | Suffisant de base |
| USB 3.1 Gen 2 (USB-C) | 10 Gbps | ~700 Mo/s | Recommandé |
| Thunderbolt 3/4 | 40 Gbps | ~2500 Mo/s | Meilleures performances |
| NVMe (Thunderbolt) | 40 Gbps | ~2800 Mo/s | Meilleures performances |

## Recommandations de système de fichiers

### APFS (Recommandé)

- Supporte les clones, les instantanés, le partage d'espace
- Meilleures performances, surtout pour les SSD
- Support natif macOS

### HFS+

- Bonne compatibilité ; adapté aux anciens Macs
- Ne supporte pas les clones et les instantanés
- Adapté aux disques durs mécaniques

### exFAT

- Compatible multi-plateforme (macOS + Windows)
- Ne supporte pas les liens durs et les clones
- Performances relativement plus faibles
- Adapté aux scénarios nécessitant une utilisation sur plusieurs systèmes

## Planification de la capacité

L'utilisation du stockage externe d'AppPorts après la migration dépend de la taille des applications et répertoires de données migrés. Voici des tailles de référence pour des applications courantes :

| Type d'application | Taille |
|---------------------|--------|
| Chrome | ~500 Mo |
| Microsoft Office | ~5 Go |
| Adobe Creative Cloud | ~20-50 Go |
| Xcode | ~15 Go |
| Final Cut Pro | ~5 Go |
| Modèles de langage locaux (Ollama) | ~4-30 Go |

::: tip 💡 Recommandations de capacité
- Usage léger (5-10 applications) : 128 Go
- Usage moyen (10-20 applications) : 256 Go
- Usage intensif (20+ applications + répertoires de données) : 512 Go ou plus
:::

## Notes

- Le stockage externe doit rester connecté ; les applications et répertoires de données migrés ne peuvent pas être utilisés hors ligne
- Sauvegarder régulièrement les données sur le stockage externe
- Éviter de débrancher le stockage externe pendant la migration
- Si le stockage externe tombe en panne, vous pouvez déplacer les applications vers le local via AppPorts
