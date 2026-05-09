---
outline: deep
---

# Externer Speicher - Leitfaden

## Empfohlene Konfiguration

| Konfiguration | Empfohlener Wert | Beschreibung |
|---------------|------------------|--------------|
| Kapazität | 256 GB oder mehr | Abhängig von der Anzahl der migrierten Apps |
| Schnittstelle | USB 3.0 oder höher / Thunderbolt | USB 2.0 ist langsam; Migration großer Apps dauert länger |
| Dateisystem | APFS | Unterstützt Klone, Snapshots, beste Leistung |

## Schnittstellenleistungsvergleich

| Schnittstelle | Theoretische Geschwindigkeit | Tatsächliche Migrationsgeschwindigkeit | Anwendungsfall |
|---------------|-----------------------------|--------------------------------------|----------------|
| USB 2.0 | 480 Mbps | ~30 MB/s | Nicht empfohlen; zu langsam |
| USB 3.0 (USB-A) | 5 Gbps | ~350 MB/s | Grundsätzlich ausreichend |
| USB 3.1 Gen 2 (USB-C) | 10 Gbps | ~700 MB/s | Empfohlen |
| Thunderbolt 3/4 | 40 Gbps | ~2500 MB/s | Beste Leistung |
| NVMe (Thunderbolt) | 40 Gbps | ~2800 MB/s | Beste Leistung |

## Dateisystemempfehlungen

### APFS (Empfohlen)

- Unterstützt Klone, Snapshots, Speicher-Sharing
- Beste Leistung, besonders für SSDs
- Native macOS-Unterstützung

### HFS+

- Gute Kompatibilität; geeignet für ältere Macs
- Unterstützt keine Klone und Snapshots
- Geeignet für mechanische Festplatten

### exFAT

- Plattformübergreifend kompatibel (macOS + Windows)
- Unterstützt keine Hard Links und Klone
- Relativ niedrigere Leistung
- Geeignet für Szenarien, die Nutzung über mehrere Systeme erfordern

## Kapazitätsplanung

Die Nutzung des externen Speichers durch AppPorts nach der Migration hängt von der Größe der migrierten Apps und Datenverzeichnisse ab. Hier sind Referenzgrößen für gängige Apps:

| App-Typ | Größe |
|---------|------|
| Chrome | ~500 MB |
| Microsoft Office | ~5 GB |
| Adobe Creative Cloud | ~20-50 GB |
| Xcode | ~15 GB |
| Final Cut Pro | ~5 GB |
| Lokale Large Language Models (Ollama) | ~4-30 GB |

::: tip 💡 Kapazitätsempfehlungen
- Leichte Nutzung (5-10 Apps): 128 GB
- Mittlere Nutzung (10-20 Apps): 256 GB
- Schwere Nutzung (20+ Apps + Datenverzeichnisse): 512 GB oder mehr
:::

## Hinweise

- Externer Speicher muss verbunden bleiben; migrierte Apps und Datenverzeichnisse können offline nicht genutzt werden
- Sichern Sie regelmäßig Daten auf dem externen Speicher
- Vermeiden Sie das Abstecken des externen Speichers während der Migration
- Fällt der externe Speicher aus, können Sie Apps über AppPorts zurück in den lokalen Speicher verschieben
