# PTtool 测试

## 快速开始

```bash
# 完整测试（含 dash 严格 POSIX 验证）
docker build -t pttool-test -f- .. <<'DOCKERFILE'
FROM alpine:3.21
RUN apk add --no-cache dash coreutils
COPY tests/test_suite.sh /test_suite.sh
RUN chmod +x /test_suite.sh
ENTRYPOINT ["/bin/sh", "/test_suite.sh"]
DOCKERFILE

docker run --rm -v "$PWD:/pttool:ro" pttool-test
```

```bash
# NAS 仿真测试（纯 Busybox ash）
docker build -t pttool-nas -f- .. <<'DOCKERFILE'
FROM alpine:3.21
COPY tests/verify_nas.sh /verify_nas.sh
RUN chmod +x /verify_nas.sh
ENTRYPOINT ["/bin/sh", "/verify_nas.sh"]
DOCKERFILE

docker run --rm -v "$PWD:/pttool:ro" pttool-nas
```

## 单行快速验证

```bash
# 语法检查
docker run --rm -v "$PWD:/pttool:ro" alpine:3.21 sh -c \
  'for f in /pttool/*.sh; do sh -n "$f" && echo "  ✓ $f" || echo "  ✗ $f"; done'
```

## 测试文件说明

| 文件 | 用途 |
|------|------|
| `test_suite.sh` | 完整测试套件（需 dash + coreutils + python3） |
| `verify_nas.sh` | NAS 仿真测试（仅需 Bare Busybox） |
| `docs/TESTING.md` | 测试用例文档、TC 编号、测试标准 |

详细测试规范见 `docs/TESTING.md`。
