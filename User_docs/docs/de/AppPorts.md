---
outline: deep
---

# AppPorts Benutzerhandbuch

Dieses Handbuch stellt systematisch die Funktionen, Designprinzipien und technische Umsetzung von AppPorts vor. Weitere technische Details finden Sie unter [DeepWiki](https://deepwiki.com/wzh4869/AppPorts). Verbesserungsvorschläge bitte über die Projekt-[Issues](https://github.com/wzh4869/AppPorts/issues) einreichen.

## Überblick

AppPorts ist ein Anwendungsmigrations- und Verknüpfungstool für [macOS](https://www.apple.com/macos/), das die Migration großer Anwendungen auf externe Speichergeräte unterstützt, während die vollständige Systemfunktionalität und Konsistenz erhalten bleibt.

### AppPorts-Philosophie

| Prinzip | Beschreibung |
|---------|--------------|
| **Transparente Erfahrung** | Stellt sicher, dass die Benutzererfahrung und das Betriebssystem die App weiterhin als vom internen Speicher ausgeführt wahrnehmen |
| **Stabile Strategie** | Bevorzugt erprobte, stabilere Migrationsansätze |
| **Geringe Systemlast** | Keine Daemons, vermeidet kontinuierliche Systemressourcenverbrauch |
| **Breite Internationalisierung** | Bevorzugt die Abdeckung vieler Sprachen; Übersetzungsbreite vor Präzision |
| **Barrierefreiheitsfreundlich** | Umfassende Barrierefreiheitsunterstützung |

## Kernfunktionen

- **Badge-freie Migration**: Ein-Klick-Migration großer Apps auf externe Laufwerke. Lokal bleibt nur eine leichte Launcher-Hülle übrig; der Finder zeigt keine Verknüpfungspfeile an; Launchpad und macOS-App-Menü funktionieren normal.
- **Auto-Update-Schutz**: Erkennt automatisch Apps mit Auto-Update-Unterstützung (Sparkle, Electron, Chrome usw.) und bietet eine Option „Gesperrte Migration", um zu verhindern, dass Auto-Updater Apps auf dem externen Laufwerk löschen oder überschreiben.
- **Code-Signatur-Verwaltung**: Falls nach der Migration eine „Beschädigt"-Meldung erscheint, Ein-Klick-Neuzeichnung über das Rechtsklickmenü. Unterstützt das Sichern und Wiederherstellen der ursprünglichen Signaturen; automatische Neuzeichnung nach Datenverzeichnismigration.
- **macOS 15.1+ App Store-Unterstützung**: Unterstützt die Installation von App Store-Apps direkt auf externe Laufwerke mit In-Place-Updates auf dem externen Laufwerk.
- **Ein-Klick-Wiederherstellung**: Unterstützt die Rückmigration von Apps in den lokalen Speicher mit automatischer Linkentfernung. Automatische Wiederherstellung bei unterbrochener Migration.
- **Datenverzeichnisverwaltung**: Unterstützt die Migration von App-Datenverzeichnissen (`~/Library/`-Unterverzeichnisse, `~/.npm` usw.) in den externen Speicher, mit Baumansicht-Gruppierung, Suche und Sortierung.

## Glossar

### Migrationsstrategien

#### Deep Contents Wrapper (Contents-Verzeichnismigration)

Die Standard-Dateistruktur einer macOS-Anwendung sieht wie folgt aus:

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

Die Deep Contents Wrapper-Strategie migriert alle Anwendungsinhalte in den externen Speicher und erstellt lokal ein leeres `.app`-Verzeichnis mit nur einem symbolischen Link, der auf das externe `Contents`-Verzeichnis verweist. Da macOS ein vollständiges `.app`-Paket erkennt (und keine Verknüpfung), zeigt der Finder keine Pfeilmarkierungen an; Icons, Launchpad und App-Menüs funktionieren normal.

::: warning ⚠️ Diese Strategie ist in der aktuellen Version veraltet
Der Hauptnachteil von Deep Contents Wrapper ist, dass Auto-Updater symbolischen Links folgen und Dateien direkt im externen Speicher ändern, was die Anwendung beschädigen kann.
:::

#### Stub Portal

Der Stub Portal-Ansatz erstellt lokal eine minimale `.app`-Hülle, die nur diese vier Elemente enthält:

| Komponente | Beschreibung |
|------------|--------------|
| `Contents/MacOS/launcher` | Bash-Launchskript, das `open "/Volumes/External/SomeApp.app"` ausführt |
| `Contents/Resources/` | Icon-Datei, die von der externen Anwendung kopiert wird |
| `Contents/Info.plist` | Vereinfacht aus der externen App-`Info.plist`, mit `CFBundleExecutable` auf `launcher` gesetzt, `LSUIElement=true` (nicht im Dock angezeigt) und alle update-bezogenen Konfigurationsschlüssel entfernt |
| `Contents/PkgInfo` | Standard-4-Byte-Kennungsdatei |

Wenn der Benutzer auf diese Hülle klickt, führt macOS das `launcher`-Skript aus und öffnet die echte Anwendung auf dem externen Laufwerk über den `open`-Befehl. Es sind keine symbolischen Links lokal vorhanden; Auto-Updater können nicht durchdringen.

##### iOS Stub Portal

Das Grundprinzip ist dasselbe wie beim Standard Stub Portal, aber die Icon-Behandlung unterscheidet sich. iOS-App-Icons sind nicht in `Info.plist` angegeben, sondern als mehrere `AppIcon.png`-Dateien in den `Wrapper/`- oder `WrappedBundle/`-Verzeichnissen gespeichert. Der Ablauf ist:

1. Höchstauflösende `AppIcon.png`-Datei finden
2. Mit `sips` auf 256×256 Pixel skalieren
3. Mit `sips` ins `.icns`-Format konvertieren
4. `Info.plist` aus `iTunesMetadata.plist` generieren (iOS-Apps enthalten keine standardmäßige `Info.plist`)

#### Whole Symlink

Erstellt das gesamte `.app`-Verzeichnis als symbolischen Link zum externen Speicher:

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

Lokal wird nur ein symbolischer Link ohne tatsächliche Dateien beibehalten. macOS kann die App normal öffnen, aber der Finder zeigt Pfeilverknüpfungsmarker auf dem Icon an, und das Launchpad hat gelegentlich Kompatibilitätsprobleme. Auto-Updater können auch über den symbolischen Link auf externe App-Dateien zugreifen. Dies ist AppPorts' Fallback-Migrationsstrategie.
