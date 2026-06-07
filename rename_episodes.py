#!/usr/bin/env python3
# 说明 / Description: 修正 SXXEXX 的偏移量 / Adjust SXXEXX episode numbering by offset.
# useage / Usage:
#   python3 rename_episodes.py /path/to/your/folder 1 -12

import os
import re
import sys

# --- i18n: 语言选择 / Language selection ---
# 环境变量 SCRIPT_LANG=en_US → English, 否则中文 / else Chinese
_lang = "en" if os.environ.get("SCRIPT_LANG", os.environ.get("LANG", "zh_CN")).startswith("en") else "zh"

MSG = {
    "usage": {
        "zh": "用法：python3 rename_episodes.py <目录> <季偏移> <集偏移>",
        "en": "Usage: python3 rename_episodes.py <dir> <season_offset> <episode_offset>",
    },
    "example": {
        "zh": "示例：python3 rename_episodes.py ./videos 1 -12",
        "en": "Example: python3 rename_episodes.py ./videos 1 -12",
    },
    "renamed": {
        "zh": "重命名：{}  →  {}",
        "en": "Renamed: {}  →  {}",
    },
    "skip": {
        "zh": "跳过：{}（未匹配 SxxExx 模式）",
        "en": "Skip: {} (no SxxExx pattern found)",
    },
}

_l = lambda key, *args: MSG[key][_lang].format(*args)


def rename_files(target_dir, season_offset, episode_offset):
    """重命名匹配 SxxExx 模式的文件 / Rename files matching the SxxExx pattern."""
    pattern = re.compile(r"S(\d{2})E(\d{2})")

    for filename in os.listdir(target_dir):
        match = pattern.search(filename)
        if match:
            season = int(match.group(1)) + season_offset
            episode = int(match.group(2)) + episode_offset

            # 限制下限，防止出现负数或 0 / Clamp to minimum of 1
            season = max(1, season)
            episode = max(1, episode)

            new_tag = f"S{season:02d}E{episode:02d}"
            new_filename = pattern.sub(new_tag, filename)

            old_path = os.path.join(target_dir, filename)
            new_path = os.path.join(target_dir, new_filename)

            os.rename(old_path, new_path)
            print(_l("renamed", filename, new_filename))
        else:
            print(_l("skip", filename))


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(_l("usage"))
        print(_l("example"))
        sys.exit(1)

    target_dir = sys.argv[1]
    season_offset = int(sys.argv[2])
    episode_offset = int(sys.argv[3])

    rename_files(target_dir, season_offset, episode_offset)
