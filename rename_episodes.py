#!/usr/bin/env python3
import os
import re
import sys

# 说明：修正SXXEXX的偏移量。
# useage:
# python rename_episodes.py /path/to/your/folder 1 -12

def rename_files(target_dir, season_offset, episode_offset):
    pattern = re.compile(r"S(\d{2})E(\d{2})")

    for filename in os.listdir(target_dir):
        match = pattern.search(filename)
        if match:
            season = int(match.group(1)) + season_offset
            episode = int(match.group(2)) + episode_offset

            # 限制下限，防止出现负数或 0
            season = max(1, season)
            episode = max(1, episode)

            new_tag = f"S{season:02d}E{episode:02d}"
            new_filename = pattern.sub(new_tag, filename)

            old_path = os.path.join(target_dir, filename)
            new_path = os.path.join(target_dir, new_filename)

            os.rename(old_path, new_path)
            print(f"✅ {filename}  →  {new_filename}")
        else:
            print(f"⚠️ 跳过：{filename}（未匹配 SxxExx 模式）")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("用法: python rename_episodes.py <target_dir> <season_offset> <episode_offset>")
        print("示例: python rename_episodes.py ./videos 1 -12")
        sys.exit(1)

    target_dir = sys.argv[1]
    season_offset = int(sys.argv[2])
    episode_offset = int(sys.argv[3])

    rename_files(target_dir, season_offset, episode_offset)
