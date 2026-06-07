# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> 純 Shell / Python ハードリンクツール。Linux、BSD、macOS、Synology、QNAP など、標準 POSIX シェル対応の OS で動作します。
>
> **[中文](README.md)** · **[English](README.en.md)**

[![opencode](https://img.shields.io/badge/リファクタリング-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

このプロジェクトは [opencode](https://opencode.ai) で完全にリファクタリングされ、**AI Agent 駆動の開発・テストサイクル**（要件→設計→コーディング→Docker テスト→ナレッジベース管理）を実現しています。詳細は [`AGENTS.md`](AGENTS.md) と [`docs/`](docs/) を参照してください。

---

## スクリプト一覧

| スクリプト | 用途 |
|-----------|------|
| `mklink.sh` | 一括ハードリンク：>1MB はハードリンク、<1MB はコピー |
| `dirlink.sh` | 冪等ハードリンク（サブディレクトリ単位、`islinked.lk` マーカー） |
| `link.sh` | `dirlink.sh` のバッチラッパー |
| `autolink.sh` | qBittorrent ダウンロード完了フック |
| `rename_episodes.py` | SXXEXX オフセット調整 |

## 言語切り替え

スクリプトの出力言語は環境変数 `SCRIPT_LANG` で制御します（デフォルトはシステムの `LANG` に従う）：

```bash
# 英語出力
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# 中国語出力（デフォルト）
./dirlink.sh /src /dst
```

## 動作の仕組み

PT ユーザーがファイルをハードリンクし、スペースを節約しながらシードを維持するためのツールです。
1MB 未満のファイルは直接コピー（Emby/tmm などが nfo ファイルを書き換えられるようにするため）。
1MB 以上のファイルはハードリンク（リネーム可能だが内容は読み取り専用）。

**注意：** SRC と DST は同じファイルシステム上にある必要があります（ハードリンクはパーティションを越えられません）。

## 使用例

```bash
# 一括リンク
mklink.sh /share/Download/src /share/Download/dst

# 冪等リンク（サブディレクトリ単位）
dirlink.sh /share/Download/src /share/Download/dst

# qBittorrent 完了フック（設定 → ダウンロード → 外部プログラム）
/path/to/autolink.sh "%N" "%D" "%L"
```

## インストール

```bash
git clone https://github.com/appotry/PTtool.git
chmod +x *.sh
```

## テスト

```bash
cd tests
make test       # フルテストスイート（15 項目）
make test-nas   # NAS 互換性テスト（8 項目）
```

## 免責事項

データは貴重です。慎重に操作してください。これらのスクリプト（autolink.sh を除く）は mkdir と cp のみを使用し、rm は使用しません。最悪の場合、ファイルシステムを乱雑にする可能性があります。システムディレクトリを宛先に設定しないでください。自己責任で使用してください。
