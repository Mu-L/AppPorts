---
outline: deep
---

# Neuzeichnung & Absturzprävention

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.37.png)

## Warum Apps nach der Datenmigration abstürzen können

Der Code-Signing-Mechanismus von macOS (`codesign`) überprüft die Integrität des Anwendungspakets, einschließlich der Dateipfadstruktur. Wenn AppPorts das Datenverzeichnis einer App in den externen Speicher migriert und durch einen symbolischen Link ersetzt, wird die Signatur aufgebrochen, was folgende Probleme verursacht:

- **Gatekeeper-Blockierung**: `codesign --verify --deep --strict` erkennt Signaturfehler; das System zeigt einen „Beschädigt"- oder „Von nicht identifiziertem Entwickler"-Dialog an und blockiert den App-Start
- **Keychain-Zugriffsstörung**: Apps, die auf Keychain-Zugriffsgruppen angewiesen sind, können gespeicherte Anmeldedaten aufgrund von Signaturidentitätsänderungen nicht lesen
- **Entitlements-Fehler**: Einige App-Entitlements sind an die Signaturidentität gebunden; nach Signaturänderungen stimmen die Entitlements nicht überein

### Hochrisiko-App-Typen

| App-Typ | Risikostufe | Grund |
|---------|-------------|-------|
| Sparkle-Selbstupdate-Apps | **Hoch** | Updater kann App löschen oder ersetzen und symbolische Links beschädigen |
| Electron-Selbstupdate-Apps | **Hoch** | `electron-updater` kann ebenfalls externe Speicher-Apps stören |
| Keychain-abhängige Apps | **Hoch** | Ad-hoc-Signierung ändert die Signaturidentität; Keychain-Zugriffsgruppen schlagen fehl |
| Mac App Store-Apps | **Hoch** | SIP-Schutz; kann nicht neu signiert werden |
| Native Selbstupdate-Apps (Chrome, Edge) | Mittel | Selbstupdate kann externe Kopie ersetzen und lokalen Eintrag ungültig machen |
| iOS-Apps (Mac-Version) | Niedrig | Verwendet Stub Portal oder Whole Symlink; weniger Signaturprobleme |

### Hochrisiko-Datenverzeichnistypen

| Daten-Typ | Risikostufe | Grund |
|-----------|-------------|-------|
| `~/Library/Application Support/` | Mittel | App kann Dateisperrungen, SQLite WAL-Logs oder erweiterte Attribute verwenden; kann sich über symbolische Links abnormal verhalten |
| `~/Library/Group Containers/` | Mittel | Von mehreren Apps unter demselben Team gemeinsam genutzt; symbolische Links können andere Apps stören |
| `~/Library/Preferences/` | Niedrig-Mittel | `cfprefsd` cached plist-Dateien; symbolische Links können veraltete Daten verursachen |
| `~/Library/Caches/` | Niedrig | Caches sind wiederherstellbar; die meisten Apps gehen mit fehlenden Caches um |

## Neuzeichnungsmechanismus

### Ad-hoc-Signierung

AppPorts verwendet **Ad-hoc-Signierung** (zertifikatslose lokale Signierung), um App-Signaturen nach der Migration zu reparieren. Ausführungsbefehl:

```bash
codesign --force --deep --sign - <App-Pfad>
```

Wobei `-` die Ad-hoc-Signierung angibt (ohne Entwicklerzertifikat).

### Signierungsablauf

```mermaid
flowchart TD
    A[Neuzeichnung starten] --> B[Ursprüngliche Signaturidentität sichern]
    B --> C{Ist die App gesperrt?}
    C -->|Ja| D[uchg-Flag vorübergehend entsperren]
    C -->|Nein| E{Ist die App beschreibbar?}
    D --> E
    E =>|Nicht beschreibbar & Root-besitz| F[Eigentumswechsel mit Admin versuchen]
    E =>|Beschreibbar| G[Erweiterte Attribute bereinigen]
    F --> G
    F -->|Fehlgeschlagen & MAS-App| H[Signierung überspringen - SIP-Schutz]
    G --> I[Bundle-Stammverzeichnis aufräumen]
    I --> J{Ist Contents ein symbolischer Link?}
    J =>|Ja| K[Vorübergehend durch echte Verzeichniskopie ersetzen]
    J =>|Nein| L[Deep Signing ausführen]
    K --> L
    L =>|Fehlgeschlagen| M[Fallback auf Shallow Signing]
    L =>|Erfolgreich| N{War Contents vorübergehend ersetzt?}
    M --> N
    N =>|Ja| O[Symbolischen Link wiederherstellen]
    N =>|Nein| P[uchg-Flag wieder sperren]
    O --> P
    P => Q[Signierung abgeschlossen]
```

### Hauptschritte

1. **Ursprüngliche Signaturidentität sichern**: Vor der Signierung wird die aktuelle Signaturidentität der App gelesen (Parsing von `Authority=`-Zeilen über `codesign -dvv`), gespeichert in `~/Library/Application Support/AppPorts/signature-backups/<BundleID>.plist`

2. **Erweiterte Attribute bereinigen**: `xattr -cr` ausführen, um Resource Forks, Finder-Infos usw. zu entfernen und „detritus not allowed"-Fehler bei der Signierung zu vermeiden

3. **Bundle-Stammverzeichnis bereinigen**: `.DS_Store`, `__MACOSX`, `.git`, `.svn` und andere Reste entfernen

4. **Symbolischen Link Contents behandeln**: Falls `Contents/` ein symbolischer Link ist (Deep Contents Wrapper-Strategie), vorübergehend durch eine echte Verzeichniskopie ersetzen, dann nach der Signierung den symbolischen Link wiederherstellen

5. **Deep Signing → Shallow Signing Fallback**: Bevorzugt `--deep`-Signierung (alle verschachtelten Komponenten abdeckend); schlägt es aufgrund von Berechtigungs- oder Resource Fork-Problemen fehl, wird auf Shallow Signing ohne `--deep` zurückgegriffen

6. **Wiederholungsmechanismus**: Wenn `codesign` einen „internal error" erzeugt oder durch SIGKILL beendet wird, bis zu 2-mal wiederholen

## Signatur-Sicherung & Wiederherstellung

### Pfadauflösung für verknüpfte Apps

Für verknüpfte Apps (Status: „Verknüpft") lösen Signierungsoperationen automatisch den **echten externen App-Pfad** auf, anstatt die lokale Stub-Portal-Shell oder den symbolischen Link zu verwenden. Auflösungsstrategie:

| Migrationsmethode | Auflösung |
|-------------------|-----------|
| Whole App Symlink | Löst das symbolische Link-Ziel zum echten externen `.app`-Pfad auf |
| Stub Portal | Extrahiert den `REAL_APP='...'-Pfad aus dem `Contents/MacOS/launcher`-Skript |

Das bedeutet, dass Sicherungs-, Wiederherstellungs- und Neuzeichnungsoperationen immer das tatsächliche Anwendungspaket betreffen und Signaturänderungen wirksam werden.

### Sicherung

Sicherungsdateien werden im Verzeichnis `~/Library/Application Support/AppPorts/signature-backups/` gespeichert, benannt nach der **realen App** `BundleID.plist`:

| Feld | Beschreibung |
|------|--------------|
| `bundleIdentifier` | Bundle ID der App |
| `signingIdentity` | Ursprüngliche Signaturidentität (z. B. `Developer ID Application: ...` oder `ad-hoc`) |
| `originalPath` | Ursprünglicher App-Pfad |
| `backupDate` | Sicherungszeitstempel |

Sicherungen werden zu folgenden Zeitpunkten ausgelöst:

- Vor der Datenverzeichnismigration (falls automatische Neuzeichnung aktiviert ist) — verwendet den realen App-Pfad für die Sicherung
- Vor jeder Signierungsoperation (idempotent; überschreibt keine vorhandenen Sicherungen)
- Manuelle „Signatur sichern"-Aktion

### Wiederherstellung

Bei der Signaturwiederherstellung führt AppPorts unterschiedliche Strategien basierend auf der gesicherten Signaturidentität aus:

| Gesicherte Signaturidentität | Wiederherstellungsverhalten |
|-----------------------------|----------------------------|
| `ad-hoc` oder leer | `codesign --remove-signature` ausführen, um Signatur zu entfernen; Sicherung löschen |
| Gültige Entwicklerzertifikat-Identität | Prüfen, ob Zertifikat in Keychain vorhanden ist. Falls vorhanden, mit ursprünglicher Identität neu signieren |
| Gültige Entwicklerzertifikat-Identität, aber Zertifikat nicht auf diesem Rechner | **Fallback auf Ad-hoc-Signierung**; ursprüngliche Signatur kann nicht vollständig wiederhergestellt werden |

### Wiederherstellungsfehler-Szenarien

Die folgenden Szenarien führen zu einem Signaturwiederherstellungsfehler oder einer unvollständigen Wiederherstellung:

| Szenario | Ergebnis |
|----------|----------|
| Sicherungs-plist-Datei existiert nicht | Wirft `noBackupFound`-Fehler; Wiederherstellung nicht möglich |
| Ursprüngliches Entwicklerzertifikat nicht in lokaler Keychain | Fallback auf Ad-hoc-Signierung. App kann starten, aber Keychain-Zugriffsgruppen und einige Entitlements können fehlschlagen |
| Mac App Store-Apps (SIP-Schutz) | Wird stillschweigend übersprungen. SIP verhindert jegliche Änderung an System-App-Signaturen |
| App-Verzeichnis nicht beschreibbar & Root-besitz | Versuch, Eigentumswechsel über Admin-Rechte durchzuführen. Schlägt fehl, wenn der Benutzer die Autorisierungsanfrage abbricht |
| Contents symbolischer Link-Ziel verloren | `copyItem` schlägt im temporären Ersetzungsschritt fehl; Signierung kann nicht ausgeführt werden |
| Benutzer bricht Admin-Autorisierung ab | Wirft `codesignFailed("User cancelled authorization")` |
| Deep und Shallow Signing beide fehlgeschlagen | Fehler wird nach oben weitergeleitet; Signierungsoperation schlägt fehl |

::: warning ⚠️ Über verlorene Entwicklerzertifikate
Das häufigste reale Wiederherstellungsfehler-Szenario ist: Die ursprüngliche App wurde von einem Drittanbieter signiert (z. B. `Developer ID Application: Google LLC`), aber die Keychain des aktuellen Rechners hat nicht den entsprechenden privaten Schlüssel. In diesem Fall kann die Wiederherstellungsoperation nur eine Ad-hoc-Signatur erzeugen; **die ursprüngliche Signaturidentität kann nicht vollständig wiederhergestellt werden**. Für Apps, die auf bestimmte Signaturidentitäten für Keychain-Zugriffsgruppen oder Unternehmenskonfigurationsprofile angewiesen sind, kann dies zu Funktionsanomalien führen.
:::
