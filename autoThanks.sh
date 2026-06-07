#!/bin/sh
# autoThanks.sh - NexusPHP 站点批量感谢 / Bulk "Thanks" for NexusPHP PT sites
#
# ⚠️ WARNING / 警告: This script is DANGEROUS. Misuse can get your PT account banned.
# 此脚本有风险，误用可能导致 PT 账号被封！
#
# code created by / 代码作者: thedaoge
# 个人脚本管理器配置，可以删除 / Personal script manager config, safe to delete.
# 20191104: added 16s delay per POST to avoid triggering rate limits
# 增加了 sleep 16，每发一个感谢等待 16 秒，避免被站点封禁

# 脚本元信息 / Script metadata (safe to delete / 可以删除)
SHDNM=pt_more_thanks
SHDVER=1.0.0
# 配置头结束 / Config section end.

# --- i18n: output language selection / 输出语言选择 ---
_lang="${SCRIPT_LANG:-${LANG:-zh_CN}}"
case "$_lang" in en*)
  MSG_IP="Current IP:"
  MSG_READY="All set, ready to go."
  MSG_NO_CURL="Error: curl is not installed"
  MSG_WARN="Proceeding in 5 seconds... Press Ctrl+C to abort. By continuing you accept all consequences."
  MSG_SKIP="Skip (unknown response):"
  ;;
*)
  MSG_IP="当前 IP："
  MSG_READY="万事俱备只欠东风"
  MSG_NO_CURL="错误：未安装 curl"
  MSG_WARN="5 秒后开始执行… 按 Ctrl+C 中止。继续代表你已接受条款，后果自负。"
  MSG_SKIP="跳过（未知响应）："
  ;;
esac

# --- 编辑以下内容 / Edit the following configuration ---

# 获取到的完整的 Cookie 粘贴在这里
# Paste your complete Cookie string here
COOKIES="paste your full cookie string here"

# 仅供娱乐，自行修改为正确 cookies
# For reference only — replace with your actual cookies
SITE="https://pterclub.com.disabled/thanks.php"

# 仅供娱乐，自行修改为你希望批量点赞的 NexusPHP 搭建的 PT 站点
# For reference only — replace with your target NexusPHP site URL
MINID="1"          # 开始 ID / Start ID
MAXID="20000"      # 结束 ID / End ID

UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0 pt_more_thanks/1.0.0"

# --- 不要编辑以下内容，除非你懂 ---
# --- Do not edit below unless you know what you are doing ---

# 显示当前 IP / Display current IP
printf '%s ' "$MSG_IP"
# 获取当前 IP，顺便判断是否已经安装 curl
# Fetch current IP, also check if curl is installed
# 如果 curl 未安装，运行返回非零值，退出脚本
# If curl is not installed, the command will fail and we exit
curl -s ip.3322.org

if [ $? = "0" ]; then
  printf '\n%s\n' "$MSG_READY"
else
  printf '\n%s\n' "$MSG_NO_CURL"
  exit 1
fi

# 最后确认 / Final confirmation
printf '\n%s\n' "$MSG_WARN"
sleep 5

# 循环发送感谢 / Send thanks in a loop
_id="$MINID"
while [ "$_id" -le "$MAXID" ]; do
  curl "$SITE" \
    -X POST \
    -H "User-Agent: $UA" \
    -d "id=$_id" \
    --cookie "$COOKIES" \
    --referer "https://pterclub.com/details.php?id=$_id&hit=1" \
    --silent --show-error || printf '%s %s\n' "$MSG_SKIP" "$_id"
  # 每发一个感谢等待 16 秒，避免被站点封禁
  # Wait 16 seconds between thanks to avoid triggering rate limits
  sleep 16
  _id=$((_id + 1))
done
