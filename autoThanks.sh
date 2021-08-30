#!/bin/bash
#code created by thedaoge
#个人脚本管理器配置，可以删除。
#20191104，增加了sleep 16 点一个赞等待16秒，避免撸死了站点被ban
SHDNM=pt_more_thanks
SHDVER=1.0.0
#配置头结束。
#编辑以下内容
COOKIES="获取到的ID完整的粘贴在这里"
#仅供娱乐，自行修改为正确cookies
SITE="https://pterclub.com.disabled/thanks.php"
#仅供娱乐，自行修改为你希望批量点赞的NexusPHP搭建的PT站点
MINID="1"
#开始ID
MAXID="20000"
#结束ID
UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0 pt_more_thanks/1.0.0"
#不要编辑以下内容，除非你懂
echo "当前IP"
#取巧，取得当前IP，顺便判断是否已经安装CURL，如果CURL未安装，运行的返回值不为0，退出脚本
curl ip.3322.org

if [ $? == "0" ]
  then echo "万事俱备只欠东风"
else echo "你还没有安装curl"
  exit 1
fi
echo "动手！！！你还有5秒钟考虑，如果决定放弃，按CTRL+C。继续使用代表你已接受条款后果自负。"
sleep 5

for ((i=MINID; i<=MAXID; i++))
do
  curl $SITE -X POST -H "User-Agent: $UA" -d '"id":"$i"' --cookie $COOKIES --referer "https://pterclub.com/details.php?id=$i&hit=1"
  sleep 16
done
