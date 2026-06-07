# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> Pure Shell / Python hardlink tools. Works on Linux, BSD, macOS, Synology, QNAP and any OS with a standard POSIX shell.
>
> **[中文](README.md)** · **[日本語](README.ja.md)** · **[한국어](README.ko.md)** · **[Español](README.es.md)** · **[Deutsch](README.de.md)** · **[Français](README.fr.md)** · **[繁體中文](README.zh-TW.md)**
>
> [![opencode](https://img.shields.io/badge/Refactored%20with-opencode-6A0DAD)](https://opencode.ai)
> [![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

This project was fully refactored with [opencode](https://opencode.ai), implementing an **AI Agent-driven dev-test loop**: requirements → architecture → coding → Docker testing → knowledge base archiving, all completed autonomously by the Agent. See [`AGENTS.md`](AGENTS.md) and [`docs/`](docs/).

---

## Table of Contents

- [Language Selection](#language-selection)
- [Design Rationale](#design-rationale)
- [Problems Solved](#problems-solved)
- [Usage Guide](#usage-guide)
- [mklink.sh](#mklinksh)
- [dirlink.sh](#dirlinksh)
- [Adjusting the Size Threshold](#adjusting-the-size-threshold)
- [autolink.sh](#autolinksh)
- [Caveats](#caveats)
- [Disclaimer](#disclaimer)
- [Contributing](#contributing)

---

## Language Selection

Script output language is controlled by the `SCRIPT_LANG` environment variable (defaults to system `LANG`):

```bash
# English output
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# Chinese output (default)
./dirlink.sh /src /dst
```

`rename_episodes.py` also supports `SCRIPT_LANG`.

## Design Rationale

Allow PT users to hardlink files, saving maximum space while keeping torrents seeding.
Files < 1MB are copied directly (lets scrapers like emby/tmm modify nfo files).
Files > 1MB are hardlinked to the destination (renameable but read-only).

Example:

```
/share/Download/src    — PT download directory
/share/Download/dst    — Scraper directory (point emby/tmm here)
```

After downloading, run `chmod +x mklink.sh`. Set SRC and DST in the script or pass as arguments, then run.

```bash
SRC="/share/Download/src"
DST="/share/Download/dst"
```

**Note:**

> SRC and DST must be on the same filesystem — hardlinks cannot cross partitions.
>
> Use `mv` on hardlinked files, not `cp` — `cp` duplicates storage.

## Problems Solved

When tmm/emby scrape metadata, they modify nfo files and download different cover images per source. Small files are copied so modifications don't affect the originals. Large files are hardlinked to save space — multiple paths point to the same underlying data, which is only freed when ALL hardlinks are deleted.

## Usage Guide

Use `/share/Download` as the download root. qBittorrent saves categorized torrents to subdirectories under `/share/Download/src/` (tv, anime, movie, 4k, etc.).
Create `/share/Download/dst/` and use src and dst as script inputs.

Small files are copied (allows tmm to modify nfo). Large files are hardlinked (one copy of data, two file entries — renameable and movable). Seeding and emby work simultaneously.

### Recommended Layout

```
/share/Download/src       # Default BT download directory
/share/Download/dst       # Hardlink destination for Emby/tmm
```

Create subdirectories under src (movie, music, anime, tv, 4k), configure them as qBittorrent categories. After download, run the hardlink scripts. Point emby/tmm to dst for scraping.

#### qBittorrent Configuration

- **Move torrent save location**: Right-click a torrent in the qBittorrent web UI → Save location
- **Set category directories**: Right-click → Category → New category → set name and path. For multi-file torrents, enable automatic management. For single-file torrents, add subdirectories manually.

## mklink.sh

One-shot hardlink from source to destination. Files < 1MB are copied (allows scraper modifications). Files > 1MB are hardlinked (saves space, two file entries share one data copy).

No idempotency check. **Best for fresh, unlinked directories.**

```bash
# mklink.sh sourcedir dstdir
mklink.sh /share/Download/tmp/src /share/Download/tmp/dst
```

## dirlink.sh

Idempotent hardlink per subdirectory, tracked via `islinked.lk` marker files.
If a marker exists, the subdirectory is skipped. If not, files are hardlinked and the marker is created.

Set SRC and DST in the script or pass as command-line arguments (`$1`, `$2`).

```bash
SRC="/share/Download/tmp/src/movie"
DST="/share/Download/tmp/dst/movie"
```

**Note:** Source content must be organized in subdirectories (e.g., `src/anime/anime1`, `src/tv/tv2`) for `islinked.lk` to work correctly.

```bash
# dirlink.sh sourcedir dstdir
dirlink.sh /share/Download/tmp/src /share/Download/tmp/dst
```

### Re-link: Delete all islinked.lk files

```bash
find /share/Download/tmp -name "islinked.lk" | xargs rm -f
```

Replace the path with your own. **Be extremely careful — mistakes with rm are costly!**

### Batch link multiple directories

Example in `link.sh`:

```bash
#!/bin/sh
/path/to/dirlink.sh /share/Download/src/anime /share/Download/dst/anime
/path/to/dirlink.sh /share/Download/src/movie /share/Download/dst/movie
/path/to/dirlink.sh /share/Download/src/tv   /share/Download/dst/tv
```

## Adjusting the Size Threshold

Set `FILEGIG` in the script (default `1000000c` = 1 MB). In `find`'s `-size` option: `c` = bytes, `k` = kilobytes, `M` = megabytes, `G` = gigabytes.

Size conversions: 1 KB = 1024 bytes, 1 MB = 1024 KB, 1 GB = 1024 MB.

```bash
FILEGIG=2000000c   # 2 MB
FILEGIG=10M        # 10 MB
FILEGIG=100M       # 100 MB
```

## autolink.sh

qBittorrent completion hook. Auto-hardlinks newly completed torrents by category. For existing torrents, use `link.sh` instead.

- **Set target directory**: Edit `your_path` in the script.
- **Configure qBittorrent**: Tools → Options → Downloads → "Run external program on torrent completion"

```
/path/to/autolink.sh "%N" "%D" "%L"
```

> `autolink.sh` and `dirlink.sh` must be in the same directory.

**All categories are linked automatically** — no need to edit category lists in the script. To exclude specific categories, set `EXCLUDE_CATEGORIES` in the script.

## Caveats

- Check file permissions if errors occur. The target directory must be writable!

## Disclaimer

Data is precious, operate with care. These scripts (except autolink.sh) only use mkdir and cp — no rm. At worst you may clutter your filesystem. Do not set the destination to a system directory. Use at your own risk.

## Contributing

1. Fork it (https://github.com/appotry/PTtool/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
