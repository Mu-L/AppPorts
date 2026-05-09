---
outline: deep
---

# Selbst-Updater-Erkennung

## Electron-App-Erkennung

AppPorts identifiziert Electron-Apps anhand der folgenden drei Erkennungsbedingungen (in Prioritätsreihenfolge geprüft, Kurzschlussauswertung):

| # | Erkennungselement | Pfad / Muster |
|---|-------------------|----------------|
| 1 | Electron Framework | `Contents/Frameworks/Electron Framework.framework`-Verzeichnis vorhanden |
| 2 | Electron Helper-Varianten | Einträge mit `Electron Helper` im Namen unter `Contents/Frameworks/` vorhanden |
| 3 | Info.plist Identifikationsschlüssel | `ElectronDefaultApp`- oder `electron`-Schlüssel in `Contents/Info.plist` vorhanden |

### Electron-Selbstupdate-Erkennung

Zusätzlich wird das Vorhandensein der Datei `Contents/Resources/app-update.yml` geprüft (Konfigurationsdatei für `electron-updater`). Falls vorhanden, wird die Electron-App als selbstupdatefähig markiert.

## Sparkle-App-Erkennung

AppPorts identifiziert Sparkle-Apps anhand der folgenden drei Erkennungsbedingungen:

| # | Erkennungselement | Pfad / Muster |
|---|-------------------|----------------|
| 1 | Sparkle Framework | `Contents/Frameworks/Sparkle.framework` oder `Contents/Frameworks/Squirrel.framework` vorhanden |
| 2 | Updater-Binärdateien | Dateien, die `shipit`, `autoupdate`, `updater`, `update` entsprechen, unter `Contents/MacOS/` oder `Contents/Frameworks/` vorhanden |
| 3 | Info.plist Sparkle-Schlüssel | Einer der folgenden Schlüssel in `Contents/Info.plist` vorhanden: `SUFeedURL`, `SUPublicDSAKeyFile`, `SUPublicEDKey`, `SUScheduledCheckInterval`, `SUAllowsAutomaticUpdates` |

::: warning ⚠️ Spezialbehandlung für Electron-Apps
Wenn eine App als Electron-App identifiziert wurde, wird die Erkennungsbedingung #2 (Updater-Binärdateien) übersprungen, um falsch-positive Erkennungen des `electron-updater`-`updater`-Binär als Sparkle zu vermeiden.
:::

## Hybrid Electron + Sparkle Apps

Einige Apps enthalten sowohl das Electron-Framework als auch den Sparkle-Updater. AppPorts erkennt beide Flags unabhängig, sodass `isElectron` und `isSparkle` beide `true` sein können.

### Erkennungslogik

```text
isElectron = erfüllt eine der drei Electron-Erkennungsbedingungen
isSparkle  = erfüllt eine der drei Sparkle-Erkennungsbedingungen (Electron-Apps überspringen Bedingung #2)
```

Die beiden Flags sind unabhängig und können beide gleichzeitig wahr sein.

### Verhalten nach der Migration

| Attribut | Bestimmungsbedingung |
|----------|---------------------|
| `hasSelfUpdater` | `isSparkle` oder (`isElectron` und `app-update.yml` vorhanden) oder Custom Updater vorhanden |
| `needsLock` | `isSparkle` oder (`isElectron` und `app-update.yml` vorhanden) |

Wenn `needsLock` `true` ist, führt AppPorts nach Abschluss der Migration `chflags -R uchg` (Setzen des immutable Flags) auf der externen Speicher-App aus, um zu verhindern, dass Selbst-Updater die externe Kopie löschen oder ändern.

## Custom-Updater-Erkennung

Für native Selbstupdate-Apps, die weder Sparkle noch Electron sind (z. B. Chrome, Edge, Parallels), identifiziert AppPorts diese anhand folgender Muster:

| Erkennungspfad | Übereinstimmungsmuster | Typische Apps |
|----------------|----------------------|---------------|
| `Contents/Library/LaunchServices/` | Dateiname enthält `update` | Chrome, Edge, Thunderbird |
| `Contents/MacOS/` | Binärdateiname enthält `update` oder `upgrade` (ausgenommen `electron`) | Parallels, Thunderbird |
| `Contents/SharedSupport/` | Dateiname enthält `update` | WPS Office |
| `Contents/Info.plist` | `KSProductID`-Schlüssel vorhanden | Google Keystone (Chrome) |

## Legacy-Strategie-Identifikation

Bei der Wiederherstellung oder Entlinkung muss AppPorts Legacy-Einträge erkennen, die von älteren Versionen erstellt wurden:

| Lokale Strukturerkennung | Identifiziert als |
|--------------------------|------------------|
| Stammverzeichnis ist ein symbolischer Link | `wholeAppSymlink` |
| `Contents/` ist ein symbolischer Link | `deepContentsWrapper` |
| `Contents/Info.plist` ist ein symbolischer Link | `wholeAppSymlink` (Legacy Sparkle-Hybrid-Schema) |
| `Contents/Frameworks/` ist ein symbolischer Link | `wholeAppSymlink` (Legacy Electron-Hybrid-Schema) |
| `Contents/MacOS/launcher` vorhanden | `stubPortal` |
| Keine der obigen Übereinstimmungen | Nicht von AppPorts verwaltet |
