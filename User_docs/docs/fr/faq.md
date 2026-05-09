---
outline: deep
---

# FAQ

## Installation et autorisation

### Quelles permissions AppPorts a-t-il besoin ?

AppPorts a besoin de la permission **Accès complet au disque** pour lire et modifier le répertoire `/Applications`. Au premier lancement, il vous guidera dans l'autorisation. Vous pouvez aussi l'ajouter manuellement dans Réglages Système → Confidentialité et sécurité → Accès complet au disque.

### Quelles versions de macOS sont supportées ?

Le support minimum est macOS 12.0 (Monterey). macOS 15.1 (Sequoia) et ultérieur supportent en plus l'installation d'applications App Store sur des disques externes avec mises à jour in situ.

## Migration d'applications

### Que faire si l'application ne s'ouvre pas après la migration ?

1. Confirmer que le stockage externe est connecté et accessible
2. Vérifier le badge de statut de l'application : Si « Lien orphelin », l'application externe est perdue ; suppression manuelle du lien requise
3. Si un message « Endommagé » apparaît, cliquer avec le bouton droit sur l'application et sélectionner « Re-signer »
4. Si toujours non résolu, sélectionner « Déplacer vers le local » dans la bibliothèque Applications externes

### Que faire si je vois un message « Endommagé » ?

Le mécanisme de signature de code de macOS a détecté un changement dans la structure du package applicatif. Résolution :

1. Cliquer avec le bouton droit sur l'application dans AppPorts
2. Sélectionner « Re-signer »
3. AppPorts sauvegardera automatiquement la signature originale et exécutera la re-signature Ad-hoc

Pour les mécanismes détaillés, voir [Re-signature et prévention des plantages](/fr/datamigrae/resign).

### L'application plantera-t-elle si le stockage externe est débranché ?

L'entrée locale (Stub Portal) tentera d'appeler `open` pour lancer l'application externe. Si le stockage externe n'est pas connecté, l'application ne pourra pas se lancer mais ne plantera pas. L'usage normal reprend après la reconnexion du stockage externe.

### Les applications peuvent-elles être mises à jour après la migration ?

Cela dépend du type d'application :

| Type d'application | Peut se mettre à jour auto | Notes |
|---------------------|:---:|-------|
| Applications natives (sans mise à jour auto) | ✓ | Mises à jour normales |
| Chrome, Edge (mise à jour auto personnalisée) | ✓ | Les mises à jour s'installent en local ; AppPorts détecte la différence de version et marque « Migration en attente » |
| Applications Sparkle / Electron | ✗ | Le verrouillage empêche les mises à jour dans l'application ; doit restaurer vers le local via AppPorts avant de mettre à jour |
| Applications App Store (macOS 15.1+) | ✓ | L'App Store peut mettre à jour in situ sur le disque externe |
| Applications App Store (macOS <15.1) | ✗ | Re-migration manuelle requise |

### Comment migrer des applications App Store vers un disque externe ?

**macOS 15.1+** : Dans les réglages de l'App Store, activer « Télécharger et installer les grandes applications sur un disque externe », en sélectionnant le même stockage externe qu'AppPorts.

**macOS <15.1** : Dans les réglages d'AppPorts, activer « Migration des applications App Store ». Après la migration manuelle, les mises à jour d'applications nécessitent une re-migration.

### La migration est lente/bloquée. Que faire ?

- À 100% de progression de la migration, il peut y avoir une pause de 1-2 secondes lors de la création des entrées locales
- Les applications volumineuses (par ex., Xcode, Adobe) prennent plus de temps à migrer — c'est normal
- Si bloquée pendant longtemps, vérifier la stabilité de la connexion du stockage externe
- L'USB 2.0 est lent ; recommandé d'utiliser l'USB 3.0 ou supérieur, ou Thunderbolt

## Migration des répertoires de données

### Les données seront-elles perdues après la migration du répertoire de données ?

Non. AppPorts utilise la stratégie de lien symbolique : les données sont entièrement copiées vers le stockage externe d'abord ; ce n'est qu'après confirmation de la réussite de la copie que le répertoire local original est supprimé. Toute étape échouée déclenche une annulation automatique.

### Quand la migration du répertoire de données peut-elle causer des problèmes ?

- Applications utilisant des verrous de fichiers ou des journaux SQLite WAL
- Les attributs étendus peuvent être perdus à travers les liens symboliques
- Répertoires Group Containers partagés par plusieurs applications sous la même équipe

### Comment restaurer les répertoires de données migrés ?

Dans l'interface de gestion des répertoires de données d'AppPorts, sélectionner le répertoire migré et cliquer sur « Restaurer ». AppPorts supprimera le lien symbolique et copiera les données depuis le stockage externe vers le local.

## Divers

### AppPorts collecte-t-il mes données ?

Non. AppPorts fonctionne complètement hors ligne et ne collecte ni ne télécharge aucune donnée utilisateur. Les fichiers journaux sont stockés localement dans `~/Library/Application Support/AppPorts/`.

### Comment signaler des problèmes ?

Veuillez soumettre sur la page [Issues](https://github.com/wzh4869/AppPorts/issues) du projet. Il est recommandé d'inclure un package de diagnostic (Barre de menus → Journaux → Exporter le package de diagnostic) pour accélérer la résolution du problème.
