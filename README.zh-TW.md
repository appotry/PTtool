# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> 純 Shell / Python 硬連結工具！支援 Linux、BSD、Mac、**群暉**、**威聯通**等支援標準 Shell 的作業系統。
>
> **[English](README.en.md)** · **[日本語](README.ja.md)** · **[한국어](README.ko.md)** · **[Español](README.es.md)** · **[Deutsch](README.de.md)** · **[Français](README.fr.md)** · **[中文](README.md)**

[![opencode](https://img.shields.io/badge/重構-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

本專案採用 [opencode](https://opencode.ai) 全程重構，實現 **AI Agent 驅動的開發-測試閉環**：需求→架構→編碼→Docker 測試→經驗入庫，全部由 Agent 自主完成。詳見 [`AGENTS.md`](AGENTS.md) 和 [`docs/`](docs/)。

---

## 指令碼一覽

| 指令碼 | 用途 |
|--------|------|
| `mklink.sh` | 一次性硬連結：>1MB 硬連結，<1MB 複製 |
| `dirlink.sh` | 幂等硬連結（按子目錄，`islinked.lk` 標記） |
| `link.sh` | 批量呼叫 `dirlink.sh` |
| `autolink.sh` | qBittorrent 下載完成鉤子 |
| `rename_episodes.py` | 調整 SXXEXX 偏移量 |

## 語言切換

指令碼輸出語言由環境變數 `SCRIPT_LANG` 控制，預設跟隨系統 `LANG`：

```bash
# 英文輸出
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# 中文輸出（預設）
./dirlink.sh /src /dst
```

## 設計目的

方便 PT 使用者硬連結檔案，在最大可能情況下節約空間，並保持做種。
小於 1MB 的檔案直接複製，方便 Emby、tmm 等工具刮削修改 nfo 等小檔案。
大於 1MB 的檔案硬連結到目的目錄，可以修改檔名，但不能修改檔案內容！

**注意：** 來源目錄、目的目錄需要在同一個硬碟分區裡面——硬連結不能跨分區。

## 使用範例

```bash
# 一次性連結
mklink.sh /share/Download/src /share/Download/dst

# 幂等連結（按子目錄）
dirlink.sh /share/Download/src /share/Download/dst

# qBittorrent 完成鉤子
/path/to/autolink.sh "%N" "%D" "%L"
```

## 安裝

```bash
git clone https://github.com/appotry/PTtool.git
chmod +x *.sh
```

## 測試

```bash
cd tests
make test       # 完整測試套件（15 項）
make test-nas   # NAS 相容性測試（8 項）
```

## 免責宣告

資料無價，小心操作。本指令碼（除 `autolink.sh` 外）沒有 `rm` 刪除操作，只有 `mkdir` 和 `cp`，最多搞亂檔案系統。但注意不要把目的地目錄設定到系統目錄去了。一切後果自負。
