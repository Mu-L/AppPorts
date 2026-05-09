---
outline: deep
---

# Dépannage

## Interruption de la migration

### Symptômes

Migration interrompue en raison de la déconnexion du stockage externe, d'un crash système ou de la fermeture forcée de l'application.

### Résolution

AppPorts dispose d'un mécanisme de récupération automatique intégré. Après le redémarrage d'AppPorts :

1. Détecte les données de migration résiduelles (la copie externe existe mais le lien symbolique local n'est pas créé)
2. Compare automatiquement les tailles des répertoires local et externe (seuil de 90%)
3. Si les données sont complètes, termine automatiquement la migration (supprime le répertoire local original, crée le lien symbolique)
4. Si les données sont incomplètes, nettoie la copie externe résiduelle et restaure l'état d'origine

::: tip 💡 Aucune intervention manuelle nécessaire
Le mécanisme de récupération automatique d'AppPorts gère les migrations interrompues au lancement suivant. Si la récupération automatique échoue, vous pouvez voir les statuts « Nécessite une normalisation » ou « Nécessite une re-liaison » dans la liste des répertoires de données — exécutez simplement l'opération correspondante manuellement.
:::

## Stockage externe hors ligne

### Symptômes

Après la déconnexion ou le débranchement du stockage externe, les applications migrées ne peuvent pas se lancer et les répertoires de données affichent un statut d'erreur rouge.

### Résolution

1. Reconnecter le stockage externe
2. Le `FolderMonitor` d'AppPorts détecte automatiquement le montage du volume de stockage et déclenche une nouvelle analyse
3. Les applications et répertoires de données reprennent un usage normal

::: warning ⚠️ Note
Pendant que le stockage externe est hors ligne, les entrées locales (Stub Portal) appelant `open` échoueront ; les applications ne pourront pas se lancer mais ne planteront pas. Les liens symboliques des répertoires de données pointent vers des chemins invalides ; les applications associées peuvent ne pas être en mesure de lire les données.
:::

## Échec de restauration de signature

### Symptômes

La tentative de restauration de la signature originale échoue, ou l'application affiche toujours « Endommagé » après la restauration.

### Causes possibles et résolution

| Cause | Résolution |
|-------|-----------|
| Le fichier de sauvegarde n'existe pas | Impossible de restaurer la signature originale ; exécuter la re-signature Ad-hoc comme alternative |
| Le certificat de développeur original n'est pas dans le Keychain local | AppPorts revient automatiquement à la signature Ad-hoc ; l'application peut se lancer mais l'accès Keychain peut être anormal |
| Application Mac App Store (protection SIP | Impossible de re-signer ; SIP empêche toute modification des signatures d'applications système |
| Le répertoire d'appartient à root | AppPorts tente de changer la propriété via les privilèges admin ; autoriser dans la fenêtre popup |
| Cible du lien symbolique Contents perdue | Impossible de signer ; doit restaurer les données externes ou restaurer l'application d'abord |

Pour les mécanismes détaillés, voir [Re-signature et prévention des plantages](/fr/datamigrae/resign).

## Les applications App Store ne peuvent pas être migrées vers un disque externe

### Versions macOS inférieures à 15.1

Les versions macOS antérieures à 15.1 ne supportent pas l'installation d'applications App Store sur des disques externes. Vous devez :

1. Activer « Migration des applications App Store » dans les réglages d'AppPorts
2. Après la migration, les mises à jour d'applications nécessitent une re-migration manuelle pour écraser

### macOS 15.1 et supérieur

Si l'App Store ne peut pas mettre à jour les applications sur les disques externes :

1. Ouvrir les réglages de l'App Store
2. Activer « Télécharger et installer les grandes applications sur un disque externe »
3. Sélectionner le même stockage externe que la bibliothèque de stockage externe d'AppPorts

## L'application ne peut pas se lancer après la migration

### Étapes de dépannage

1. **Vérifier la connexion du stockage externe** : Confirmer que le stockage externe est connecté et accessible
2. **Vérifier les badges de statut de l'application** :
   - « Lien orphelin » → Application externe perdue ; suppression manuelle du lien requise
   - « Endommagé » → Exécuter la re-signature
3. **Vérifier le statut de verrouillage** : Si l'application est verrouillée (uchg), le programme de mise à jour automatique peut ne pas pouvoir s'exécuter
4. **Vérifier les journaux** : Barre de menus → Journaux → Voir dans le Finder ; rechercher les messages d'erreur pertinents
5. **Déplacer vers le local** : Dans la bibliothèque Applications externes, sélectionner « Déplacer vers le local » pour confirmer s'il s'agit d'un problème de stockage externe

## Problèmes d'affichage des répertoires de données

### Symptômes

La liste des répertoires de données affiche un statut incomplet ou incorrect.

### Résolution

1. AppPorts utilise `FolderMonitor` pour surveiller les changements du système de fichiers ; il se rafraîchit généralement automatiquement
2. Si non rafraîchi automatiquement, basculer vers un autre onglet puis revenir pour déclencher une nouvelle analyse
3. Si le problème persiste, vérifier les messages d'erreur d'analyse dans les journaux
