---
outline: deep
---

# External Storage Guide

## Recommended Configuration

| Configuration | Recommended Value | Description |
|---------------|-------------------|-------------|
| Capacity | 256 GB or above | Depends on number of migrated apps |
| Interface | USB 3.0 or above / Thunderbolt | USB 2.0 is slow; large app migration takes longer |
| File System | APFS | Supports clones, snapshots, best performance |

## Interface Performance Comparison

| Interface | Theoretical Speed | Actual Migration Speed | Use Case |
|-----------|-------------------|----------------------|----------|
| USB 2.0 | 480 Mbps | ~30 MB/s | Not recommended; too slow |
| USB 3.0 (USB-A) | 5 Gbps | ~350 MB/s | Basically sufficient |
| USB 3.1 Gen 2 (USB-C) | 10 Gbps | ~700 MB/s | Recommended |
| Thunderbolt 3/4 | 40 Gbps | ~2500 MB/s | Best performance |
| NVMe (Thunderbolt) | 40 Gbps | ~2800 MB/s | Best performance |

## File System Recommendations

### APFS (Recommended)

- Supports clones, snapshots, space sharing
- Best performance, especially for SSDs
- Native macOS support

### HFS+

- Good compatibility; suitable for older Macs
- Does not support clones and snapshots
- Suitable for mechanical hard drives

### exFAT

- Cross-platform compatible (macOS + Windows)
- Does not support hard links and clones
- Relatively lower performance
- Suitable for scenarios requiring use across multiple systems

## Capacity Planning

AppPorts' external storage usage after migration depends on the size of migrated apps and data directories. Below are reference sizes for common apps:

| App Type | Size |
|----------|------|
| Chrome | ~500 MB |
| Microsoft Office | ~5 GB |
| Adobe Creative Cloud | ~20-50 GB |
| Xcode | ~15 GB |
| Final Cut Pro | ~5 GB |
| Local large language models (Ollama) | ~4-30 GB |

::: tip 💡 Capacity Recommendations
- Light use (5-10 apps): 128 GB
- Medium use (10-20 apps): 256 GB
- Heavy use (20+ apps + data directories): 512 GB or above
:::

## Notes

- External storage must remain connected; migrated apps and data directories cannot be used offline
- Regularly back up data on external storage
- Avoid unplugging external storage during migration
- If external storage fails, you can move apps back to local via AppPorts
