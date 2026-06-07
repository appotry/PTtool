# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> Reine Shell/Python Hardlink-Tools. Läuft auf Linux, BSD, macOS, Synology, QNAP und jedem OS mit einer standardkonformen POSIX-Shell.
>
> **[中文](README.md)** · **[English](README.en.md)** · **[日本語](README.ja.md)** · **[한국어](README.ko.md)** · **[Español](README.es.md)** · **[Français](README.fr.md)** · **[繁體中文](README.zh-TW.md)**

[![opencode](https://img.shields.io/badge/Refaktorisiert%20mit-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

Dieses Projekt wurde vollständig mit [opencode](https://opencode.ai) refaktorisiert und implementiert eine **KI-Agent-gesteuerte Entwicklungs-Test-Schleife**: Anforderungen → Architektur → Codierung → Docker-Tests → Wissensdatenbank-Archivierung, alles autonom vom Agenten erledigt. Siehe [`AGENTS.md`](AGENTS.md) und [`docs/`](docs/).

---

## Skriptübersicht

| Skript | Zweck |
|--------|-------|
| `mklink.sh` | Einmaliger Hardlink: >1MB verlinken, <1MB kopieren |
| `dirlink.sh` | Idempotenter Hardlink (pro Unterverzeichnis, `islinked.lk`-Marker) |
| `link.sh` | Batch-Wrapper für `dirlink.sh` |
| `autolink.sh` | qBittorrent-Abschluss-Hook |
| `rename_episodes.py` | SXXEXX-Offset-Anpassung |
| `autoThanks.sh` | NexusPHP-Massen-Danke (Vorsicht geboten) |

## Sprachauswahl

Die Ausgabesprache der Skripte wird über die Umgebungsvariable `SCRIPT_LANG` gesteuert (Standard: System-`LANG`):

```bash
# Englische Ausgabe
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# Chinesische Ausgabe (Standard)
./dirlink.sh /src /dst
```

## Design

PT-Benutzern ermöglichen, Dateien hart zu verlinken, um maximal Speicherplatz zu sparen und gleichzeitig das Seeden zu erhalten.
Dateien < 1MB werden direkt kopiert (ermöglicht Scrapern wie emby/tmm, nfo-Dateien zu ändern).
Dateien > 1MB werden zum Ziel hart verlinkt (umbenennbar, aber schreibgeschützt).

**Hinweis:** SRC und DST müssen sich im selben Dateisystem befinden — Hardlinks können Partitionen nicht überqueren.

## Verwendungsbeispiele

```bash
# Einmaliger Link
mklink.sh /share/Download/src /share/Download/dst

# Idempotenter Link (pro Unterverzeichnis)
dirlink.sh /share/Download/src /share/Download/dst

# qBittorrent-Abschluss-Hook
/path/to/autolink.sh "%N" "%D" "%L"
```

## Installation

```bash
git clone https://github.com/appotry/PTtool.git
chmod +x *.sh
```

## Tests

```bash
cd tests
make test       # Vollständige Testsuite (15 Tests)
make test-nas   # NAS-Kompatibilitätstests (8 Tests)
```

## Haftungsausschluss

Daten sind wertvoll, gehen Sie vorsichtig vor. Diese Skripte (außer autolink.sh) verwenden nur mkdir und cp — kein rm. Im schlimmsten Fall können Sie Ihr Dateisystem überladen. Setzen Sie das Zielverzeichnis nicht auf ein Systemverzeichnis. Nutzung auf eigene Gefahr.
