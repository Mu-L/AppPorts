---
outline: deep
---

# Badges de statut

AppPorts affiche le statut actuel des applications et des répertoires de données à l'aide de badges colorés en forme de capsule. Certains badges sont cliquables pour obtenir des informations détaillées.

## Badges de statut des applications

### Statut de liaison

| Badge | Icône | Couleur | Signification |
|-------|-------|---------|---------------|
| Lié | `link` | Vert | Application migrée vers le stockage externe avec entrée locale |
| Migration verrouillée | `lock.fill` | Vert | Liée et verrouillée avec `uchg`, empêchant les mises à jour automatiques d'endommager l'application externe |
| Migration déverrouillée | `lock.open` | Orange | Liée mais non verrouillée ; les mises à jour dans l'application peuvent supprimer l'application externe |
| Lien partiel | `link.badge.plus` | Jaune | Composants partiels de l'application liés (par ex., certains fichiers `.app` dans un répertoire) |
| Lien orphelin | `link.badge.exclamationmark` | Rouge | Application externe perdue mais entrée locale toujours existante |
| Non liée | `externaldrive.badge.xmark` | Orange | Application sur le stockage externe mais non liée en retour localement |
| Externe | `externaldrive` | Orange | Application sur le stockage externe sans entrée locale |
| Locale | `macmini` | Couleur secondaire | Application locale régulière, non migrée ; affichée quand aucun autre tag n'est présent |

### Labels de framework

| Badge | Icône | Couleur | Signification | Action au clic |
|-------|-------|---------|---------------|----------------|
| Sparkle | `arrow.triangle.2.circlepath` | Cyan | Utilise le framework Sparkle pour les mises à jour automatiques | Après migration vers le stockage externe, les mises à jour dans l'application peuvent causer la perte de l'application externe ; migration verrouillée recommandée |
| Electron | `atom` | Indigo | Basé sur le framework Electron avec support de mise à jour automatique | Après migration vers le stockage externe, les mises à jour dans l'application peuvent causer la perte de l'application externe ; migration verrouillée recommandée |

### Labels de type

| Badge | Icône | Couleur | Signification |
|-------|-------|---------|---------------|
| En cours d'exécution | `play.fill` | Violet | Application actuellement en cours d'exécution |
| Système | `lock.fill` | Gris | Application système macOS |
| Non native | `iphone` | Rose | Application iOS/iPadOS (exécutée via Apple Silicon) |
| Store | `applelogo` | Bleu | Application Mac App Store |

### Labels spéciaux

| Badge | Icône | Couleur | Signification |
|-------|-------|---------|---------------|
| Re-signée | `seal.fill` | Cyan | L'application a été re-signée en Ad-hoc (exécuté quand « Endommagé » apparaît après la migration) |

::: tip 💡 Note spéciale sur le label Store
Quand une application remplit les conditions suivantes, le label « Store » devient cliquable et affiche les instructions d'installation native macOS 15.1+ :
- L'application est située dans le répertoire `/Volumes/{drive}/Applications/` sur le stockage externe
- Gérée nativement par macOS ; l'App Store peut effectuer des mises à jour incrémentielles directement dans ce répertoire
:::

## Badges de statut des répertoires de données

| Statut | Couleur | Signification |
|--------|---------|---------------|
| Local | Couleur secondaire | Répertoire sur le stockage local, non migré |
| Lié | Vert | Migré vers le stockage externe ; le local est un lien symbolique |
| Nécessite une normalisation | Jaune | Lien géré par AppPorts, mais le chemin externe n'est pas à l'emplacement canonique ; opération « Normaliser » recommandée |
| Nécessite une re-liaison | Orange | Données sur le stockage externe existantes mais lien symbolique local perdu ; opération « Re-lier » recommandée |
| Lien symbolique existant | Bleu | Lien symbolique créé par l'utilisateur (non créé par AppPorts) ; option pour reprendre la gestion |

## Combinaisons de statut d'application

Une application peut afficher plusieurs badges simultanément :

```text
[Lié] [Sparkle] [En cours d'exécution]
```
Signification : Application migrée vers le stockage externe, utilise le framework de mise à jour automatique Sparkle, actuellement en cours d'exécution.

```text
[Externe] [Store] [Non native]
```
Signification : Application iOS (version Mac) sur le stockage externe, installée via l'App Store.

```text
[Lien orphelin]
```
Signification : Application externe perdue ou supprimée, mais l'entrée locale toujours conservée. Suppression manuelle du lien requise.
