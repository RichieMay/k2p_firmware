#!/bin/sh

uprul=`cat /tmp/upinfo |awk -F',' '{print $5}' `
upmd5=`cat /tmp/upinfo |awk -F',' '{print $6}' `
if [ -z "$upmd5" ] ;then
return
fi
count=`ps -w|grep sysupgrade|grep -v grep|wc -l`
[ "$icount" -gt 0 ] && exit
wget $uprul -O /tmp/sysupgrade.bin -t 2 -T 30
if [ "$?" == "0" ]; then
localmd5=`md5sum  /tmp/sysupgrade.bin|awk  '{print $1}'`
if [ "$upmd5" == "$localmd5" ] ;then
/root/myup.sh 1 0
else
echo -n "3,升级失败！文件校验错误！">/tmp/checkinfo
fi
else
echo -n "3,升级失败！文件下载失败！">/tmp/checkinfo
fi
rm -f /tmp/sysupgrade.bin




