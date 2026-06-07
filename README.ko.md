# PTtool

> GitHub: [appotry/PTtool](https://github.com/appotry/PTtool)
>
> 순수 Shell/Python 하드링크 도구. Linux, BSD, macOS, Synology, QNAP 등 표준 POSIX 셸을 지원하는 모든 OS에서 작동합니다.
>
> **[中文](README.md)** · **[English](README.en.md)** · **[日本語](README.ja.md)** · **[Español](README.es.md)** · **[Deutsch](README.de.md)** · **[Français](README.fr.md)** · **[繁體中文](README.zh-TW.md)**

[![opencode](https://img.shields.io/badge/리팩토링-opencode-6A0DAD)](https://opencode.ai)
[![CI](https://github.com/appotry/PTtool/actions/workflows/test.yml/badge.svg)](https://github.com/appotry/PTtool/actions/workflows/test.yml)

---

이 프로젝트는 [opencode](https://opencode.ai)로 완전히 리팩토링되어 **AI Agent 기반 개발-테스트 루프**를 구현했습니다: 요구사항 → 아키텍처 → 코딩 → Docker 테스트 → 지식베이스 기록까지 모두 Agent가 자율적으로 수행합니다. 자세한 내용은 [`AGENTS.md`](AGENTS.md)와 [`docs/`](docs/)를 참조하세요.

---

## 스크립트 목록

| 스크립트 | 설명 |
|----------|------|
| `mklink.sh` | 1회성 하드링크: >1MB는 하드링크, <1MB는 복사 |
| `dirlink.sh` | 멱등성 하드링크 (서브디렉토리 단위, `islinked.lk` 마커) |
| `link.sh` | `dirlink.sh` 배치 래퍼 |
| `autolink.sh` | qBittorrent 다운로드 완료 후크 |
| `rename_episodes.py` | SXXEXX 오프셋 조정 |
| `autoThanks.sh` | NexusPHP 대량 감사 (주의 필요) |

## 언어 설정

스크립트 출력 언어는 `SCRIPT_LANG` 환경변수로 제어됩니다 (기본값: 시스템 `LANG`):

```bash
# 영어 출력
SCRIPT_LANG=en_US ./dirlink.sh /src /dst

# 중국어 출력 (기본값)
./dirlink.sh /src /dst
```

## 설계 목적

PT 사용자가 파일을 하드링크하여 공간을 절약하고 시드를 유지할 수 있도록 합니다.
1MB 미만 파일은 직접 복사 (Emby/tmm 등의 스크레이퍼가 nfo 파일을 수정할 수 있도록).
1MB 이상 파일은 하드링크 (이름 변경 가능하지만 내용은 읽기 전용).

**주의:** SRC와 DST는 동일한 파일시스템에 있어야 합니다 (하드링크는 파티션을 넘을 수 없음).

## 사용 예시

```bash
# 1회성 링크
mklink.sh /share/Download/src /share/Download/dst

# 멱등성 링크 (서브디렉토리 단위)
dirlink.sh /share/Download/src /share/Download/dst

# qBittorrent 완료 후크
/path/to/autolink.sh "%N" "%D" "%L"
```

## 설치

```bash
git clone https://github.com/appotry/PTtool.git
chmod +x *.sh
```

## 테스트

```bash
cd tests
make test       # 전체 테스트 스위트 (15개 항목)
make test-nas   # NAS 호환성 테스트 (8개 항목)
```

## 면책 조항

데이터는 소중합니다. 주의해서操作하세요. 이 스크립트들(autolink.sh 제외)은 mkdir과 cp만 사용하며 rm은 사용하지 않습니다. 최악의 경우 파일시스템을 어지럽힐 수 있습니다. 대상 디렉토리를 시스템 디렉토리로 설정하지 마세요. 사용에 따른 책임은 본인에게 있습니다.
