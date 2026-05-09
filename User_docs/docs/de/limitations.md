---
outline: deep
---

# Kompatibilität & Einschränkungen

## Systemanforderungen

| Anforderung | Beschreibung |
|-------------|--------------|
| Minimale OS-Version | macOS 12.0 (Monterey) |
| Architektur | Intel x86_64 / Apple Silicon (arm64) |
| Berechtigungen | Vollständiger Festplattenzugriff |
| Externer Speicher | Mindestens ein externes Speichergerät erforderlich |

## Funktionskompatibilität

### Nach macOS-Version

| Funktion | macOS 12.0 - 15.0 | macOS 15.1+ |
|----------|:---:|:---:|
| App-Migration (Stub Portal) | ✓ | ✓ |
| Datenverzeichnismigration | ✓ | ✓ |
| Code-Signatur-Verwaltung | ✓ | ✓ |
| App Store-App-Migration auf externes Laufwerk | ✗ | ✓ |
| App Store-App In-Place-Update auf externem Laufwerk | ✗ | ✓ |
| iOS-App-Migration | ✓ | ✓ |

::: warning ⚠️ App Store-Apps auf macOS-Versionen unter 15.1
macOS-Versionen vor 15.1 (Sequoia) unterstützen die App Store-App-Installation auf externe Laufwerke nicht. Sie müssen „App Store-App-Migration" manuell in den AppPorts-Einstellungen aktivieren, und App-Updates erfordern eine manuelle Re-Migration zum Überschreiben.
:::

### Nach App-Typ

| App-Typ | Migration | Wiederherstellung | Auto-Update | Hinweise |
|---------|:---:|:---:|:---:|----------|
| Native macOS-App | ✓ | ✓ | ✓ | Beste Kompatibilität |
| Sparkle-App | ✓ | ✓ | Sperrung erforderlich | Sperrung verhindert In-App-Updates; muss für Update wiederhergestellt werden |
| Electron-App | ✓ | ✓ | Sperrung erforderlich | Wie Sparkle |
| Chrome / Edge (Custom Updater) | ✓ | ✓ | ✓ | Updater installiert lokal; beschädigt externe Kopie nicht |
| App Store-App (macOS 15.1+) | ✓ | ✓ | ✓ | Native externe Installation; App Store kann direkt aktualisieren |
| App Store-App (macOS <15.1) | ✓ | ✓ | Manuell | Updates erfordern Re-Migration |
| iOS-App (Mac-Version) | ✓ | ✓ | ✓ | Verwendet iOS Stub Portal |
| System-Apps | ✗ | — | — | SIP-Schutz; kann nicht migriert werden |

### Nach Datenverzeichnistyp

| Datenverzeichnistyp | Migration | Risiko |
|---------------------|:---:|--------|
| `~/Library/Application Support/` | ✓ | Mittel — kann Dateisperrungen oder SQLite WAL-Logs verwenden |
| `~/Library/Preferences/` | ✓ | Niedrig-Mittel — `cfprefsd`-Caching kann veraltete Lesungen verursachen |
| `~/Library/Containers/` | ✓ | Mittel — wird von Apps unter demselben Team gemeinsam genutzt |
| `~/Library/Group Containers/` | ✓ | Mittel — gemeinsame Daten können andere Apps stören |
| `~/Library/Caches/` | ✓ | Niedrig — Caches sind wiederherstellbar |
| `~/Library/Logs/` | ✓ | Niedrig — nur Protokolldateien |
| `~/Library/WebKit/` | ✓ | Mittel — WebKit lokaler Speicher |
| `~/Library/HTTPStorages/` | ✓ | Niedrig | Netzwerk-Sitzungsspeicher |
| `~/Library/Application Scripts/` | ✓ | Niedrig | Erweiterungsskripte |
| `~/Library/Saved Application State/` | ✓ | Niedrig | Fensterzustandswiederherstellung |
| `~/.npm`, `~/.m2` usw. Dot-Folder | ✓ | Niedrig | Entwicklungstool-Caches |

## Nicht-migrierbare Inhalte

### SIP-geschützt

| Pfad | Grund |
|------|-------|
| macOS-System-Apps (Safari, Finder usw.) | System Integrity Protection |
| `~/Library/Containers/` Stammverzeichnis | macOS-Systemschutz |

### Enthält Pfadreferenzen

| Pfad | Grund |
|------|-------|
| `~/.local` | Enthält ausführbare Pfadreferenzen; Befehlszeilentools können nach der Migration fehlschlagen |
| `~/.config` | Enthält absolute Pfadkonfigurationen; Tool-Konfigurationen können nach der Migration fehlschlagen |

## Anforderungen an externen Speicher

| Anforderung | Beschreibung |
|-------------|--------------|
| Dateisystem | APFS, HFS+, exFAT unterstützt |
| Mindestspeicherplatz | Abhängig von der Größe der migrierten Apps |
| Schnittstelle | USB, Thunderbolt, NVMe alle unterstützt |
| Verbunden bleiben | Externer Speicher muss nach der Migration verbunden bleiben; andernfalls können Apps nicht gestartet werden |

::: tip 💡 Dateisystemempfehlungen
- **APFS**: Empfohlen; unterstützt Klone, Snapshots, beste Leistung
- **HFS+**: Gute Kompatibilität; geeignet für ältere Macs
- **exFAT**: Plattformübergreifend kompatibel; unterstützt keine Hard Links und Klone
:::
