# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> Herramientas de enlace físico (hardlink) en Shell/Python puro. Funciona en Linux, BSD, macOS, Synology, QNAP y cualquier SO con un shell POSIX estándar.
>
> **[中文](README.md)** · **[English](README.en.md)** · **[日本語](README.ja.md)** · **[한국어](README.ko.md)** · **[Deutsch](README.de.md)** · **[Français](README.fr.md)** · **[繁體中文](README.zh-TW.md)**

[![opencode](https://img.shields.io/badge/Reestructurado%20con-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

Este proyecto fue completamente reestructurado con [opencode](https://opencode.ai), implementando un **ciclo de desarrollo-pruebas impulsado por IA**: requerimientos → arquitectura → codificación → pruebas Docker → archivado en base de conocimiento, todo completado autónomamente por el Agente. Consulte [`AGENTS.md`](AGENTS.md) y [`docs/`](docs/).

---

## Lista de Scripts

| Script | Propósito |
|--------|-----------|
| `mklink.sh` | Enlace físico único: >1MB hardlink, <1MB copia |
| `dirlink.sh` | Enlace físico idempotente (por subdirectorio, marcador `islinked.lk`) |
| `link.sh` | Envoltorio batch para `dirlink.sh` |
| `autolink.sh` | Hook de finalización de qBittorrent |
| `rename_episodes.py` | Ajuste de offset SXXEXX |
| `autoThanks.sh` | Agradecimiento masivo NexusPHP (requiere precaución) |

## Selección de Idioma

El idioma de salida de los scripts se controla mediante la variable de entorno `SCRIPT_LANG` (por defecto sigue el `LANG` del sistema):

```bash
# Salida en inglés
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# Salida en chino (por defecto)
./dirlink.sh /src /dst
```

## Razón de Diseño

Permitir a los usuarios de PT enlazar físicamente archivos, ahorrando espacio máximo mientras mantienen los torrents seedeando.
Archivos < 1MB se copian directamente (permite que scrapers como emby/tmm modifiquen archivos nfo).
Archivos > 1MB se enlazan físicamente al destino (renombrables pero de solo lectura).

**Nota:** SRC y DST deben estar en el mismo sistema de archivos — los enlaces físicos no pueden cruzar particiones.

## Ejemplos de Uso

```bash
# Enlace único
mklink.sh /share/Download/src /share/Download/dst

# Enlace idempotente (por subdirectorio)
dirlink.sh /share/Download/src /share/Download/dst

# Hook de finalización de qBittorrent
/path/to/autolink.sh "%N" "%D" "%L"
```

## Instalación

```bash
git clone https://github.com/appotry/PTtool.git
chmod +x *.sh
```

## Pruebas

```bash
cd tests
make test       # Suite completa (15 pruebas)
make test-nas   # Pruebas de compatibilidad NAS (8 pruebas)
```

## Aviso Legal

Los datos son valiosos, opere con cuidado. Estos scripts (excepto autolink.sh) solo usan mkdir y cp — no usan rm. En el peor caso, puede desordenar su sistema de archivos. No configure el directorio de destino como un directorio del sistema. Úselo bajo su propio riesgo.
