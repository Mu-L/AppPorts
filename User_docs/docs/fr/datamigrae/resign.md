---
outline: deep
---

# Re-signature et prévention des plantages

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.37.png)

## Pourquoi les applications peuvent planter après la migration des données

Le mécanisme de signature de code de macOS (`codesign`) vérifie l'intégrité du package applicatif, y compris la structure des chemins de fichiers. Quand AppPorts migre le répertoire de données d'une application vers le stockage externe et le remplace par un lien symbolique, le sceau de signature est rompu, provoquant les problèmes suivants :

- **Blocage Gatekeeper** : `codesign --verify --deep --strict` détecte un échec de signature ; le système affiche une boîte de dialogue « Endommagé » ou « d'un développeur non identifié », bloquant le lancement de l'application
- **Perturbation d'accès Keychain** : Les applications dépendant des groupes d'accès Keychain ne peuvent pas lire les identifiants stockés en raison des changements d'identité de signature
- **Échec des droits (Entitlements)** : Certains droits d'application sont liés à l'identité de signature ; après un changement de signature, les droits ne correspondent plus

### Types d'applications à haut risque

| Type d'application | Niveau de risque | Raison |
|---------------------|------------------|--------|
| Applications avec mise à jour automatique Sparkle | **Élevé** | Le programme de mise à jour peut supprimer ou remplacer l'application, endommageant les liens symboliques |
| Applications avec mise à jour automatique Electron | **Élevé** | `electron-updater` peut également interférer avec les applications sur le stockage externe |
| Applications dépendant de Keychain | **Élevé** | La signature Ad-hoc change l'identité de signature ; les groupes d'accès Keychain échouent |
| Applications Mac App Store | **Élevé** | Protection SIP ; ne peut pas être re-signée |
| Applications avec mise à jour automatique native (Chrome, Edge) | Moyen | La mise à jour automatique peut remplacer la copie externe, invalidant l'entrée locale |
| Applications iOS (version Mac) | Faible | Utilise Stub Portal ou whole symlink ; moins de problèmes de signature |

### Types de répertoires de données à haut risque

| Type de données | Niveau de risque | Raison |
|-----------------|------------------|--------|
| `~/Library/Application Support/` | Moyen | L'application peut utiliser des verrous de fichiers, des journaux SQLite WAL ou des attributs étendus ; peut se comporter anormalement à travers les liens symboliques |
| `~/Library/Group Containers/` | Moyen | Partagé par plusieurs applications sous la même équipe ; les liens symboliques peuvent interférer avec d'autres applications |
| `~/Library/Preferences/` | Faible-Moyen | `cfprefsd` met en cache les fichiers plist ; les liens symboliques peuvent provoquer la lecture de données obsolètes |
| `~/Library/Caches/` | Faible | Les caches sont reconstituables ; la plupart des applications gèrent gracieusement l'absence de cache |

## Mécanisme de re-signature

### Signature Ad-hoc

AppPorts utilise la **signature Ad-hoc** (signature locale sans certificat) pour corriger les signatures d'application après la migration. Commande d'exécution :

```bash
codesign --force --deep --sign - <chemin de l'application>
```

Où `-` indique la signature Ad-hoc (sans certificat de développeur).

### Flux de signature

```mermaid
flowchart TD
    A[Démarrer la re-signature] --> B[Sauvegarder l'identité de signature originale]
    B --> C{L'application est-elle verrouillée ?}
    C -->|Oui| D[Déverrouiller temporairement le drapeau uchg]
    C -->|Non| E{L'application est-elle en écriture ?}
    D --> E
    E =>|Non inscriptible & appartenant à root| F[Essayer de changer la propriété avec admin]
    E =>|Inscriptible| G[Nettoyer les attributs étendus]
    F --> G
    F -->|Échec & app MAS| H[Passer la signature - Protection SIP]
    G --> I[Nettoyer les fichiers parasites du répertoire racine du bundle]
    I --> J{Contents est-il un lien symbolique ?}
    J =>|Oui| K[Remplacer temporairement par une copie réelle du répertoire]
    J =>|Non| L[Exécuter la signature profonde]
    K --> L
    L =>|Échec| M[Reculer vers la signature superficielle]
    L =>|Réussi| N{Contents a-t-il été remplacé temporairement ?}
    M --> N
    N =>|Oui| O[Restaurer le lien symbolique]
    N =>|Non| P[Re-verrouiller le drapeau uchg]
    O --> P
    P => Q[Signature terminée]
```

### Étapes clés

1. **Sauvegarder l'identité de signature originale** : Avant la signature, lire l'identité de signature actuelle de l'application (analyser les lignes `Authority=` via `codesign -dvv`), sauvegarder dans `~/Library/Application Support/AppPorts/signature-backups/<BundleID>.plist`

2. **Nettoyer les attributs étendus** : Exécuter `xattr -cr` pour supprimer les forks de ressources, les infos Finder, etc., évitant les erreurs « detritus not allowed » lors de la signature

3. **Nettoyer le répertoire racine du bundle** : Supprimer `.DS_Store`, `__MACOSX`, `.git`, `.svn` et autres fichiers parasites

4. **Gérer le lien symbolique Contents** : Si `Contents/` est un lien symbolique (stratégie Deep Contents Wrapper), le remplacer temporairement par une copie réelle du répertoire, puis restaurer le lien symbolique après la signature

5. **Signature profonde → repli vers signature superficielle** : Privilégier la signature `--deep` (couvrant tous les composants imbriqués) ; si elle échoue à cause de permissions ou de problèmes de fork de ressources, reculer vers la signature superficielle sans `--deep`

6. **Mécanisme de réessai** : Quand `codesign` produit une « erreur interne » ou est terminé par SIGKILL, réessayer jusqu'à 2 fois

## Sauvegarde et restauration de signature

### Sauvegarde

Les fichiers de sauvegarde sont stockés dans le répertoire `~/Library/Application Support/AppPorts/signature-backups/`, nommés `BundleID.plist` :

| Champ | Description |
|-------|-------------|
| `bundleIdentifier` | Bundle ID de l'application |
| `signingIdentity` | Identité de signature originale (par ex., `Developer ID Application: ...` ou `ad-hoc`) |
| `originalPath` | Chemin original de l'application |
| `backupDate` | Horodatage de la sauvegarde |

Les sauvegardes sont déclenchées aux moments suivants :

- Avant la migration du répertoire de données (si la re-signature automatique est activée)
- Avant toute opération de signature (idempotente ; n'écrase pas les sauvegardes existantes)

### Restauration

Lors de la restauration d'une signature, AppPorts exécute différentes stratégies selon l'identité de signature sauvegardée :

| Identité de signature sauvegardée | Comportement de restauration |
|------------------------------------|------------------------------|
| `ad-hoc` ou vide | Exécuter `codesign --remove-signature` pour supprimer la signature ; supprimer la sauvegarde |
| Identité de certificat développeur valide | Vérifier si le certificat existe dans Keychain. Si présent, re-signer avec l'identité originale |
| Identité de certificat développeur valide mais certificat absent de cette machine | **Repli vers la signature Ad-hoc** ; la signature originale ne peut pas être entièrement restaurée |

### Scénarios d'échec de restauration

Les scénarios suivants provoquent un échec ou une incomplétude de la restauration de signature :

| Scénario | Résultat |
|----------|----------|
| Le fichier plist de sauvegarde n'existe pas | Lance une erreur `noBackupFound` ; impossible de restaurer |
| Le certificat de développeur original n'est pas dans le Keychain local | Revient à la signature Ad-hoc. L'application peut se lancer mais les groupes d'accès Keychain et certains droits peuvent échouer |
| Applications Mac App Store (protection SIP | Passées silencieusement. SIP empêche toute modification des signatures d'applications système |
| Répertoire d'application non inscriptible & appartenant à root | Tente de changer la propriété via les privilèges admin. Échoue si l'utilisateur annule l'invite d'autorisation |
| Cible du lien symbolique Contents perdue | `copyItem` échoue dans l'étape de remplacement temporaire ; la signature ne peut pas être exécutée |
| L'utilisateur annule l'autorisation admin | Lance `codesignFailed("User cancelled authorization")` |
| Signature profonde et superficielle toutes deux échouées | Erreur propagée vers le haut ; l'opération de signature échoue |

::: warning ⚠️ À propos des certificats de développeur perdus
Le scénario d'échec de restauration le plus courant dans la réalité est : l'application originale était signée par un développeur tiers (par ex., `Developer ID Application: Google LLC`), mais le Keychain de la machine actuelle n'a pas la clé privée correspondante. Dans ce cas, l'opération de restauration ne peut générer qu'une signature Ad-hoc ; **l'identité de signature originale ne peut pas être entièrement restaurée**. Pour les applications dépendant d'identités de signature spécifiques pour les groupes d'accès Keychain ou les profils de configuration d'entreprise, cela peut provoquer des anomalies fonctionnelles.
:::
