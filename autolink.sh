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
#在qBittorrent分别按如上顺序键入参数，ex:/path/to/autolink.sh "%N" "%D" "%L"

#your_path=/path/to/creat/link
your_path=/mnt/nas/disk2/jellyfin

#获取种子名称
torrent_name="$1"
#获取保存路径
torrent_path="$2"
#获取种子分类
torrent_category="$3"

link_path_library="$your_path"/"$torrent_category"

#判断是否是需要建立硬链接的分类
if [[ "$torrent_category" == *"movies"* || "$torrent_category" == *"series"* || "$torrent_category" == *"documents"* || "$torrent_category" == *"operas"* ]]
then
  #判断是单文件种子还是带有目录的种子
  if [ -d "$torrent_path"/"$torrent_name" ];
  then
    #如果是带有目录的种子，先删除下载过程中被误创建的记录
    rm "$torrent_path"/"$torrent_name"/islinked.lk
    #调用dirlink.sh，创建硬链接
    "$(dirname $(readlink -f $0))"/dirlink.sh "$torrent_path" "$link_path_library"
  elif [ -e "$torrent_path"/"$torrent_name" ];
  then
    #如果是单文件种子，同样先删除下载过程中被误创建的记录
    rm "$torrent_path"/islinked.lk
    #调用dirlink.sh，将下载目录（注意，这个需要自己手动在qbittorrent中设置好）下的所有文件创建硬链接
    "$(dirname $(readlink -f $0))"/dirlink.sh "$torrent_path"/.. "$link_path_library"
  fi
fi
