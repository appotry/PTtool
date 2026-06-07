#!/bin/sh
# author / 作者: andycrusoe@gmail.com
# 使用说明 / Usage: https://github.com/appotry/PTtool#readme
# 结合 du -b 可以得到性能更快更好的版本，目前先用这个
# This version works but can be optimized with du -b for better performance

# 查找文件硬链接的命令参考 / Commands to inspect hardlinks:
# ls -ialh file.txt
# find . -inum 1234

# --- i18n: output language selection / 输出语言选择 ---
# SCRIPT_LANG=en_US → English, otherwise Chinese (default / 默认中文)
_lang="${SCRIPT_LANG:-${LANG:-zh_CN}}"
case "$_lang" in en*)
  # English messages
  MSG_USAGE_SHORT="Usage: mklink.sh sourcedir dstdir"
  MSG_USER_SET="User set:"
  MSG_DEF_SET="use default set:"
  MSG_SRC_LABEL="src:"
  MSG_DST_LABEL="dst:"
  MSG_WORK="work:"
  MSG_SKIP_DIR1="Skip dir1:"
  MSG_SKIP_DIR3="Skip dir3:"
  MSG_SRC_FILE="src file:"
  MSG_DST_FILE="dst file:"
  MSG_MKDIR="mkdir -p"
  MSG_CP_L="cp -l"
  MSG_CP="cp"
  MSG_SEP="--"
  MSG_ERR_SRC="Error: SRC does not exist:"
  MSG_ERR_DST="Error: cannot create DST:"
  MSG_ERR_FS="Error: SRC and DST must be on same filesystem (hardlink constraint)"
  ;;
*)
  # Chinese messages / 中文消息
  MSG_USAGE_SHORT="Usage:mklink.sh sourcedir dstdir"
  MSG_USER_SET="User set:"
  MSG_DEF_SET="use default set:"
  MSG_SRC_LABEL="源目录src:"
  MSG_DST_LABEL="目的目录dst:"
  MSG_WORK="work:"
  MSG_SKIP_DIR1="跳过处理目录1:"
  MSG_SKIP_DIR3="跳过处理目录3:"
  MSG_SRC_FILE="src file:"
  MSG_DST_FILE="dst file:"
  MSG_MKDIR="mkdir -p"
  MSG_CP_L="cp -l"
  MSG_CP="cp"
  MSG_SEP="--"
  MSG_ERR_SRC="错误：源目录不存在："
  MSG_ERR_DST="错误：无法创建目标目录："
  MSG_ERR_FS="错误：源目录和目标目录必须在同一文件系统（硬链接限制）"
  ;;
esac

# 默认源目录和目标目录 / Default source and destination dirs
SRC="/share/Download/tmp/src"
DST="/share/Download/tmp/dst"

# 文件大小阈值：大于此值硬链接，小于此值复制
# File size threshold: files larger than this get hardlinked, smaller ones get copied
# 默认 1000000c = 1MB，可改为 10M、100M、1G 等
# Default is 1000000c (1 MB). Can also use 10M, 100M, 1G etc.
FILEGIG=1000000c

# 参数处理：如果给了 2 个参数就用用户指定的目录，否则显示默认目录并退出
# Argument handling: if 2 args provided, use them; otherwise show defaults and exit
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
    exit 1
fi

# 检查目录有效性 + 跨文件系统 / Validate directories + check filesystem
if [ ! -d "$SRC" ]; then
    echo "$MSG_ERR_SRC $SRC" >&2
    exit 2
fi
if [ ! -d "$DST" ]; then
    echo "$MSG_ERR_DST $DST" >&2
    exit 2
fi
_src_dev=$(stat -c %d "$SRC" 2>/dev/null)
_dst_dev=$(stat -c %d "$DST" 2>/dev/null)
if [ "$_src_dev" ] && [ "$_dst_dev" ] && [ "$_src_dev" != "$_dst_dev" ]; then
    echo "$MSG_ERR_FS" >&2
    exit 2
fi

# 大于阈值（默认 1MB）→ 硬链接
# Files larger than threshold → hardlink
find "$SRC" -size +"$FILEGIG" 2>/dev/null | while IFS= read -r i; do

    echo "$MSG_WORK$i"

    [ -d "$i" ] && { echo "$MSG_SKIP_DIR1$i"; echo "$MSG_SEP"; continue; }

    tmppth=$(dirname "$i")
    pth=$(echo "$tmppth" | sed "s|$SRC|$DST|")

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
find "$SRC" -size -"$FILEGIG" 2>/dev/null | while IFS= read -r i; do

    echo "$MSG_WORK$i"

    [ -d "$i" ] && { echo "$MSG_SKIP_DIR3$i"; echo "$MSG_SEP"; continue; }

    tmppth=$(dirname "$i")
    pth=$(echo "$tmppth" | sed "s|$SRC|$DST|")

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
