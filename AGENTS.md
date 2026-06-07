# PTtool

PT 硬链接管理脚本集合。纯 Shell/Python，零外部依赖。

项目类型：**B 类（脚本工具型）** — 见 `docs/` 工程文档体系。

## 工程文档体系

| 文档 | 用途 | 按类型设计依据 |
|------|------|----------------|
| `docs/REQUIREMENTS.md` | 需求、用例、非功能指标 | B 类脚本工具必选 |
| `docs/ARCHITECTURE.md` | 组件关系、数据流、设计决策、平台兼容表 | B 类必选 |
| `docs/TESTING.md` | 测试策略、用例规范、TC 编号、测试标准 | 所有项目必选 |
| `tests/test_suite.sh` | 主测试套件（Docker） | TC 编号对应的自动化验证 |
| `tests/verify_nas.sh` | NAS 仿真测试（Docker） | 平台兼容性专项验证 |
| `tests/README.md` | 测试快速开始 | 测试入口文档 |

## 命令

| 脚本 | 用途 |
|------|------|
| `mklink.sh <src> <dst>` | 一次性硬链接：>1MB 硬链接，<1MB 复制 |
| `dirlink.sh <src> <dst>` | 幂等硬链接（按子目录，`islinked.lk` 标记） |
| `link.sh` | 批量调用 `dirlink.sh`（编辑路径后直接运行） |
| `autolink.sh "%N" "%D" "%L"` | qBittorrent 下载完成钩子 |
| `python3 rename_episodes.py <dir> <season_off> <episode_off>` | 调整 SXXEXX 偏移量 |

## 项目结构

```
mklink.sh              # 一次性硬链接（无幂等检查）
dirlink.sh             # 幂等硬链接
autolink.sh            # qBittorrent 完成钩子
link.sh                # 批量包装脚本
autoThanks.sh          # NexusPHP 批量感谢（危险）
rename_episodes.py     # SXXEXX 重命名
renovate.json          # 依赖更新（config:recommended）
README.md              # 中文文档（默认）
README.en.md           # 英文文档
docs/
  REQUIREMENTS.md      # 需求文档
  ARCHITECTURE.md      # 架构文档
  TESTING.md           # 测试规范文档
tests/
  test_suite.sh        # 主测试套件（Docker）
  verify_nas.sh        # NAS 仿真测试（Docker）
  README.md            # 测试快速开始
```

## 关键细节

- **SRC 和 DST 必须在同一文件系统**（硬链接不能跨分区）
- `dirlink.sh` 用 `islinked.lk` 标记进度。重链：`find <path> -name "islinked.lk" | xargs rm -f`
- `FILEGIG` 控制大小阈值，默认 `1000000c`（1 MB），可改为 `10M`、`100M` 等
- `autolink.sh` 将 `dirlink.sh` 作为同目录兄弟执行，下载中误创建的 `islinked.lk` 会被自动删除
- `autoThanks.sh` 需要 `curl`，16s/POST 延迟防封。**误用可能导致 PT 账号被封**
- 所有脚本使用严格 POSIX sh（`#!/bin/sh`），不依赖 bash 特性。`rename_episodes.py` 需要 Python 3
- i18n 通过环境变量 `SCRIPT_LANG` 控制，默认跟随系统 `LANG`。设为 `en_US` 即可输出英文
- 中文文档、中英双语 README，群辉/威联通等 NAS 环境通用
- `autolink.sh` 中 `readlink -f` 替换为便携的 `cd "$(dirname "$0")" && pwd`，兼容 BSD/macOS

## 经验知识库

共享路径：`~/Work/dev-experience/`
本项目标签：`cli`, `shell`, `testing`, `documentation`, `architecture`, `docker`, `git-workflow`, `i18n`

### 同步策略

- 每次 session 开始时自动同步经验库
- 完成任务后检查是否有新经验需要应用
- 同步后输出变更摘要

### 引用经验

| 引用 | 路径 | 用途 |
|------|------|------|
| 项目类型文档体系 | `04-documentation/05-project-type-doc-architecture.md` | 本项目 B 类文档体系设计 |
| Docker 测试架构 | `08-testing/03-docker-test-architecture.md` | tests/ 目录结构、两级测试策略 |
| 经验同步机制 | `00-ai-agent/08-experience-sync-workflow.md` | AGENTS.md 同步节设计 |
| 文档初始化工作流 | `04-documentation/03-doc-bootstrap-workflow.md` | docs/ 创建顺序 |
| 平台差异处理 | `99-general/03-platform-diff.md` | `readlink -f` 替代、`exit -1` 修复 |
| 静默失败预防 | `99-general/01-silent-failure.md` | 脚本返回值检查、curl -d 展开 |
| 项目类型标签 | `00-ai-agent/03-project-type-tagging.md` | 标签体系设计 |
| 批判性经验消费 | `00-ai-agent/05-critical-experience-consumption.md` | 经验适用性评估 |
| Shell 编码规范 | `99-general/05-shell-coding-standards.md` | 本项目的 POSIX sh 遵循规范 |
| Python 编码规范 | `99-general/06-python-coding-standards.md` | rename_episodes.py 遵循规范 |
| 敏感数据隔离 | `00-ai-agent/11-sensitive-data-redaction.md` | AGENTS.md 本身不包含敏感信息 |
