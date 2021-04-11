
if [ -f /tmp/updateroute.lock ] ;then
echo "更新失败！进程冲突，请稍后更新！"
exit
fi

touch /tmp/updateroute.lock

wget -q --timeout=60 -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/china_ssr.txt
wget_ok=$?
icount=`cat /tmp/china_ssr.txt | wc -l`
if [ "$wget_ok" != "0" -o $icount == 0 ]; then
wget -q --timeout=60 http://down.iytc.net/tools/china_ssr.txt -O /tmp/china_ssr.txt
 if [ "$?" != "0" ]; then
 echo "下载失败！请检查网络连接是否正确！"
 rm -f /tmp/china_ssr.txt
 rm -f /tmp/updateroute.lock
 exit
 fi
fi

icount=`cat /tmp/china_ssr.txt | wc -l`
if [ $icount -gt 4000 ]; then
oldcount=`cat /etc/ignore.list | wc -l`
 if [ $icount -ne $oldcount ]; then
  cp -f /tmp/china_ssr.txt /etc/ignore.list
  echo "更新成功！更新后网段数目为："$icount"条"
 else
  echo "当前数据为最新数据，无需更新！"
 fi
else
echo "更新失败！请检查网络连接是否正确！"
fi

rm -f /tmp/china_ssr.txt
rm -f /tmp/updateroute.lock

