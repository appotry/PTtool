# PTtool 架构概览

## 项目定位

纯 Shell（POSIX sh）/ Python 硬链接管理工具集合。零外部依赖，专为 NAS（群辉、威联通）和 Linux 环境设计，作为 qBittorrent 下载完成钩子工作。

## 组件关系图

```
qBittorrent                    Emby / Jellyfin / tmm
    │                                  │
    │ "%N" "%D" "%L"                   │
    ▼                                  ▼
autolink.sh ───→ dirlink.sh ───→ /share/Download/dst/
                          │                │
                          ├── islinked.lk (标记)
                          │
mklink.sh ←── 一次性的批量硬链接（无标记）
                          │
                    ┌─────┴──────┐
                    ▼            ▼
               >1MB 硬链接    <1MB 复制
               (cp -l)        (cp)
```

## 数据流（以 autolink.sh 触发为例）

```
触发           %N=torrent_name %D=save_path %L=category
  │
  ▼
autolink.sh   排除检查 → 构造 link_path = your_path/category
  │
  ├── 多文件种子  → dirlink.sh <torrent_path> <link_path>
  └── 单文件种子  → dirlink.sh <torrent_path/..> <link_path>
                    │
                    ▼
dirlink.sh     遍历 SRC 子目录
  │
  ├── 发现 islinked.lk → 跳过（幂等）
  └── 无标记 → mklink() 处理
                  │
             Files > FILEGIG → cp -l（硬链接）
             Files < FILEGIG → cp（复制）
                  │
              touch islinked.lk
```

## 设计决策

| 决策 | 方案 | 理由 |
|------|------|------|
| Shell 选择 | `#!/bin/sh`（POSIX） | NAS 环境无 bash，Busybox ash/dash 保证最大兼容 |
| 路径推导 | `cd $(dirname $0) && pwd` | 替代 `readlink -f`，兼容 BSD/macOS |
| 幂等机制 | `islinked.lk` 标记文件 | 简单可靠，无需数据库，删除标记即可重链 |
| 大小阈值 | `FILEGIG` 变量，默认 1MB | 小文件复制给刮削器修改，大文件硬链接省空间 |
| 分类适配 | 默认全部链接，可选排除 | 开箱即用，无需每次新增分类都改脚本 |
| i18n | `SCRIPT_LANG` 环境变量 | 轻量，无外部依赖，随 LANG 自动切换 |
| 状态跟踪 | 无日志文件 | 纯函数式设计，每次运行独立，出错可重跑 |

## 平台兼容性

| 特性 | Linux (bash/dash) | Busybox (ash) | BSD/macOS | Synology/QNAP |
|------|---|---|---|---|
| `cp -l`（硬链接） | ✓ | ✓ | ✓ | ✓ |
| `find -size` | ✓ | ✓ | ✓ | ✓ |
| `readlink -f` | ✓ | ✗ | ✗ | ✗ |
| `dirname` / `pwd` | ✓ | ✓ | ✓ | ✓ |
| `sed` 替换 | ✓ | ✓ | ✓ | ✓ |
| `exit -1` | ✗ (bash 兼容) | ✗ | ✗ | ✗ |
| `[[ ]]` | ✓ (bash only) | ✗ | ✗ | ✗ |
| `function` 关键字 | ✓ (bash only) | ✗ | ✗ | ✗ |

> PTtool 使用 **交集语法**：只使用所有平台都支持的 POSIX sh 子集。

## 安全约束

- SRC 和 DST 必须在同一文件系统（硬链接不能跨分区）
- 脚本只执行 `mkdir` 和 `cp`，不执行 `rm`（autolink.sh 仅删除误创建的 `islinked.lk`）
- `autoThanks.sh` 需要 `curl`，16 秒/POST 延迟防封

## 错误流

| 场景 | 检测方式 | 行为 | 退出码 |
|------|---------|------|--------|
| SRC 不存在 | `[ ! -d "$SRC" ]` | 打印错误并退出 | 2 |
| DST 不存在 | `[ ! -d "$DST" ]` | 自动 mkdir -p 创建 | 0 |
| 参数不足 | `[ $# -lt 2 ]` | 打印用法并退出 | 1 |
| 跨文件系统 | `stat -c %d` 比较设备号 | 打印错误并退出 | 2 |
| cp -l 失败 | 命令返回非零 | 打印错误继续执行 | 0 |
