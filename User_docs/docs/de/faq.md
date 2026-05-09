---
outline: deep
---

# FAQ

## Installation & Berechtigungen

### Welche Berechtigungen benötigt AppPorts?

AppPorts benötigt die **„Vollständiger Festplattenzugriff"**-Berechtigung, um das `/Applications`-Verzeichnis zu lesen und zu ändern. Beim ersten Start wird es Sie durch die Autorisierung führen. Sie können es auch manuell in Systemeinstellungen → Datenschutz & Sicherheit → Vollständiger Festplattenzugriff hinzufügen.

### Welche macOS-Versionen werden unterstützt?

Mindestens macOS 12.0 (Monterey). macOS 15.1 (Sequoia) und neuer unterstützen zusätzlich die App Store-App-Installation auf externe Laufwerke mit In-Place-Updates.

## App-Migration

### Was ist, wenn die App nach der Migration nicht geöffnet werden kann?

1. Bestätigen Sie, dass der externe Speicher verbunden und zugänglich ist
2. Prüfen Sie das App-Status-Badge: Bei „Verwaister Link" ist die externe App verloren; manuelle Entlinkung erforderlich
3. Erscheint eine „Beschädigt"-Meldung, klicken Sie mit der rechten Maustaste auf die App und wählen Sie „Neu signieren"
4. Wird das Problem nicht gelöst, wählen Sie in der Externe-Apps-Bibliothek „Zurück in den lokalen Speicher verschieben"

### Was ist, wenn ich eine „Beschädigt"-Meldung sehe?

Der Code-Signing-Mechanismus von macOS hat eine Änderung in der App-Paketstruktur erkannt. Lösung:

1. Rechtsklick auf die App in AppPorts
2. „Neu signieren" auswählen
3. AppPorts sichert automatisch die ursprüngliche Signatur und führt die Ad-hoc-Neuzeichnung aus

Für detaillierte Mechanismen siehe [Neuzeichnung & Absturzprävention](/de/datamigrae/resign).

### Stürzt die App ab, wenn der externe Speicher abgesteckt wird?

Der lokale Eintrag (Stub Portal) versucht, `open` aufzurufen, um die externe App zu starten. Ist der externe Speicher nicht verbunden, kann die App nicht gestartet werden, stürzt aber nicht ab. Nach dem Wiederverbinden des externen Speichers wird der normale Gebrauch wieder aufgenommen.

### Können Apps nach der Migration aktualisiert werden?

Hängt vom App-Typ ab:

| App-Typ | Kann automatisch aktualisieren | Hinweise |
|---------|:---:|----------|
| Native Apps (ohne Selbstupdate) | ✓ | Normale Updates |
| Chrome, Edge (Custom Updater) | ✓ | Updates installieren lokal; AppPorts erkennt Versionsunterschied und markiert „Ausstehende Migration" |
| Sparkle / Electron Apps | ✗ | Sperrung verhindert In-App-Updates; muss vor Update über AppPorts lokal wiederhergestellt werden |
| App Store-Apps (macOS 15.1+) | ✓ | App Store kann direkt auf externem Laufwerk aktualisieren |
| App Store-Apps (macOS <15.1) | ✗ | Manuelle Re-Migration erforderlich |

### Wie migriere ich App Store-Apps auf ein externes Laufwerk?

**macOS 15.1+**: In den App Store-Einstellungen „Große Apps auf ein externes Laufwerk herunterladen und installieren" aktivieren und dasselbe externe Speichergerät wie AppPorts auswählen.

**macOS <15.1**: In den AppPorts-Einstellungen „App Store-App-Migration" aktivieren. Nach manueller Migration erfordern App-Updates eine Re-Migration.

### Die Migration ist langsam/hängt. Was tun?

- Bei 100% Migrationsfortschritt kann es eine 1-2 Sekunden Pause geben, während lokale Einträge erstellt werden
- Große Apps (z. B. Xcode, Adobe) brauchen länger für die Migration — das ist normal
- Hängt die Migration lange, prüfen Sie die Verbindungsstabilität des externen Speichers
- USB 2.0 ist langsam; empfohlen wird USB 3.0 oder höher, oder Thunderbolt

## Datenverzeichnismigration

### Gehen Daten nach der Datenverzeichnismigration verloren?

Nein. AppPorts verwendet die Strategie des symbolischen Links: Daten werden zuerst vollständig in den externen Speicher kopiert; erst nach Bestätigung der erfolgreichen Kopie wird das ursprüngliche lokale Verzeichnis gelöscht. Jeder fehlgeschlagene Schritt löst einen automatischen Rollback aus.

### Wann kann die Datenverzeichnismigration App-Probleme verursachen?

- Apps, die Dateisperrungen oder SQLite WAL-Logs verwenden
- Erweiterte Attribute können über symbolische Links verloren gehen
- Group Containers-Verzeichnisse, die von mehreren Apps unter demselben Team gemeinsam genutzt werden

### Wie stelle ich migrierte Datenverzeichnisse wieder her?

In der Datenverzeichnisverwaltungsoberfläche von AppPorts das migrierte Verzeichnis auswählen und auf „Wiederherstellen" klicken. AppPorts löscht den symbolischen Link und kopiert Daten vom externen Speicher zurück in den lokalen Speicher.

## Sonstiges

### Sammelt AppPorts meine Daten?

Nein. AppPorts läuft vollständig offline und sammelt oder lädt keine Benutzerdaten hoch. Protokolldateien werden lokal in `~/Library/Application Support/AppPorts/` gespeichert.

### Wie melde ich Probleme?

Bitte reichen Sie diese auf der Projekt-[Issues](https://github.com/wzh4869/AppPorts/issues)-Seite ein. Es wird empfohlen, ein Diagnosepaket beizufügen (Menüleiste → Protokolle → Diagnosepaket exportieren), um die Problemlösung zu beschleunigen.
