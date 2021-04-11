
if [ -f /tmp/updategfw.lock ] ;then
echo "更新失败！进程冲突，请稍后更新！"
exit
fi
touch /tmp/updategfw.lock

wget -q --timeout=60 --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt -O /tmp/gfw.b64
wget_ok=$?
icount=`cat /tmp/gfw.b64 | wc -l`
if [ "$wget_ok" != "0" -o $icount == 0 ]; then
wget -q --timeout=60 http://down.iytc.net/tools/list.b64 -O /tmp/gfw.b64
 if [ "$?" != "0" ]; then
 echo "下载失败！请检查网络连接是否正确！"
 rm -f /tmp/gfw.b64
 rm -f /tmp/updategfw.lock
 exit
 fi
fi

generate_china_banned()
{
	
		cat $1 | base64 -d > /tmp/gfwlist.txt
		sed -i '/@@/d' /tmp/gfwlist.txt



	cat /tmp/gfwlist.txt | sort -u |
		sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' |
		sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /jlike\.com/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d' |
		sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
		grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##' | sort -u |
		awk '
BEGIN { prev = "________"; }  {
	cur = $0;
	if (index(cur, prev) == 1 && substr(cur, 1 + length(prev) ,1) == ".") {
	} else {
		print cur;
		prev = cur;
	}
}' | sort -u

}

generate_china_banned /tmp/gfw.b64 > /tmp/gfw.txt

datestr=`date`
echo -e "# gfw list ipset rules for dnsmasq and pdnsd mode\n# updated on $datestr\n#">/tmp/gfw_list.conf
sed '/.*/s/.*/server=\/\.&\/127.0.0.1#5353\nipset=\/\.&\/ssr/' /tmp/gfw.txt >>/tmp/gfw_list.conf
echo -e "# gfw list ipset rules for dnsmasq and remote mode\n# updated on $datestr\n#">/tmp/gfw_addr.conf
sed '/.*/s/.*/address=\/\.&\/93.46.8.89/' /tmp/gfw.txt >>/tmp/gfw_addr.conf



icount=`cat /tmp/gfw_addr.conf | wc -l`

if [ $icount -gt 2000 ]; then
oldcount=`cat /etc/dnsmasq.gfw/gfw_addr.conf | wc -l`

 if [ $icount -ne $oldcount ]; then
  cp -f /tmp/gfw_addr.conf /etc/dnsmasq.gfw/gfw_addr.conf
  cp -f /tmp/gfw_list.conf /etc/dnsmasq.ssr/gfw_list.conf
  echo "更新成功！更新后GFW列表数目为："$icount"条"
 else
  echo "当前数据为最新数据，无需更新！"
 fi
else
echo "更新失败！请检查网络连接是否正确！"
fi
rm -f /tmp/gfwlist.txt
rm -f /tmp/gfw.txt
rm -f /tmp/gfw_addr.conf
rm -f /tmp/gfw_list.conf
rm -f /tmp/gfw.b64
rm -f /tmp/updategfw.lock

