---
outline: deep
---

# Détection des mises à jour automatiques

## Détection des applications Electron

AppPorts identifie les applications Electron via les trois conditions de détection suivantes (vérifiées par ordre de priorité, évaluation en court-circuit) :

| # | Élément de détection | Chemin / Motif |
|---|----------------------|----------------|
| 1 | Framework Electron | Le répertoire `Contents/Frameworks/Electron Framework.framework` existe |
| 2 | Variantes d'Electron Helper | Des entrées contenant `Electron Helper` dans le nom existent sous `Contents/Frameworks/` |
| 3 | Clés d'identification Info.plist | La clé `ElectronDefaultApp` ou `electron` existe dans `Contents/Info.plist` |

### Détection de mise à jour automatique Electron

Vérifie en plus l'existence du fichier `Contents/Resources/app-update.yml` (fichier de configuration pour `electron-updater`). Si présent, l'application Electron est marquée comme ayant une capacité de mise à jour automatique.

## Détection des applications Sparkle

AppPorts identifie les applications Sparkle via les trois conditions de détection suivantes :

| # | Élément de détection | Chemin / Motif |
|---|----------------------|----------------|
| 1 | Framework Sparkle | `Contents/Frameworks/Sparkle.framework` ou `Contents/Frameworks/Squirrel.framework` existe |
| 2 | Fichiers binaires du programme de mise à jour | Des fichiers correspondant à `shipit`, `autoupdate`, `updater`, `update` existent sous `Contents/MacOS/` ou `Contents/Frameworks/` |
| 3 | Clés Sparkle Info.plist | L'une des clés suivantes existe dans `Contents/Info.plist` : `SUFeedURL`, `SUPublicDSAKeyFile`, `SUPublicEDKey`, `SUScheduledCheckInterval`, `SUAllowsAutomaticUpdates` |

::: warning ⚠️ Gestion spéciale des applications Electron
Quand une application a été identifiée comme une application Electron, la condition de détection n°2 (fichiers binaires du programme de mise à jour) est ignorée pour éviter les faux positifs du binaire `updater` d'`electron-updater` détecté comme Sparkle.
:::

## Applications hybrides Electron + Sparkle

Certaines applications contiennent à la fois le framework Electron et le programme de mise à jour Sparkle. AppPorts détecte les deux indicateurs indépendamment, permettant à `isElectron` et `isSparkle` d'être tous deux `true`.

### Logique de détection

```text
isElectron = satisfait l'une des trois conditions de détection Electron
isSparkle  = satisfait l'une des trois conditions de détection Sparkle (les applications Electron ignorent la condition n°2)
```

Les deux indicateurs sont indépendants et peuvent être vrais simultanément.

### Comportement après migration

| Attribut | Condition de détermination |
|----------|---------------------------|
| `hasSelfUpdater` | `isSparkle` ou (`isElectron` et `app-update.yml` existe) ou mise à jour auto personnalisée existe |
| `needsLock` | `isSparkle` ou (`isElectron` et `app-update.yml` existe) |

Quand `needsLock` est `true`, AppPorts exécute `chflags -R uchg` (définition du drapeau immuable) sur l'application externe après la fin de la migration, empêchant les mises à jour automatiques de supprimer ou modifier la copie externe.

## Détection des mises à jour automatiques personnalisées

Pour les applications natives avec mise à jour automatique qui ne sont ni Sparkle ni Electron (par ex., Chrome, Edge, Parallels), AppPorts les identifie via les motifs suivants :

| Chemin de détection | Motif de correspondance | Applications typiques |
|---------------------|------------------------|----------------------|
| `Contents/Library/LaunchServices/` | Le nom de fichier contient `update` | Chrome, Edge, Thunderbird |
| `Contents/MacOS/` | Le nom du binaire contient `update` ou `upgrade` (excluant `electron`) | Parallels, Thunderbird |
| `Contents/SharedSupport/` | Le nom de fichier contient `update` | WPS Office |
| `Contents/Info.plist` | La clé `KSProductID` existe | Google Keystone (Chrome) |

## Identification des stratégies héritées

Lors de la restauration ou de la suppression de liens, AppPorts doit identifier les entrées héritées créées par des versions antérieures :

| Caractéristique de la structure locale | Identifié comme |
|----------------------------------------|-----------------|
| Le chemin racine est un lien symbolique | `wholeAppSymlink` |
| `Contents/` est un lien symbolique | `deepContentsWrapper` |
| `Contents/Info.plist` est un lien symbolique | `wholeAppSymlink` (schéma hybride Sparkle hérité) |
| `Contents/Frameworks/` est un lien symbolique | `wholeAppSymlink` (schéma hybride Electron hérité) |
| `Contents/MacOS/launcher` existe | `stubPortal` |
| Aucune correspondance ci-dessus | Non géré par AppPorts |
