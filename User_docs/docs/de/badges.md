---
outline: deep
---

# Status-Badges

AppPorts zeigt den aktuellen Status von Apps und Datenverzeichnissen mit kapselförmigen farbigen Badges an. Einige Badges sind anklickbar für detaillierte Informationen.

## App-Status-Badges

### Linkstatus

| Badge | Icon | Farbe | Bedeutung |
|-------|------|-------|-----------|
| Verknüpft | `link` | Grün | App in den externen Speicher migriert mit lokalem Eintrag |
| Gesperrte Migration | `lock.fill` | Grün | Verknüpft und mit `uchg` gesperrt, verhindert Beschädigung der externen App durch Selbstupdates |
| Entsperre Migration | `lock.open` | Orange | Verknüpft aber nicht gesperrt; In-App-Updates können die externe App löschen |
| Teilweise verknüpft | `link.badge.plus` | Gelb | Teilweise App-Komponenten verknüpft (z. B. einige `.app`-Dateien in einem Verzeichnis) |
| Verwaister Link | `link.badge.exclamationmark` | Rot | Externe Speicher-App verloren, aber lokaler Eintrag vorhanden |
| Nicht verknüpft | `externaldrive.badge.xmark` | Orange | App auf externem Speicher, aber lokal nicht verknüpft |
| Extern | `externaldrive` | Orange | App auf externem Speicher ohne lokalen Eintrag |
| Lokal | `macmini` | Sekundärfarbe | Normale lokale App, nicht migriert; wird angezeigt, wenn keine anderen Tags vorhanden sind |

### Framework-Labels

| Badge | Icon | Farbe | Bedeutung | Klickaktion |
|-------|------|-------|-----------|-------------|
| Sparkle | `arrow.triangle.2.circlepath` | Cyan | Verwendet Sparkle-Framework für Auto-Updates | Nach Migration in den externen Speicher können In-App-Updates zum Verlust der externen App führen; gesperrte Migration empfohlen |
| Electron | `atom` | Indigo | Basiert auf Electron-Framework mit Auto-Update-Unterstützung | Nach Migration in den externen Speicher können In-App-Updates zum Verlust der externen App führen; gesperrte Migration empfohlen |

### Typ-Labels

| Badge | Icon | Farbe | Bedeutung |
|-------|------|-------|-----------|
| Läuft | `play.fill` | Lila | App wird gerade ausgeführt |
| System | `lock.fill` | Grau | macOS-Systemanwendung |
| Nicht-nativ | `iphone` | Pink | iOS/iPadOS-App (läuft über Apple Silicon) |
| Store | `applelogo` | Blau | Mac App Store-Anwendung |

### Spezielle Labels

| Badge | Icon | Farbe | Bedeutung |
|-------|------|-------|-----------|
| Neu signiert | `seal.fill` | Cyan | App wurde Ad-hoc neu signiert (ausgeführt, wenn nach der Migration „Beschädigt" erscheint) |

::: tip 💡 Spezieller Hinweis zum Store-Label
Wenn eine App die folgenden Bedingungen erfüllt, wird das „Store"-Label anklickbar und zeigt macOS 15.1+ native Installationsanweisungen an:
- App befindet sich im `/Volumes/{Laufwerk}/Applications/`-Verzeichnis auf dem externen Speicher
- Wird nativ von macOS verwaltet; der App Store kann inkrementelle Updates direkt in diesem Verzeichnis durchführen
:::

## Datenverzeichnis-Status-Badges

| Status | Farbe | Bedeutung |
|--------|-------|-----------|
| Lokal | Sekundärfarbe | Verzeichnis auf lokalem Speicher, nicht migriert |
| Verknüpft | Grün | In den externen Speicher migriert; lokal ist ein symbolischer Link |
| Normalisierung erforderlich | Gelb | Von AppPorts verwalteter Link, aber externer Pfad nicht am kanonischen Ort; „Normalisieren"-Operation empfohlen |
| Neuverlinkung erforderlich | Orange | Externe Speicherdaten vorhanden, aber lokaler symbolischer Link verloren; „Neuverlinken"-Operation empfohlen |
| Vorhandener Soft Link | Blau | Vom Benutzer erstellter symbolischer Link (nicht von AppPorts erstellt); Option zur Übernahme der Verwaltung |

## App-Status-Kombinationen

Eine App kann gleichzeitig mehrere Badges anzeigen:

```text
[Verknüpft] [Sparkle] [Läuft]
```
Bedeutung: App in den externen Speicher migriert, verwendet Sparkle Auto-Update-Framework, wird gerade ausgeführt.

```text
[Extern] [Store] [Nicht-nativ]
```
Bedeutung: iOS-App (Mac-Version) auf externem Speicher, über App Store installiert.

```text
[Verwaister Link]
```
Bedeutung: Externe Speicher-App verloren oder entfernt, aber lokaler Eintrag noch vorhanden. Manuelle Entlinkung erforderlich.
