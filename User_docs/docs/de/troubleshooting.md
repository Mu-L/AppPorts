---
outline: deep
---

# Fehlerbehebung

## Migrationsunterbrechung

### Symptome

Migration wurde durch Trennung des externen Speichers, Systemabsturz oder App-Zwangsbeendigung unterbrochen.

### Lösung

AppPorts hat einen eingebauten Auto-Wiederherstellungsmechanismus. Nach dem Neustart von AppPorts:

1. Erkennt verbleibende Migrationsdaten (externe Kopie vorhanden, aber lokaler symbolischer Link nicht erstellt)
2. Prüft `.appports-link-metadata.plist` im externen Verzeichnis
3. Nur wenn `schemaVersion`, `managedBy`, `sourcePath`, `destinationPath` und `dataDirType` vollständig übereinstimmen, wird die Wiederherstellung oder Neuverlinkung fortgesetzt
4. Stimmen die Metadaten nicht überein, stoppt AppPorts die automatische Verarbeitung und erhält die vorhandenen Daten zur manuellen Prüfung

::: tip 💡 Kein manueller Eingriff erforderlich
Der Auto-Wiederherstellungsmechanismus von AppPorts behandelt unterbrochene Migrationen beim nächsten Start. Falls die Auto-Wiederherstellung fehlschlägt, sehen Sie möglicherweise den Status „Normalisierung erforderlich" oder „Neuverlinkung erforderlich" in der Datenverzeichnisliste — führen Sie einfach die entsprechende Operation manuell aus.
:::

## Externer Speicher offline

### Symptome

Nach dem Abstecken oder Trennen des externen Speichers können migrierte Apps nicht gestartet werden, und Datenverzeichnisse zeigen roten Fehlerstatus an.

### Lösung

1. Externen Speicher wieder verbinden
2. AppPorts' `FolderMonitor` erkennt automatisch das Einhängen des Speichervolumes und löst einen erneuten Scan aus
3. Apps und Datenverzeichnisse nehmen den normalen Gebrauch wieder auf

::: warning ⚠️ Hinweis
Während der externe Speicher offline ist, schlagen lokale Einträge (Stub Portal), die `open` aufrufen, fehl; Apps können nicht gestartet werden, stürzen aber nicht ab. Datenverzeichnis-Symbolische Links zeigen auf ungültige Pfade; assoziierte Apps können möglicherweise keine Daten lesen.
:::

## Signaturwiederherstellung fehlgeschlagen

### Symptome

Der Versuch, die ursprüngliche Signatur wiederherzustellen, schlägt fehl, oder die App zeigt nach der Wiederherstellung immer noch „Beschädigt" an.

### Mögliche Ursachen & Lösung

| Ursache | Lösung |
|---------|--------|
| Sicherungsdatei existiert nicht | Ursprüngliche Signatur kann nicht wiederhergestellt werden; Ad-hoc-Neuzeichnung als Alternative ausführen |
| Ursprüngliches Entwicklerzertifikat nicht in lokaler Keychain | AppPorts weicht automatisch auf Ad-hoc-Signierung aus; App kann starten, aber Keychain-Zugriff kann abnormal sein |
| Mac App Store-App (SIP-Schutz) | Kann nicht neu signiert werden; SIP verhindert jegliche Änderung an System-App-Signaturen |
| App-Verzeichnis ist Root-besitz | AppPorts versucht, Eigentumswechsel über Admin-Rechte durchzuführen; im Popup autorisieren |
| Contents symbolischer Link-Ziel verloren | Kann nicht signiert werden; externe Daten müssen zuerst wiederhergestellt oder App zurückverschoben werden |

Für detaillierte Mechanismen siehe [Neuzeichnung & Absturzprävention](/de/datamigrae/resign).

## App Store-Apps können nicht auf externes Laufwerk migriert werden

### macOS-Versionen unter 15.1

macOS-Versionen vor 15.1 unterstützen die App Store-App-Installation auf externe Laufwerke nicht. Sie müssen:

1. „App Store-App-Migration" in den AppPorts-Einstellungen aktivieren
2. Nach der Migration erfordern App-Updates eine manuelle Re-Migration zum Überschreiben

### macOS 15.1 und höher

Falls der App Store Apps auf externen Laufwerken nicht aktualisieren kann:

1. App Store-Einstellungen öffnen
2. „Große Apps auf ein externes Laufwerk herunterladen und installieren" aktivieren
3. Dasselbe externe Speichergerät wie die AppPorts-externe Speicherbibliothek auswählen

## App kann nach der Migration nicht gestartet werden

### Fehlerschritte

1. **Externe Speicherverbindung prüfen**: Bestätigen, dass der externe Speicher verbunden und zugänglich ist
2. **App-Status-Badges prüfen**:
   - „Verwaister Link" → Externe App verloren; manuelle Entlinkung erforderlich
   - „Beschädigt" → Neuzeichnung ausführen
3. **Sperrstatus prüfen**: Falls die App gesperrt ist (uchg), kann der Selbst-Updater möglicherweise nicht ausgeführt werden
4. **Protokolle prüfen**: Menüleiste → Protokolle → Im Finder anzeigen; nach relevanten Fehlermeldungen suchen
5. **Zurück in den lokalen Speicher verschieben**: In der Externe-Apps-Bibliothek „Zurück in den lokalen Speicher verschieben" auswählen, um zu prüfen, ob es ein Problem mit dem externen Speicher ist

## Zielpfad existiert bereits

AppPorts ersetzt ein App-Ziel nur automatisch, wenn die App den Status „Ausstehendes Herausverschieben" hat oder das Ziel als alter AppPorts-Portal-Eintrag bzw. Rest erkannt wird. Datenverzeichnisse werden nur bei vollständig passenden AppPorts-Metadaten automatisch wiederhergestellt. Unabhängige echte Apps oder Verzeichnisse werden nicht überschrieben, sondern als Konflikt gemeldet.

## Datenverzeichnis-Anzeigeprobleme

### Symptome

Die Datenverzeichnisliste zeigt unvollständigen oder falschen Status an.

### Lösung

1. AppPorts verwendet `FolderMonitor` zur Überwachung von Dateisystemänderungen; aktualisiert sich normalerweise automatisch
2. Wird nicht automatisch aktualisiert, wechseln Sie zu einem anderen Reiter und zurück, um einen erneuten Scan auszulösen
3. Besteht das Problem weiterhin, prüfen Sie die Scan-Fehlermeldungen in den Protokollen
