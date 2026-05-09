---
outline: deep
---

# Implémentation de base de la migration des données

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.05.png)

La fonctionnalité de migration des données d'AppPorts migre les répertoires de données associés aux applications (tels que `~/Library/Application Support`, `~/Library/Caches`, etc.) vers le stockage externe pour libérer de l'espace disque local.

## Stratégie principale : Lien symbolique

La migration des répertoires de données utilise la stratégie **Whole Symlink** :

1. Copier l'intégralité du répertoire local original vers le stockage externe
2. Écrire les métadonnées de lien géré (`.appports-link-metadata.plist`) dans le répertoire externe
3. Supprimer le répertoire local original
4. Créer un lien symbolique à l'emplacement d'origine pointant vers la copie externe

```
~/Library/Application Support/SomeApp
    → /Volumes/External/AppPortsData/SomeApp  (symlink)
```

## Flux de migration

```mermaid
flowchart TD
    A[Sélectionner le répertoire de données] --> B{Vérification des permissions et de la protection}
    B -->|Échec| Z[Terminer]
    B -->|Réussi| C{Détection de conflit de chemin cible}
    C -->|Métadonnées gérées présentes| D[Mode de récupération automatique]
    C -->|Pas de conflit| E[Copier vers le stockage externe]
    D --> E
    E --> F[Écrire les métadonnées de lien géré]
    F --> G[Supprimer le répertoire local]
    G -->|Échec| H[Annulation : supprimer la copie externe]
    G -->|Réussi| I[Créer le lien symbolique]
    I -->|Échec| J[Annulation d'urgence : copier vers le local]
    I -->|Réussi| K[Migration terminée]
```

## Métadonnées de lien géré

AppPorts écrit un fichier `.appports-link-metadata.plist` dans le répertoire externe pour identifier que le répertoire est géré par AppPorts. Les métadonnées incluent :

| Champ | Description |
|-------|-------------|
| `schemaVersion` | Numéro de version des métadonnées (actuellement 1) |
| `managedBy` | Identifiant du gestionnaire (`com.shimoko.AppPorts`) |
| `sourcePath` | Chemin local original |
| `destinationPath` | Chemin cible du stockage externe |
| `dataDirType` | Type de répertoire de données |

Ces métadonnées sont utilisées lors de l'analyse pour distinguer les liens gérés par AppPorts des liens symboliques créés par l'utilisateur, et supportent la récupération automatique en cas d'interruption de la migration.

## Types de répertoires de données supportés

| Type | Exemple de chemin |
|------|-------------------|
| `applicationSupport` | `~/Library/Application Support/` |
| `preferences` | `~/Library/Preferences/` |
| `containers` | `~/Library/Containers/` |
| `groupContainers` | `~/Library/Group Containers/` |
| `caches` | `~/Library/Caches/` |
| `webKit` | `~/Library/WebKit/` |
| `httpStorages` | `~/Library/HTTPStorages/` |
| `applicationScripts` | `~/Library/Application Scripts/` |
| `logs` | `~/Library/Logs/` |
| `savedState` | `~/Library/Saved Application State/` |
| `dotFolder` | `~/.npm`, `~/.vscode`, etc. |
| `custom` | Chemin défini par l'utilisateur |

## Flux de restauration

1. Vérifier que le chemin local est un lien symbolique pointant vers un répertoire externe valide
2. Supprimer le lien symbolique local
3. Copier le répertoire externe vers le local
4. Supprimer le répertoire externe (dans la mesure du possible)

Si la copie échoue, reconstruit automatiquement le lien symbolique pour maintenir la cohérence.

## Gestion des erreurs et annulation

Chaque étape critique du processus de migration inclut des mécanismes d'annulation :

- **Échec de la copie** : Aucune action supplémentaire ; nettoyage des fichiers externes copiés
- **Échec de la suppression du répertoire local** : Suppression de la copie externe, restauration de l'état d'origine
- **Échec de la création du lien symbolique** : Copie des données depuis l'externe vers le local, suppression de la copie externe

Cette conception garantit l'absence de perte de données et un état système cohérent en cas d'échec à n'importe quelle étape.
