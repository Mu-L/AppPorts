---
outline: deep
---

# Guide d'opération de migration des données

Cette page couvre le flux de travail pratique pour la migration des répertoires de données. Pour les détails d'implémentation technique, voir [Implémentation de base](/fr/datamigrae/baseinfo).

## Trouver les répertoires de données associés aux applications

1. Basculer vers l'onglet « Répertoires de données » dans la fenêtre principale d'AppPorts
2. Le panneau gauche affiche toutes les applications installées
3. Cliquer sur une application ; le panneau droit affiche ses répertoires de données associés sous `~/Library/`

AppPorts analyse automatiquement les répertoires suivants, en les associant par Bundle ID ou nom de l'application :

| Chemin d'analyse | Méthode d'association |
|------------------|-----------------------|
| `~/Library/Application Support/` | Bundle ID ou nom de l'application |
| `~/Library/Preferences/` | Bundle ID ou nom de l'application |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID ou nom de l'application |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | Nom de l'application |
| `~/Library/Saved Application State/` | Nom de l'application |

## Répertoires d'outils (Dot-Folders)

AppPorts peut détecter automatiquement les dot-folders créés par les outils de développement courants dans le répertoire personnel de l'utilisateur :

1. Basculer vers le sous-onglet « Répertoires d'outils » dans l'onglet Répertoires de données
2. La page liste tous les répertoires d'outils détectés avec leurs tailles
3. Chaque répertoire affiche un badge de priorité (recommended/optional) et un statut

Pour la liste complète supportée, voir [Détection des répertoires d'outils](/fr/datamigrae/tools).

## Opérations de migration

### Migration d'un répertoire unique

1. Trouver le répertoire à migrer dans la liste des répertoires de données
2. Cliquer sur le bouton « Migrer » à droite
3. AppPorts effectue les étapes suivantes :
   - Copier le répertoire vers le stockage externe
   - Écrire les métadonnées de lien géré
   - Supprimer le répertoire local original
   - Créer un lien symbolique

### Re-signature automatique

Lorsque « Re-signature automatique » est activée dans les paramètres, la migration du répertoire de données déclenche automatiquement la signature pour l'application associée :

1. **Avant la migration** : Sauvegarde la signature originale du **vrai chemin externe** de l'application associée (pas le shell local)
2. **Après la migration** : Exécute la re-signature Ad-hoc sur la **vraie application externe** (mode silencieux ; les échecs n'affichent pas de dialogue)

Pour les applications liées, AppPorts résout automatiquement le vrai chemin de l'application derrière le shell Stub Portal ou le lien symbolique, garantissant que les changements de signature sont appliqués au vrai package d'application plutôt qu'à un shell local invalide.

::: tip 💡 Aucune action manuelle requise
Avec la re-signature automatique activée, le workflow de migration du répertoire de données est entièrement automatisé. La sauvegarde de signature et la re-signature ciblent toutes deux le vrai chemin de l'application — aucune intervention manuelle requise.
:::

### Contexte des logs

Les opérations sur les répertoires de données (migration, restauration, normalisation, re-liage) incluent automatiquement les informations de contexte de l'application associée dans les logs :

| Champ | Description |
|-------|-------------|
| `app_name` | Nom de l'application associée |
| `app_status` | Statut de l'application (Liée, Locale, etc.) |
| `app_is_resigned` | Si l'application a été re-signée |
| `app_bundle_id` | Bundle ID de l'application (lu depuis le vrai chemin) |
| `app_real_path` | Vrai chemin externe de l'application |

Ces champs aident à localiser les problèmes plus précisément lors de l'exportation de packages de diagnostic.

### Migration par lots

1. Cocher plusieurs répertoires dans la liste des répertoires d'outils
2. Cliquer sur le bouton « Migration par lots » en bas
3. AppPorts exécute la migration séquentiellement

::: tip 💡 Recommandations de priorité
Les répertoires de données sont classés en trois niveaux de priorité :

- **Critique** (`critical`) : Doit fonctionner après la migration ; affecte les fonctionnalités principales de l'application
- **Recommandé** (`recommended`) : Économie d'espace importante ; bénéfice de migration élevé
- **Optionnel** (`optional`) : Taille faible ou reconstituable

Il est recommandé de prioriser la migration des répertoires marqués comme « Recommandé ».
:::

## Opérations de restauration

1. Trouver le répertoire migré dans la liste des répertoires de données (statut : « Lié »)
2. Cliquer sur le bouton « Restaurer » à droite
3. AppPorts effectue les étapes suivantes :
   - Supprimer le lien symbolique local
   - Copier les données depuis le stockage externe vers le local
   - Supprimer le répertoire externe (dans la mesure du possible)

## Gestion des états anormaux

### Nécessite une normalisation

Le répertoire est géré par AppPorts, mais le chemin externe n'est pas à l'emplacement canonique. Cliquer sur « Normaliser » ; AppPorts déplacera les données externes vers le chemin canonique et reconstruira le lien symbolique.

### Nécessite une re-liaison

Les données sur le stockage externe existent toujours, mais le lien symbolique local est perdu. Cliquer sur « Re-lier » ; AppPorts recréera le lien symbolique.

### Lien symbolique existant

Un lien symbolique créé par l'utilisateur, non créé par AppPorts. Vous pouvez choisir « Reprendre » ; AppPorts écrira les métadonnées de lien géré et le gérera par la suite.

## Vue en arborescence

Pour les répertoires de données contenant des sous-répertoires (par ex., plusieurs répertoires d'applications sous `Application Support`), AppPorts fournit une vue de regroupement en arborescence :

- Le répertoire parent affiche des flèches d'expansion/réduction à gauche
- Les sous-répertoires affichent une indentation hiérarchique
- Chaque nœud affiche indépendamment la taille et le statut
- Les opérations de migration/restauration peuvent être effectuées sur des sous-répertoires individuels
