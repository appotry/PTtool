#!/bin/sh
# author / 作者: andycrusoe@gmail.com
# 记录日志用法 / Log usage: ./dirlink.sh > dirlink.log
# 使用说明 / Usage: https://github.com/appotry/PTtool#readme

# 查找文件硬链接的命令参考 / Commands to inspect hardlinks:
# ls -ialh file.txt
# find . -inum 1234

# 最后面不要加斜杠 / Do NOT add trailing slashes to paths below
SRC="/share/Download/tmp/src"
DST="/share/Download/tmp/dst"

# --- i18n: output language selection / 输出语言选择 ---
# SCRIPT_LANG=en_US → English, otherwise Chinese (default / 默认中文)
_lang="${SCRIPT_LANG:-${LANG:-zh_CN}}"
case "$_lang" in en*)
  # English messages
  MSG_SKIP_DIR="Skip dir:"
  MSG_LINK_DIR="Current lnk dir:"
  MSG_ALREADY_LINKED="already linked, skip"
  MSG_ERR_SRC="Error: SRC does not exist:"
  MSG_ERR_DST="Error: cannot create DST:"
  MSG_ERR_FS="Error: SRC and DST must be on same filesystem (hardlink constraint)"
  ;;
*)
  # Chinese messages / 中文消息
  MSG_SKIP_DIR="跳过处理目录:"
  MSG_LINK_DIR="当前硬链接目录"
  MSG_ALREADY_LINKED="已经硬链接过，跳过此目录"
  MSG_ERR_SRC="错误：源目录不存在："
  MSG_ERR_DST="错误：无法创建目标目录："
  MSG_ERR_FS="错误：源目录和目标目录必须在同一文件系统（硬链接限制）"
  ;;
esac

# Messages used in originals as English (unchanged in both languages)
# 原版即英文的消息（中英文保持一致）
MSG_USAGE_SHORT="Usage:dirlink.sh sourcedir dstdir"
MSG_USER_SET="User set:"
MSG_DEF_SET="use default set:"
MSG_SRC_LABEL="src:"
MSG_DST_LABEL="dst:"
MSG_MKLINK_ECHO="mklink:"
MSG_WORK="work:"
MSG_TH_SRC_FILE="THISSRC file:"
MSG_SRC_FILE="src file:"
MSG_DST_FILE="dst file:"
MSG_MKDIR="mkdir -p"
MSG_CP_L="cp -l"
MSG_CP="cp"
MSG_SEP="--"
MSG_SEP_EQ="=="
MSG_WORK_DIR="work dir:"

# 文件大小阈值 / File size threshold (default 1 MB)
FILEGIG=1000000c

######################################

# 核心硬链接函数：将一个源目录中的文件硬链接/复制到目标目录
# Core function: hardlink/copy all files from one source dir to one destination dir
mklink()
{
    THISSRC=$1
    THISDST=$2
    echo "$*"
    echo "$MSG_MKLINK_ECHO$THISSRC $THISDST"

    # 大于阈值（默认 1MB）→ 硬链接
    # Files larger than threshold → hardlink
    find "$THISSRC" -size +"$FILEGIG" 2>/dev/null | while IFS= read -r i; do
        echo "$MSG_WORK$i"

        [ -d "$i" ] && { echo "$MSG_SKIP_DIR$i"; echo "$MSG_SEP"; continue; }

        tmppth=$(dirname "$i")
        pth=$(echo "$tmppth" | sed "s|$THISSRC|$THISDST|")

        if [ ! -d "$pth" ]; then
            echo "$MSG_MKDIR $pth"
            mkdir -p "$pth"
        fi

        dstfile="$pth"/$(basename "$i")
        echo "$MSG_DST_FILE$dstfile"

        if [ ! -f "$dstfile" ]; then
          echo "$MSG_CP_L $i $dstfile"
          cp -l "$i" "$dstfile"
        fi

        echo "$MSG_SEP"
    done

    # 小于阈值（默认 1MB）→ 复制
    # Files smaller than threshold → copy
    find "$THISSRC" -size -"$FILEGIG" 2>/dev/null | while IFS= read -r i; do
        echo "$MSG_WORK$i"

        [ -d "$i" ] && { echo "$MSG_SKIP_DIR$i"; echo "$MSG_SEP"; continue; }

        tmppth=$(dirname "$i")
        pth=$(echo "$tmppth" | sed "s|$THISSRC|$THISDST|")

        if [ ! -d "$pth" ]; then
          echo "$MSG_MKDIR $pth"
          mkdir -p "$pth"
        fi

        dstfile="$pth"/$(basename "$i")
        echo "$MSG_DST_FILE$dstfile"

        if [ ! -f "$dstfile" ]; then
          echo "$MSG_CP $i $dstfile"
          cp "$i" "$dstfile"
        fi

        echo "$MSG_SEP"
    done

    return 0
}

# 参数处理：如果给了 2 个参数就用用户指定的目录，否则显示默认目录
# Argument handling: if 2 args, use them; otherwise show defaults
if [ $# -eq 2 ]; then
    SRC=$1
    DST=$2
    echo "$MSG_USER_SET"
    echo "$MSG_SRC_LABEL$SRC"
    echo "$MSG_DST_LABEL$DST"
else
    echo "$MSG_USAGE_SHORT"
    echo "$MSG_DEF_SET"
    echo "$MSG_SRC_LABEL$SRC"
    echo "$MSG_DST_LABEL$DST"
fi

# 检查 SRC 有效性 + 跨文件系统 / Validate SRC + check cross-filesystem
if [ ! -d "$SRC" ]; then
    echo "$MSG_ERR_SRC $SRC" >&2
    exit 2
fi
# 自动创建 DST 目录 / Auto-create DST directory
mkdir -p "$DST" 2>/dev/null || {
    echo "$MSG_ERR_DST $DST" >&2; exit 2
}
_src_dev=$(stat -c %d "$SRC" 2>/dev/null)
_dst_dev=$(stat -c %d "$DST" 2>/dev/null)
if [ "$_src_dev" ] && [ "$_dst_dev" ] && [ "$_src_dev" != "$_dst_dev" ]; then
    echo "$MSG_ERR_FS" >&2
    exit 2
fi

# 遍历源目录下的子目录，逐个子目录执行硬链接
# Iterate over subdirectories and process each one
find "$SRC" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while IFS= read -r dir; do
    _dir=$(basename "$dir")
    echo "$MSG_WORK_DIR$_dir"

    dstdir=$DST/$_dir
    echo "$MSG_LINK_DIR$dstdir"

    if [ ! -e "$dir/islinked.lk" ]; then
        mklink "$dir" "$dstdir"
        touch "$dir"/islinked.lk
        echo "$MSG_SEP_EQ"
    else
        echo "$_dir $MSG_ALREADY_LINKED"
        echo "$MSG_SEP_EQ"
    fi
done
