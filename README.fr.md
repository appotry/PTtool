# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> Outils de liens physiques (hardlink) en Shell/Python pur. Fonctionne sur Linux, BSD, macOS, Synology, QNAP et tout OS disposant d'un shell POSIX standard.
>
> **[中文](README.md)** · **[English](README.en.md)** · **[日本語](README.ja.md)** · **[한국어](README.ko.md)** · **[Español](README.es.md)** · **[Deutsch](README.de.md)** · **[繁體中文](README.zh-TW.md)**

[![opencode](https://img.shields.io/badge/Réfactoré%20avec-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

Ce projet a été entièrement refactoré avec [opencode](https://opencode.ai), implémentant une **boucle de développement-test pilotée par un Agent IA** : besoins → architecture → codage → tests Docker → archivage dans la base de connaissances, le tout réalisé de manière autonome par l'Agent. Voir [`AGENTS.md`](AGENTS.md) et [`docs/`](docs/).

---

## Liste des Scripts

| Script | Objectif |
|--------|----------|
| `mklink.sh` | Lien physique unique : >1Mo hardlink, <1Mo copie |
| `dirlink.sh` | Lien physique idempotent (par sous-répertoire, marqueur `islinked.lk`) |
| `link.sh` | Wrapper batch pour `dirlink.sh` |
| `autolink.sh` | Hook de fin de téléchargement qBittorrent |
| `rename_episodes.py` | Ajustement d'offset SXXEXX |
| `autoThanks.sh` | Remerciement massif NexusPHP (nécessite prudence) |

## Sélection de la Langue

La langue de sortie des scripts est contrôlée par la variable d'environnement `SCRIPT_LANG` (par défaut : suit le `LANG` du système) :

```bash
# Sortie en anglais
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# Sortie en chinois (par défaut)
./dirlink.sh /src /dst
```

## Raison d'Être

Permettre aux utilisateurs PT de créer des liens physiques sur les fichiers, économisant un maximum d'espace tout en maintenant le seeding.
Les fichiers < 1Mo sont copiés directement (permet aux scrapers comme emby/tmm de modifier les fichiers nfo).
Les fichiers > 1Mo sont liés physiquement vers la destination (renomables mais en lecture seule).

**Note :** SRC et DST doivent être sur le même système de fichiers — les liens physiques ne peuvent pas traverser les partitions.

## Exemples d'Utilisation

```bash
# Lien unique
mklink.sh /share/Download/src /share/Download/dst

# Lien idempotent (par sous-répertoire)
dirlink.sh /share/Download/src /share/Download/dst

# Hook de fin qBittorrent
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
make test       # Suite complète (15 tests)
make test-nas   # Tests de compatibilité NAS (8 tests)
```

## Avertissement

Les données sont précieuses, manipulez avec soin. Ces scripts (sauf autolink.sh) utilisent uniquement mkdir et cp — pas de rm. Au pire, vous pourriez encombrer votre système de fichiers. Ne définissez pas le répertoire de destination comme un répertoire système. Utilisation à vos propres risques.
