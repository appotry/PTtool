#!/bin/bash
#qBittorrent命令参数：
#qBittorrent %N：Torrent 名称
#qBittorrent %F：内容路径（与多文件 torrent 的根目录相同）
#qBittorrent %L：分类
#qBittorrent %G：标签（以逗号分隔）
#qBittorrent %R：根目录（第一个 torrent 的子目录路径）
#qBittorrent %D：保存路径
#qBittorrent %C：文件数
#qBittorrent %Z：Torrent 大小（字节）
#qBittorrent %T：当前 tracker
#qBittorrent %I：哈希值
#在qBittorrent分别按如上顺序键入参数，ex:/path/to/autolink.sh "%N" "%F" "%L"

#your_path=/path/to/creat/link
your_path=/mnt/nas/disk2/jellyfin

#获取种子名称
torrent_name="$1"
#获取种子路径
torrent_path="$2"

#获取种子分类
torrent_category="$3"

link_path_library="$your_path"/"$3"

if [[ "$3" == *"movies"* || "$3" == *"series"* || "$3" == *"documents"* || "$3" == *"operas"* ]]; then
  "$(dirname $(readlink -f $0))"/dirlink.sh "$2" "$link_path_library"
fi
