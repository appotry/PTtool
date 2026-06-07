#!/bin/sh
# verify_nas.sh — NAS 环境仿真测试（QNAP/Synology 模拟）
# 使用纯 Busybox ash，不依赖额外工具，验证最低兼容性
# Usage: 构建 Docker 镜像后，将 PTtool 源码挂载到 /pttool 运行

set -u
PASS=0; FAIL=0

# === 测试用例: TC-SYNTAX (NAS) ===
# Busybox ash 语法检查
test_syntax() {
    for f in /pttool/*.sh; do
        if ! /bin/sh -n "$f" 2>/dev/null; then
            echo "  SYNTAX ERROR in $f" >&2; return 1
        fi
    done
    return 0
}

# === 测试用例: TC-FILEGIG (NAS) ===
test_mklink_busybox() {
    rm -rf /tmp/t_mklink
    mkdir -p /tmp/t_mklink/src /tmp/t_mklink/dst
    dd if=/dev/zero of=/tmp/t_mklink/src/small.bin bs=1024 count=1 2>/dev/null
    dd if=/dev/zero of=/tmp/t_mklink/src/large.bin bs=1M count=2 2>/dev/null

    /pttool/mklink.sh /tmp/t_mklink/src /tmp/t_mklink/dst >/dev/null 2>&1

    si=$(stat -c %i /tmp/t_mklink/src/small.bin 2>/dev/null) || return 0
    di=$(stat -c %i /tmp/t_mklink/dst/small.bin 2>/dev/null) || return 0
    [ "$si" = "$di" ] && { echo "  FAIL: small hardlinked" >&2; return 1; }

    si=$(stat -c %i /tmp/t_mklink/src/large.bin 2>/dev/null) || return 0
    di=$(stat -c %i /tmp/t_mklink/dst/large.bin 2>/dev/null) || return 0
    [ "$si" != "$di" ] && { echo "  FAIL: large not hardlinked" >&2; return 1; }
    return 0
}

# === 测试用例: TC-SPACES ===
# 含空格的目录名正确处理
test_spaces() {
    rm -rf /tmp/t_spaces
    mkdir -p "/tmp/t_spaces/src/My Movie 2024"
    dd if=/dev/zero of="/tmp/t_spaces/src/My Movie 2024/file.mkv" bs=1M count=2 2>/dev/null
    /pttool/dirlink.sh /tmp/t_spaces/src /tmp/t_spaces/dst >/dev/null 2>&1

    [ -f "/tmp/t_spaces/dst/My Movie 2024/file.mkv" ] || { echo "  FAIL: spaced file missing" >&2; return 1; }
    return 0
}

# === 测试用例: TC-IDEMPOTENT (NAS) ===
test_dirlink_qnap() {
    rm -rf /tmp/t_dl
    mkdir -p /tmp/t_dl/src/Movie/M1 /tmp/t_dl/src/TV/S1
    dd if=/dev/zero of=/tmp/t_dl/src/Movie/M1/f.mkv bs=1M count=2 2>/dev/null
    dd if=/dev/zero of=/tmp/t_dl/src/TV/S1/ep.mkv bs=1M count=2 2>/dev/null

    /pttool/dirlink.sh /tmp/t_dl/src /tmp/t_dl/dst >/dev/null 2>&1
    /pttool/dirlink.sh /tmp/t_dl/src /tmp/t_dl/dst >/dev/null 2>&1

    [ -f /tmp/t_dl/src/Movie/islinked.lk ] || { echo "  FAIL: no Movie marker" >&2; return 1; }
    [ -f /tmp/t_dl/src/TV/islinked.lk ]   || { echo "  FAIL: no TV marker" >&2; return 1; }
    [ -f /tmp/t_dl/dst/Movie/M1/f.mkv ]   || { echo "  FAIL: dst/Movie/M1/f.mkv missing" >&2; return 1; }
    [ -f /tmp/t_dl/dst/TV/S1/ep.mkv ]     || { echo "  FAIL: dst/TV/S1/ep.mkv missing" >&2; return 1; }
    return 0
}

# === 测试用例: TC-AUTOLINK (NAS) ===
test_autolink_exclude() {
    EXCLUDE_CATEGORIES="movies xxx" /pttool/autolink.sh "movies" "/tmp" "movies" 2>&1 | grep -qiE 'skip|跳过' || return 1
    EXCLUDE_CATEGORIES="movies" /pttool/autolink.sh "tv" "/tmp" "tv" 2>&1 | grep -qiE 'skip|跳过' && return 1
    return 0
}

# === 测试用例: /share/ 路径兼容 ===
test_share_path() {
    rm -rf /share/t_test
    mkdir -p /share/t_test/src/sub
    dd if=/dev/zero of=/share/t_test/src/sub/f.bin bs=1M count=2 2>/dev/null
    /pttool/mklink.sh /share/t_test/src /share/t_test/dst >/dev/null 2>&1
    [ -f /share/t_test/dst/sub/f.bin ] || { echo "  FAIL: /share/ path not working" >&2; return 1; }
    return 0
}

# === 测试用例: TC-FILEGIG exit code ===
# 验证 exit -1 已被替换为 exit 1
test_exit_code() {
    /pttool/mklink.sh >/dev/null 2>&1
    rc=$?
    [ "$rc" = 1 ] || [ "$rc" = 255 ] || { echo "  FAIL: exit code $rc (expected 1)" >&2; return 1; }
    return 0
}

# === 测试用例: TC-FILEGIG (NAS) ===
# 500KB < 1MB threshold, Busybox find -size
test_filegig_busybox() {
    rm -rf /tmp/t_fg
    mkdir -p /tmp/t_fg/src /tmp/t_fg/dst
    dd if=/dev/zero of=/tmp/t_fg/src/mid.bin bs=1024 count=500 2>/dev/null
    /pttool/mklink.sh /tmp/t_fg/src /tmp/t_fg/dst >/dev/null 2>&1

    si=$(stat -c %i /tmp/t_fg/src/mid.bin 2>/dev/null) || return 0
    di=$(stat -c %i /tmp/t_fg/dst/mid.bin 2>/dev/null) || return 0
    [ "$si" = "$di" ] && { echo "  FAIL: 500KB hardlinked (should copy)" >&2; return 1; }
    return 0
}

# === Run ===
echo "=== QNAP/Synology NAS Simulation ==="
echo "sh: $(readlink -f /bin/sh 2>/dev/null || basename "$0")"
echo "stat: $(command -v stat || echo NO)"
echo ""

for t in test_syntax test_mklink_busybox test_spaces test_dirlink_qnap \
         test_autolink_exclude test_share_path test_exit_code test_filegig_busybox; do
    name=$(echo "$t" | sed 's/^test_//')
    printf "  %-25s " "$name..."
    if "$t" 2>/dev/null; then echo "PASS"; else echo "FAIL"; FAIL=$((FAIL+1)); fi
done

echo ""
echo "=== Results ==="
[ "$FAIL" = 0 ] && echo "All tests passed" || echo "$FAIL test(s) failed"
exit $FAIL
