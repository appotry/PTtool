#!/bin/sh
# autolink.sh - qBittorrent 下载完成钩子 / qBittorrent download completion hook
# Usage / 用法: autolink.sh "%N" "%D" "%L"
#
# qBittorrent 命令参数 / qBittorrent parameters:
# qBittorrent %N：Torrent 名称 / Torrent name
# qBittorrent %F：内容路径（与多文件 torrent 的根目录相同）/ Content path
# qBittorrent %L：分类 / Category
# qBittorrent %G：标签（以逗号分隔）/ Tags (comma separated)
# qBittorrent %R：根目录（第一个 torrent 的子目录路径）/ Root directory
# qBittorrent %D：保存路径 / Save path
# qBittorrent %C：文件数 / File count
# qBittorrent %Z：Torrent 大小（字节）/ Torrent size (bytes)
# qBittorrent %T：当前 tracker / Current tracker
# qBittorrent %I：哈希值 / Info hash
# 在 qBittorrent 按如上顺序键入参数，ex:/path/to/autolink.sh "%N" "%D" "%L"
# Pass parameters in the above order in qBittorrent

# --- i18n: output language selection / 输出语言选择 ---
_lang="${SCRIPT_LANG:-${LANG:-zh_CN}}"
case "$_lang" in en*)
  MSG_SKIP="Skip excluded category:"
  ;;
*)
  MSG_SKIP="跳过排除的分类："
  ;;
esac

# =====================================================
# 配置 / Configuration
# =====================================================

# 硬链接目标根目录 / Hardlink destination root
# 所有分类的子目录会自动创建在下方路径中
# Subdirectories for each category will be auto-created under this path
your_path=/mnt/nas/disk2/jellyfin

# 默认链接所有分类。如需排除某些分类，取消注释并修改：
# By default ALL categories are linked. To exclude specific ones, uncomment:
# EXCLUDE_CATEGORIES="music software xxx"

# =====================================================

# 获取种子信息 / Get torrent info from qBittorrent arguments
torrent_name="$1"
torrent_path="$2"
torrent_category="$3"

link_path="$your_path/$torrent_category"

# 获取脚本所在目录（便携替代 readlink -f，兼容 BSD/macOS）
# Get script directory (portable alternative to readlink -f)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 排除检查 / Check if this category should be excluded
_exclude="${EXCLUDE_CATEGORIES:-}"
case " $_exclude " in
  *" $torrent_category "*)
    printf '%s %s\n' "$MSG_SKIP" "$torrent_category"
    exit 0
    ;;
esac

# 判断是单文件种子还是带有目录的种子
# Determine if this is a multi-file or single-file torrent
if [ -d "$torrent_path/$torrent_name" ]; then
  # 多文件种子：先删除下载过程中可能被误创建的 islinked.lk
  # Multi-file: remove marker that may have been created during download
  rm -f "$torrent_path/$torrent_name/islinked.lk"
  "$SCRIPT_DIR/dirlink.sh" "$torrent_path" "$link_path"
elif [ -f "$torrent_path/$torrent_name" ]; then
  # 单文件种子：同样先删除可能误创建的标记
  # Single-file: remove any marker created during download
  rm -f "$torrent_path/islinked.lk"
  # 注意：单文件种子需要 qBittorrent 中设置好分类保存目录
  # Note: the save location must be configured in qBittorrent
  _parent=$(cd "$torrent_path" && pwd)
  "$SCRIPT_DIR/dirlink.sh" "$(dirname "$_parent")" "$link_path"
fi
