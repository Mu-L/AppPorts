---
outline: deep
---

# Guide Utilisateur AppPorts

Ce guide présente de manière systématique les fonctionnalités, les principes de conception et l'implémentation technique d'AppPorts. Pour plus de détails techniques, consultez [DeepWiki](https://deepwiki.com/wzh4869/AppPorts). Pour des suggestions d'amélioration, veuillez les soumettre sur la page [Issues](https://github.com/wzh4869/AppPorts/issues) du projet.

## Vue d'ensemble

AppPorts est un outil de migration et de liaison d'applications conçu pour [macOS](https://www.apple.com/macos/), prenant en charge la migration d'applications volumineuses vers des périphériques de stockage externes tout en maintenant une fonctionnalité et une cohérence système complètes.

### Philosophie d'AppPorts

| Principe | Description |
|----------|-------------|
| **Expérience transparente** | Garantit que l'expérience utilisateur et le système d'exploitation perçoivent l'application comme étant toujours exécutée depuis le stockage interne |
| **Stratégie stable** | Privilégie les approches de migration éprouvées et plus stables |
| **Faible charge système** | Pas de démons, évite la consommation continue de ressources système |
| **Internationalisation étendue** | Privilégie la couverture de plus de langues ; largeur de traduction plutôt que précision |
| **Accessibilité conviviale** | Support complet de l'accessibilité |

## Fonctionnalités principales

- **Migration sans badge** : Migration en un clic d'applications volumineuses vers des disques externes. Seul un shell de lancement léger est conservé localement ; le Finder n'affiche pas de flèches de raccourci ; le Launchpad et le menu des applications macOS fonctionnent normalement.
- **Protection des mises à jour automatiques** : Détecte automatiquement les applications avec support de mise à jour automatique (Sparkle, Electron, Chrome, etc.), fournissant une option « Migration verrouillée » pour empêcher les mises à jour automatiques de supprimer ou d'écraser les applications sur le disque externe.
- **Gestion des signatures de code** : Après la migration, si un message « Endommagé » apparaît, re-signature en un clic via le menu contextuel. Supporte la sauvegarde et la restauration des signatures originales ; re-signature automatique après la migration du répertoire de données.
- **Support App Store macOS 15.1+** : Prend en charge l'installation directe d'applications App Store sur des disques externes avec mises à jour in situ sur le disque externe.
- **Restauration en un clic** : Prend en charge la remigration des applications vers le stockage interne avec suppression automatique des liens. Récupération automatique en cas d'interruption de la migration.
- **Gestion des répertoires de données** : Prend en charge la migration des répertoires de données d'applications (sous-répertoires `~/Library/`, `~/.npm`, etc.) vers le stockage externe, avec regroupement en arborescence, recherche et tri.

## Glossaire

### Stratégies de migration

#### Deep Contents Wrapper (Migration du répertoire Contents)

La structure de fichiers standard d'une application macOS est la suivante :

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

La stratégie Deep Contents Wrapper migre tout le contenu de l'application vers le stockage externe, créant un répertoire `.app` vide localement avec uniquement un lien symbolique pointant vers le répertoire `Contents` externe. Puisque macOS détecte un package `.app` complet (plutôt qu'un raccourci), le Finder n'affiche pas de marqueurs fléchés ; les icônes, le Launchpad et les menus d'application fonctionnent normalement.

::: warning ⚠️ Cette stratégie est obsolète dans la version actuelle
Le principal défaut de Deep Contents Wrapper est que les mises à jour automatiques suivent les liens symboliques et modifient directement les fichiers sur le stockage externe, pouvant corrompre l'application.
:::

#### Stub Portal

L'approche Stub Portal crée un shell `.app` minimal localement, contenant uniquement ces quatre éléments :

| Composant | Description |
|-----------|-------------|
| `Contents/MacOS/launcher` | Script bash de lancement qui exécute `open "/Volumes/External/SomeApp.app"` |
| `Contents/Resources/` | Fichier icône copié depuis l'application externe |
| `Contents/Info.plist` | Simplifié depuis le `Info.plist` de l'application externe, avec `CFBundleExecutable` défini sur `launcher`, `LSUIElement=true` (non affiché dans le Dock), et toutes les clés de configuration liées aux mises à jour supprimées |
| `Contents/PkgInfo` | Fichier identifiant standard de 4 octets |

Lorsque l'utilisateur clique sur ce shell, macOS exécute le script `launcher`, ouvrant la vraie application sur le disque externe via la commande `open`. Aucun lien symbolique n'est présent localement ; les mises à jour automatiques ne peuvent pas pénétrer à travers.

##### iOS Stub Portal

Le principe de base est le même que le Stub Portal standard, mais la gestion des icônes diffère. Les icônes d'applications iOS ne sont pas spécifiées dans `Info.plist` mais stockées sous forme de multiples fichiers `AppIcon.png` dans les répertoires `Wrapper/` ou `WrappedBundle/`. Le processus est :

1. Trouver le fichier `AppIcon.png` avec la résolution la plus élevée
2. Utiliser `sips` pour redimensionner à 256×256 pixels
3. Utiliser `sips` pour convertir au format `.icns`
4. Générer le `Info.plist` à partir de `iTunesMetadata.plist` (les applications iOS n'incluent pas de `Info.plist` standard)

#### Whole Symlink

Crée le répertoire `.app` entier comme un lien symbolique vers le stockage externe :

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

Seul un lien symbolique est conservé localement sans fichiers réels. macOS peut ouvrir l'application normalement, mais le Finder affiche des marqueurs de raccourci fléchés sur l'icône, et le Launchpad a occasionnellement des problèmes de compatibilité. Les mises à jour automatiques peuvent également opérer sur les fichiers de l'application externe via le lien symbolique. Ceci est la stratégie de migration de repli d'AppPorts.
