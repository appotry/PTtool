# PTtool 测试规范

## 测试策略

| 层次 | 方法 | 触发 | 环境 |
|------|------|------|------|
| 语法检查 | `dash -n` / `sh -n` | 每次修改 | 本地 |
| 单元测试 | 独立功能验证 | 每次修改 | Docker |
| 平台兼容 | 多 shell 环境验证 | 版本发布 | Docker |
| NAS 仿真 | Busybox ash 模拟 | 版本发布 | Docker |
| 集成测试 | qBittorrent 钩子模拟 | 版本发布 | Docker |

## 测试环境

### Docker 镜像体系

```
alpine:3.21  (基础镜像，使用 Busybox ash)
  ├── pttool-test     (完整测试：含 dash + coreutils)
  │   └── tests/test_suite.sh
  └── pttool-nas      (NAS 仿真：裸 Busybox，无额外工具)
      └── tests/verify_nas.sh
```

### 构建方法

```bash
# 完整测试环境（含 dash 严格 POSIX 验证）
docker build -t pttool-test -f- . <<'DOCKERFILE'
FROM alpine:3.21
RUN apk add --no-cache dash coreutils
COPY tests/test_suite.sh /test_suite.sh
RUN chmod +x /test_suite.sh
ENTRYPOINT ["/bin/sh", "/test_suite.sh"]
DOCKERFILE

# NAS 仿真测试（纯 Busybox ash，无额外工具）
docker build -t pttool-nas -f- . <<'DOCKERFILE'
FROM alpine:3.21
COPY tests/verify_nas.sh /verify_nas.sh
RUN chmod +x /verify_nas.sh
ENTRYPOINT ["/bin/sh", "/verify_nas.sh"]
DOCKERFILE
```

### 运行方法

```bash
# 完整测试套件
docker run --rm -v "$PWD:/pttool:ro" pttool-test

# NAS 兼容性验证
docker run --rm -v "$PWD:/pttool:ro" pttool-nas

# 单容器快速验证（无需构建镜像）
docker run --rm -v "$PWD:/pttool:ro" alpine:3.21 sh -c '
  for f in /pttool/*.sh; do
    sh -n "$f" && echo "  ✓ $f" || echo "  ✗ $f"
  done
'

# 多 shell 对比验证
for img in alpine:3.21 debian:bookworm-slim; do
  echo "=== $img ==="
  docker run --rm -v "$PWD:/pttool:ro" "$img" sh -c '
    for f in /pttool/*.sh; do
      /bin/sh -n "$f" || echo "SYNTAX: $f"
    done
  '
done
```

## 测试用例

### 1. Shell 语法（TC-SYNTAX）

| 项目 | 内容 |
|------|------|
| 目标 | 验证所有 `.sh` 文件符合 POSIX sh 语法 |
| 工具 | `dash -n`（最严格 POSIX）、`sh -n` |
| 命令 | `for f in *.sh; do dash -n "$f" || exit 1; done` |
| 通过标准 | 所有脚本零错误 |
| 失败处理 | 定位具体脚本和行号，修复语法错误 |

### 2. 大小阈值（TC-FILEGIG）

| 项目 | 内容 |
|------|------|
| 目标 | `< FILEGIG` 复制，`> FILEGIG` 硬链接 |
| 前置 | 1KB 和 2MB 测试文件各一 |
| 验证 | `stat -c %i` 比较 inode：小文件不同（复制），大文件相同（硬链接）|
| 通过标准 | inode 关系符合预期 |

### 3. 幂等性（TC-IDEMPOTENT）

| 项目 | 内容 |
|------|------|
| 目标 | `dirlink.sh` 二次运行不重复操作 |
| 方法 | 创建带子目录的源，运行两次，检查 `islinked.lk` |
| 验证 | 第一次创建标记，第二次跳过处理 |
| 边界 | 下载中断时误创建的 `islinked.lk` 被 `autolink.sh` 自动删除 |

### 4. 路径含空格（TC-SPACES）

| 项目 | 内容 |
|------|------|
| 目标 | `My Movie 2024` 这类带空格的目录名正确处理 |
| 关键 | `IFS` 设置为 `\n\b` 避免空格分词 |
| 验证 | 目标目录中文件存在且链接正确 |

### 5. 国际化（TC-I18N）

| 项目 | 内容 |
|------|------|
| 目标 | `SCRIPT_LANG=en_US` 切换输出语言 |
| 验证 | 默认输出含中文，`SCRIPT_LANG=en_US` 输出为英文 |
| 覆盖 | 全部 5 个脚本（4 shell + 1 python） |

### 6. NAS 仿真（TC-NAS）

| 项目 | 内容 |
|------|------|
| 目标 | 在纯 Busybox ash 环境下工作 |
| 验证 | `/share/` 路径兼容、无 `readlink -f` 依赖、无 `exit -1` |
| 工具 | `tests/verify_nas.sh` |

### 7. qBittorrent 钩子（TC-AUTOLINK）

| 项目 | 内容 |
|------|------|
| 目标 | autolink.sh 正确解析 `%N %D %L` 参数 |
| 场景 | 多文件种子（`-d dir`）、单文件种子（`-f file`） |
| 排除 | `EXCLUDE_CATEGORIES` 变量控制跳过 |

### 8. autoThanks.sh curl 参数（TC-AUTOTHANKS）

| 项目 | 内容 |
|------|------|
| 目标 | curl `-d` 参数正确展开变量 |
| 历史 | 原版 `-d '"id":"$i"'` 单引号阻止变量展开 |
| 验证 | grep 确认不存在单引号包裹的 `$i` |

### 9. Python 重命名（TC-RENAME）

| 项目 | 内容 |
|------|------|
| 目标 | `rename_episodes.py` 正确计算 SXXEXX 偏移 |
| 方法 | 创建 `S01E01.mkv` + `S01E05.mkv` 调用 `offset 1 3` |
| 验证 | 输出 `S02E04.mkv` + `S02E08.mkv` |

### 10. 跨文件系统（TC-CROSSFS）

| 项目 | 内容 |
|------|------|
| 目标 | SRC/DST 在不同分区时应报错退出 |
| 前置 | 模拟跨分区场景（/proc 作为不同文件系统目标） |
| 验证 | 脚本退出码非零，输出包含错误提示 |

### 11. 特殊字符文件名（TC-SPECIALCHARS）

| 项目 | 内容 |
|------|------|
| 目标 | 含空格、中文、`!@#$%^&()` 的文件名正确处理 |
| 前置 | 创建含特殊字符的目录和文件 |
| 验证 | 所有文件在 DST 中存在且 inode 匹配预期 |

### 12. 排除分类（TC-EXCLUDE）

| 项目 | 内容 |
|------|------|
| 目标 | autolink.sh `EXCLUDE_CATEGORIES` 正确跳过指定分类 |
| 验证 | 排除分类被跳过，正常分类被处理 |

### 13. 并发运行（TC-CONCURRENT）

| 项目 | 内容 |
|------|------|
| 目标 | 两个 dirlink.sh 实例同时运行不冲突 |
| 方法 | 同时启动两个进程指向同一 SRC、不同 DST |
| 通过标准 | 至少一个 DST 包含正确的输出文件 |

### 14. FILEGIG 边界值（TC-FILEGIG-EDGE）

| 项目 | 内容 |
|------|------|
| 目标 | 0 字节、正好 1MB 等边界值正确处理 |
| 验证 | 0 字节文件被复制（非硬链接），1MB 边界文件行为符合 find 语义 |

### 15. 批量性能（TC-STRESS）

| 项目 | 内容 |
|------|------|
| 目标 | 100 文件 × 10 子目录（共 1000 文件）在合理时间内完成 |
| 验证 | 全部 100 个文件被链接，输出耗时 |
| 参考 | 100GB 量级应 ≤ 5 分钟 |

## 测试标准

### PASS 条件

- 功能测试：实际行为与规格完全一致
- 语法检查：`dash -n` 零错误
- 幂等测试：两次运行结果完全一致

### FAIL 处理

- 任何 FAIL 必须修复后才能合入
- 语法错误：最优先级
- 功能错误：修复后补充对应测试用例

### 测试维护

- 新增脚本必须在 `tests/` 中添加对应测试
- 测试以 `TC-XXXX` 命名，与文档一一对应
- Docker 测试脚本保持自包含，不依赖宿主机环境
