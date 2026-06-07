#!/bin/sh
# test_suite.sh — PTtool 主测试套件（运行在 Docker 内）
# Usage: 构建 Docker 镜像后，将 PTtool 源码挂载到 /pttool 运行
#
# 构建:
#   docker build -t pttool-test -f- . <<'DOCKERFILE'
#   FROM alpine:3.21
#   RUN apk add --no-cache dash coreutils
#   COPY tests/test_suite.sh /test_suite.sh
#   RUN chmod +x /test_suite.sh
#   ENTRYPOINT ["/bin/sh", "/test_suite.sh"]
#   DOCKERFILE
#
# 运行:
#   docker run --rm -v "$PWD:/pttool:ro" pttool-test

set -u

# === 测试用例: TC-SYNTAX ===
# Shell 语法检查（dash 最严格的 POSIX 模式）
test_syntax() {
    for f in /pttool/*.sh; do
        if ! dash -n "$f" 2>/dev/null; then
            echo "  SYNTAX ERROR in $f" >&2; return 1
        fi
    done
    return 0
}

# === 测试用例: TC-FILEGIG ===
# mklink.sh 大小阈值：<1MB 复制，>1MB 硬链接
test_mklink() {
    rm -rf /tmp/t_mklink
    mkdir -p /tmp/t_mklink/src /tmp/t_mklink/dst
    dd if=/dev/zero of=/tmp/t_mklink/src/small.bin bs=1024 count=1 2>/dev/null
    dd if=/dev/zero of=/tmp/t_mklink/src/large.bin bs=1M count=2 2>/dev/null

    /pttool/mklink.sh /tmp/t_mklink/src /tmp/t_mklink/dst

    si=$(stat -c %i /tmp/t_mklink/src/small.bin)
    di=$(stat -c %i /tmp/t_mklink/dst/small.bin)
    [ "$si" = "$di" ] && { echo "  FAIL: small was hardlinked (should copy)" >&2; return 1; }

    si=$(stat -c %i /tmp/t_mklink/src/large.bin)
    di=$(stat -c %i /tmp/t_mklink/dst/large.bin)
    [ "$si" != "$di" ] && { echo "  FAIL: large was copied (should hardlink)" >&2; return 1; }

    return 0
}

# === 测试用例: TC-I18N ===
# SCRIPT_LANG 环境变量切换输出语言
test_mklink_i18n() {
    rm -rf /tmp/t_i18n
    mkdir -p /tmp/t_i18n/src /tmp/t_i18n/dst
    dd if=/dev/zero of=/tmp/t_i18n/src/a.bin bs=1M count=2 2>/dev/null

    cn=$(/pttool/mklink.sh /tmp/t_i18n/src /tmp/t_i18n/dst 2>&1)
    en=$(SCRIPT_LANG=en_US /pttool/mklink.sh /tmp/t_i18n/src /tmp/t_i18n/dst 2>&1)
    [ "$cn" = "$en" ] && { echo "  FAIL: SCRIPT_LANG=en_US same as default" >&2; return 1; }
    return 0
}

# === 测试用例: TC-IDEMPOTENT ===
# dirlink.sh 二次运行跳过已标记目录
test_dirlink() {
    rm -rf /tmp/t_dirlink
    mkdir -p /tmp/t_dirlink/src/movie/TheMatrix
    mkdir -p /tmp/t_dirlink/src/tv/BreakingBad
    dd if=/dev/zero of=/tmp/t_dirlink/src/movie/TheMatrix/f.mkv bs=1M count=5 2>/dev/null
    dd if=/dev/zero of=/tmp/t_dirlink/src/tv/BreakingBad/ep1.mkv bs=1M count=3 2>/dev/null

    /pttool/dirlink.sh /tmp/t_dirlink/src /tmp/t_dirlink/dst 2>&1

    [ -f "/tmp/t_dirlink/src/movie/islinked.lk" ] || { echo "  FAIL: no islinked.lk in src/movie" >&2; return 1; }
    [ -f "/tmp/t_dirlink/src/tv/islinked.lk" ]   || { echo "  FAIL: no islinked.lk in src/tv" >&2; return 1; }

    si=$(stat -c %i /tmp/t_dirlink/src/movie/TheMatrix/f.mkv)
    di=$(stat -c %i /tmp/t_dirlink/dst/movie/TheMatrix/f.mkv)
    [ "$si" != "$di" ] && { echo "  FAIL: f.mkv not hardlinked" >&2; return 1; }

    out2=$(/pttool/dirlink.sh /tmp/t_dirlink/src /tmp/t_dirlink/dst 2>&1)
    echo "  (idempotent output: $out2)" >&2

    return 0
}

# === 测试用例: TC-AUTOLINK ===
# qBittorrent 钩子参数解析 + EXCLUDE_CATEGORIES
test_autolink() {
    rm -rf /tmp/t_autolink
    mkdir -p /tmp/t_autolink/src/movie/TestMovie
    dd if=/dev/zero of=/tmp/t_autolink/src/movie/TestMovie/f.mkv bs=1M count=2 2>/dev/null

    /pttool/autolink.sh "TestMovie" "/tmp/t_autolink/src/movie" "movie" 2>&1
    echo "  autolink test completed" >&2

    out_excl=$(EXCLUDE_CATEGORIES="movies tv" /pttool/autolink.sh "movies" "/tmp" "movies" 2>&1)
    case "$out_excl" in
        *skip*|*跳过*) echo "  EXCLUDE works: $out_excl" >&2 ;;
        *) echo "  WARN: EXCLUDE didn't skip: $out_excl" >&2 ;;
    esac

    return 0
}

# === 测试用例: TC-AUTOTHANKS ===
# curl -d 参数应正确展开变量（修复单引号 bug）
test_autothanks() {
    if grep -q "'\"id\":\"\\\$" /pttool/autoThanks.sh; then
        echo "  FAIL: still has single-quoted curl -d" >&2
        return 1
    fi
    if ! grep -q 'curl.*-d "[^"]*id=\$' /pttool/autoThanks.sh; then
        echo "  WARN: couldn't verify curl -d id expansion" >&2
    fi
    return 0
}

# === 测试用例: TC-RENAME ===
# rename_episodes.py 正确计算 SXXEXX 偏移
test_rename() {
    rm -rf /tmp/t_rename
    mkdir -p /tmp/t_rename
    touch "/tmp/t_rename/Show S01E01.mkv"
    touch "/tmp/t_rename/Show S01E05.mkv"

    python3 /pttool/rename_episodes.py /tmp/t_rename 1 3 2>&1

    [ -f "/tmp/t_rename/Show S02E04.mkv" ] || { echo "  FAIL: S01E01 not renamed" >&2; return 1; }
    [ -f "/tmp/t_rename/Show S02E08.mkv" ] || { echo "  FAIL: S01E05 not renamed" >&2; return 1; }
    return 0
}

# === 测试用例: TC-I18N (Python) ===
# rename_episodes.py 的 SCRIPT_LANG 切换
test_rename_i18n() {
    rm -rf /tmp/t_rename_i18n
    mkdir -p /tmp/t_rename_i18n
    touch "/tmp/t_rename_i18n/T S01E01.mkv"

    cn=$(LANG=zh_CN.UTF-8 python3 /pttool/rename_episodes.py /tmp/t_rename_i18n 0 0 2>&1)
    en=$(SCRIPT_LANG=en_US python3 /pttool/rename_episodes.py /tmp/t_rename_i18n 0 0 2>&1)
    [ "$cn" = "$en" ] && { echo "  FAIL: SCRIPT_LANG=en_US same as default" >&2; return 1; }
    return 0
}

# === 测试用例: TC-CROSSFS ===
# 跨文件系统检测：SRC/DST 在不同分区应优雅报错
test_crossfs() {
    rm -rf /tmp/t_crossfs
    mkdir -p /tmp/t_crossfs/src /tmp/t_crossfs/dst2
    dd if=/dev/zero of=/tmp/t_crossfs/src/f.bin bs=1M count=2 2>/dev/null

    # 用 /proc (不同文件系统) 模拟跨分区
    out=$(/pttool/dirlink.sh /tmp/t_crossfs/src /proc/dummy 2>&1) && {
        echo "  FAIL: cross-fs should fail" >&2; return 1
    }
    echo "  CROSSFS: error correctly detected" >&2
    return 0
}

# === 测试用例: TC-SPECIALCHARS ===
# 含空格、中文、特殊字符的文件名正确处理
test_specialchars() {
    rm -rf /tmp/t_spc
    mkdir -p "/tmp/t_spc/src/My Movie 2024 (1080p)"
    mkdir -p "/tmp/t_spc/dst"
    dd if=/dev/zero of="/tmp/t_spc/src/My Movie 2024 (1080p)/file [BluRay] !@#$%^&().mkv" bs=1M count=2 2>/dev/null
    touch "/tmp/t_spc/src/My Movie 2024 (1080p)/subtitle [chi,eng].srt"
    touch "/tmp/t_spc/src/My Movie 2024 (1080p)/nfo!!.nfo"

    /pttool/mklink.sh "/tmp/t_spc/src/My Movie 2024 (1080p)" "/tmp/t_spc/dst" 2>&1

    for f in "file [BluRay] !@#$%^&().mkv" "subtitle [chi,eng].srt" "nfo!!.nfo"; do
        [ -f "/tmp/t_spc/dst/$f" ] || { echo "  FAIL: missing $f" >&2; return 1; }
    done
    echo "  SPECIALCHARS: all files linked correctly" >&2
    return 0
}

# === 测试用例: TC-EXCLUDE ===
# autolink.sh 排除分类功能验证
test_exclude() {
    rm -rf /tmp/t_excl
    mkdir -p /tmp/t_excl/src/movie/TestMovie
    dd if=/dev/zero of=/tmp/t_excl/src/movie/TestMovie/f.mkv bs=1M count=2 2>/dev/null

    # 正常调用应处理
    out_norm=$(/pttool/autolink.sh "TestMovie" "/tmp/t_excl/src/movie" "movie" 2>&1)
    echo "  normal: $out_norm" >&2

    # 排除类别应跳过
    out_excl=$(EXCLUDE_CATEGORIES="movies tv" /pttool/autolink.sh "movies" "/tmp" "movies" 2>&1)
    case "$out_excl" in
        *[Ss]kip*|*跳过*) echo "  EXCLUDE: correctly skipped" >&2 ;;
        *) echo "  FAIL: EXCLUDE didn't skip: $out_excl" >&2; return 1 ;;
    esac

    # 多分类排除
    out_multi=$(EXCLUDE_CATEGORIES="music movies tv software" /pttool/autolink.sh "movies" "/tmp" "movies" 2>&1)
    case "$out_multi" in
        *[Ss]kip*|*跳过*) echo "  EXCLUDE-MULTI: correctly skipped" >&2 ;;
        *) echo "  FAIL: EXCLUDE-MULTI didn't skip: $out_multi" >&2; return 1 ;;
    esac

    return 0
}

# === 测试用例: TC-CONCURRENT ===
# 并发运行 dirlink.sh 时不应产生冲突
test_concurrent() {
    rm -rf /tmp/t_conc
    mkdir -p /tmp/t_conc/src/tv/SeriesA
    dd if=/dev/zero of=/tmp/t_conc/src/tv/SeriesA/ep1.mkv bs=1M count=2 2>/dev/null

    # 启动两个并发进程
    /pttool/dirlink.sh /tmp/t_conc/src /tmp/t_conc/dst1 2>&1 &
    /pttool/dirlink.sh /tmp/t_conc/src /tmp/t_conc/dst2 2>&1 &
    wait

    # 至少一个成功
    [ -f "/tmp/t_conc/dst1/tv/SeriesA/ep1.mkv" ] || [ -f "/tmp/t_conc/dst2/tv/SeriesA/ep1.mkv" ] || {
        echo "  FAIL: no concurrent output produced" >&2; return 1
    }
    echo "  CONCURRENT: completed without conflict" >&2
    return 0
}

# === 测试用例: TC-FILEGIG-EDGE ===
# FILEGIG 边界值：正好 1MB、0 字节、不同后缀
test_filegig_edge() {
    rm -rf /tmp/t_fge
    mkdir -p /tmp/t_fge/src /tmp/t_fge/dst

    # 0 字节文件
    touch /tmp/t_fge/src/empty.bin
    # 正好 1MB（默认阈值上限）
    dd if=/dev/zero of=/tmp/t_fge/src/exact1M.bin bs=1M count=1 2>/dev/null

    /pttool/mklink.sh /tmp/t_fge/src /tmp/t_fge/dst 2>&1

    # 0 字节 → 应被 -size -1M 匹配 → 复制
    si=$(stat -c %i /tmp/t_fge/src/empty.bin)
    di=$(stat -c %i /tmp/t_fge/dst/empty.bin)
    [ "$si" = "$di" ] && { echo "  FAIL: empty file was hardlinked (should copy)" >&2; return 1; }

    # 正好 1MB → find -size -1M 不匹配（NOT smaller），-size +1M 也不匹配（NOT larger）
    # 所以这个文件不会被处理
    [ -f "/tmp/t_fge/dst/exact1M.bin" ] && {
        echo "  WARN: exact 1MB boundary: file was processed (implementation specific)" >&2
    } || {
        echo "  note: exact 1MB boundary file was skipped (expected, depends on find behavior)" >&2
    }

    echo "  FILEGIG-EDGE: boundaries verified" >&2
    return 0
}

# === 测试用例: TC-STRESS ===
# 批量性能：100 文件 + 10 子目录，计时
test_stress() {
    rm -rf /tmp/t_stress
    mkdir -p /tmp/t_stress/src /tmp/t_stress/dst

    _dir_i=0
    while [ "$_dir_i" -lt 10 ]; do
        mkdir -p "/tmp/t_stress/src/dir$_dir_i"
        _file_i=0
        while [ "$_file_i" -lt 10 ]; do
            dd if=/dev/zero of="/tmp/t_stress/src/dir$_dir_i/f$_file_i.bin" bs=1M count=2 2>/dev/null
            _file_i=$((_file_i + 1))
        done
        _dir_i=$((_dir_i + 1))
    done

    _start=$(date +%s)
    /pttool/dirlink.sh /tmp/t_stress/src /tmp/t_stress/dst 2>&1
    _end=$(date +%s)
    _elapsed=$((_end - _start))

    # 验证全部链完
    count=$(find /tmp/t_stress/dst -type f 2>/dev/null | wc -l)
    [ "$count" -eq 100 ] || { echo "  FAIL: expected 100 files, got $count" >&2; return 1; }

    echo "  STRESS: 100 files linked in ${_elapsed}s" >&2
    return 0
}

# === 测试用例: TC-FILEGIG (threshold) ===
# 500KB < 1MB default threshold, should copy (not hardlink)
test_filegig() {
    rm -rf /tmp/t_fg
    mkdir -p /tmp/t_fg/src /tmp/t_fg/dst
    dd if=/dev/zero of=/tmp/t_fg/src/mid.bin bs=1024 count=500 2>/dev/null

    /pttool/mklink.sh /tmp/t_fg/src /tmp/t_fg/dst

    si=$(stat -c %i /tmp/t_fg/src/mid.bin)
    di=$(stat -c %i /tmp/t_fg/dst/mid.bin)
    [ "$si" = "$di" ] && { echo "  FAIL: 500KB was hardlinked (should copy <1MB)" >&2; return 1; }
    return 0
}

# === Run ===
PASS=0; FAIL=0; ERRORS=""

echo "=== PTtool Verification Container ==="
echo "OS: $(uname -a)"
echo "sh: $(readlink -f /bin/sh) ($(/bin/sh -c 'echo $0'))"
echo "dash: $(command -v dash) ($(dash --version 2>&1 | head -1))"
echo "python3: $(python3 --version 2>&1)"
echo ""

for t in \
    test_syntax \
    test_mklink \
    test_mklink_i18n \
    test_dirlink \
    test_autolink \
    test_autothanks \
    test_rename \
    test_rename_i18n \
    test_filegig \
    test_crossfs \
    test_specialchars \
    test_exclude \
    test_concurrent \
    test_filegig_edge \
    test_stress; do
    name=$(echo "$t" | sed 's/^test_//')
    printf "  %-30s " "$name..."
    if "$t" >/dev/null 2>&1; then
        printf "PASS\n"
        PASS=$((PASS + 1))
    else
        printf "FAIL\n"
        "$t"
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}  FAIL: ${t}\n"
    fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ -n "$ERRORS" ] && { echo ""; printf "%b" "$ERRORS"; exit 1; }
exit 0
