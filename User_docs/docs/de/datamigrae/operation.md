---
outline: deep
---

# Datenmigrations-Betriebshandbuch

Diese Seite behandelt den praktischen Arbeitsablauf für die Datenverzeichnismigration. Technische Implementierungsdetails finden Sie unter [Grundlegende Implementierung](/de/datamigrae/baseinfo).

## App-assoziierte Datenverzeichnisse finden

1. Wechseln Sie im Hauptfenster von AppPorts zum Reiter „Datenverzeichnisse"
2. Das linke Panel zeigt alle installierten Apps
3. Klicken Sie auf eine App; das rechte Panel zeigt die zugehörigen Datenverzeichnisse unter `~/Library/` an

AppPorts scannt automatisch die folgenden Verzeichnisse und gleicht sie anhand der App Bundle ID oder des Namens ab:

| Scan-Pfad | Abgleichmethode |
|-----------|-----------------|
| `~/Library/Application Support/` | Bundle ID oder App-Name |
| `~/Library/Preferences/` | Bundle ID oder App-Name |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID oder App-Name |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | App-Name |
| `~/Library/Saved Application State/` | App-Name |

## Tool-Verzeichnisse (Dot-Folders)

AppPorts kann automatisch Dot-Folders erkennen, die von gängigen Entwicklungstools im Home-Verzeichnis des Benutzers erstellt wurden:

1. Wechseln Sie zum Unterreiter „Tool-Verzeichnisse" im Reiter Datenverzeichnisse
2. Die Seite listet alle erkannten Tool-Verzeichnisse mit ihren Größen auf
3. Jedes Verzeichnis zeigt ein Prioritäts-Badge (recommended/optional) und den Status

Für die vollständige unterstützte Liste siehe [Tool-Verzeichnis-Erkennung](/de/datamigrae/tools).

## Migrationsvorgänge

### Einzelverzeichnis-Migration

1. Finden Sie das zu migrierende Verzeichnis in der Datenverzeichnisliste
2. Klicken Sie rechts auf die Schaltfläche „Migrieren"
3. AppPorts führt die folgenden Schritte aus:
   - Verzeichnis in den externen Speicher kopieren
   - Verwaltete Link-Metadaten schreiben
   - Ursprüngliches lokales Verzeichnis löschen
   - Symbolischen Link erstellen

### Batch-Migration

1. Aktivieren Sie mehrere Verzeichnisse in der Tool-Verzeichnisliste
2. Klicken Sie unten auf die Schaltfläche „Batch-Migration"
3. AppPorts führt die Migration nacheinander aus

::: tip 💡 Prioritätsempfehlungen
Datenverzeichnisse werden in drei Prioritätsstufen eingeteilt:

- **Kritisch** (`critical`): Muss nach der Migration funktionieren; beeinflusst die Kernfunktionalität der Anwendung
- **Empfohlen** (`recommended`): Große Speicherersparnis; hoher Migrationsnutzen
- **Optional** (`optional`): Kleine Größe oder wiederherstellbar

Es wird empfohlen, zuerst Verzeichnisse zu migrieren, die als „Empfohlen" markiert sind.
:::

## Wiederherstellungsvorgänge

1. Finden Sie das migrierte Verzeichnis in der Datenverzeichnisliste (Status: „Verknüpft")
2. Klicken Sie rechts auf die Schaltfläche „Wiederherstellen"
3. AppPorts führt die folgenden Schritte aus:
   - Lokalen symbolischen Link löschen
   - Daten vom externen Speicher zurück in den lokalen Speicher kopieren
   - Externes Verzeichnis löschen (best effort)

## Umgang mit abnormalen Zuständen

### Normalisierung erforderlich

Das Verzeichnis wird von AppPorts verwaltet, aber der externe Pfad befindet sich nicht am kanonischen Ort. Klicken Sie auf „Normalisieren"; AppPorts verschiebt die externen Daten zum kanonischen Pfad und erstellt den symbolischen Link neu.

### Neuverlinkung erforderlich

Externe Speicherdaten sind noch vorhanden, aber der lokale symbolische Link ist verloren. Klicken Sie auf „Neuverlinken"; AppPorts erstellt den symbolischen Link neu.

### Vorhandener Soft Link

Ein vom Benutzer erstellter symbolischer Link, der nicht von AppPorts erstellt wurde. Sie können „Übernehmen" wählen; AppPorts schreibt verwaltete Link-Metadaten und verwaltet es fortan.

## Baumansicht

Für Datenverzeichnisse, die Unterverzeichnisse enthalten (z. B. mehrere App-Verzeichnisse unter `Application Support`), bietet AppPorts eine Baumgruppierungsansicht:

- Das übergeordnete Verzeichnis zeigt links Erweitern/Zusammenklappen-Pfeile an
- Unterverzeichnisse werden mit hierarchischer Einrückung angezeigt
- Jeder Knoten zeigt unabhängig Größe und Status an
- Migrations-/Wiederherstellungsvorgänge können an einzelnen Unterverzeichnissen durchgeführt werden
