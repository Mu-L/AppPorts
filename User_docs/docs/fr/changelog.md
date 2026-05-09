---
outline: deep
---

# Journal des modifications

## v1.5.5

Version actuelle.

## v1.5.0

- Ajout du support d'installation externe d'applications App Store macOS 15.1+
- Ajout de la fonctionnalité de re-signature automatique (exécutée automatiquement après la migration du répertoire de données)
- Ajout des tests d'audit de localisation `LocalizationAuditTests`
- Amélioration de la logique de génération du Info.plist du Stub Portal
- Correction du problème de perte d'icône Launchpad pour certaines applications après migration

## v1.4.0

- Ajout de la vue en arborescence des répertoires de données
- Ajout de la détection des répertoires d'outils (30+ outils de développement)
- Ajout de la fonctionnalité d'exportation de package de diagnostic
- Amélioration de la détection des mises à jour automatiques (Chrome, Edge et autres mises à jour personnalisées)
- Correction du mécanisme de récupération automatique après interruption de migration

## v1.3.0

- Ajout de la fonctionnalité de migration des répertoires de données
- Ajout de la gestion des signatures de code (sauvegarde/restauration des signatures originales)
- Ajout de la détection automatique des applications Sparkle et Electron
- Amélioration de la protection de migration verrouillée (`chflags uchg`)
- Correction des problèmes d'affichage des badges dans le Finder

## v1.2.0

- Ajout de la stratégie de migration Stub Portal (remplaçant Deep Contents Wrapper)
- Ajout du support de migration des applications iOS (applications iOS version Mac)
- Amélioration des performances de migration par lots
- Correction du problème où certaines applications ne pouvaient pas se lancer après restauration

## v1.1.0

- Ajout du support multilingue (20+ langues)
- Ajout de la migration des répertoires de suites d'applications (par ex., Microsoft Office)
- Amélioration de la détection de stockage externe hors ligne
- Correction du problème de pénétration de lien symbolique avec la stratégie Deep Contents Wrapper

## v1.0.0

- Première version officielle
- Support de la migration d'applications vers le stockage externe (Deep Contents Wrapper / Whole App Symlink)
- Support de la restauration d'applications et de la gestion des liens
- Support de la surveillance de système de fichiers en temps réel FolderMonitor
