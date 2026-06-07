# PTtool 测试

## 快速开始（推荐）

```bash
# 完整测试（自动按需构建，0 网络依赖）
make test

# NAS 仿真测试
make test-nas

# 查看本地镜像缓存
make list

# 强制重建镜像
make rebuild

# 删除本地测试镜像
make clean
```

## Docker 命令（备选）

```bash
# 完整测试
docker build -t pttool-test -f docker/test_suite.Dockerfile ..
docker run --rm -v "$PWD:/pttool:ro" pttool-test

# NAS 仿真测试
docker build -t pttool-nas -f docker/verify_nas.Dockerfile ..
docker run --rm -v "$PWD:/pttool:ro" pttool-nas
```

## 本地镜像维护

测试镜像构建后永久缓存，每次运行 `make test` 会先计算 Dockerfile + 测试脚本的 MD5 校验和，仅在校验和变化时才重建。这意味着：

- **首次构建**：需 1 次网络拉取 alpine + 安装包
- **后续运行**：完全离线，瞬间启动
- **代码变更**：自动感知并增量重建

查看构建时间戳和校验和：

```bash
make list
# === PTtool 测试镜像缓存 ===
#   ✓ pttool-test (2026-06-07 23:35:00, 19M)
#   ✓ pttool-nas (2026-06-07 22:01:15, 3.5M)
#     校验和: 81d800ff4aa887fbaaad9f49db67e8a9
#     校验和: 81b9bf1e6488f08230b94c3de6ef1619
```

## 架构

```
tests/
├── Makefile                   # 入口：build/rebuild/test/clean/list
├── docker/
│   ├── test_suite.Dockerfile  # 完整测试镜像定义
│   └── verify_nas.Dockerfile  # NAS 仿真镜像定义
├── .checksums/                # MD5 校验和缓存（自动管理）
├── test_suite.sh              # 15 项完整测试用例
├── verify_nas.sh              # 8 项 NAS 兼容性测试
└── README.md
```

## 测试文件说明

| 文件 | 用途 |
|------|------|
| `Makefile` | 镜像维护 + 一键测试入口 |
| `docker/*.Dockerfile` | 独立镜像定义（替代内联 heredoc） |
| `test_suite.sh` | 15 项完整测试（dash + coreutils + python3） |
| `verify_nas.sh` | 8 项 NAS 仿真测试（纯 Busybox） |
| `.checksums/` | MD5 校验和，自动管理 |

详细测试规范见 `docs/TESTING.md`。
