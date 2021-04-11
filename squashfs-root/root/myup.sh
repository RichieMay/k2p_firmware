#!/bin/sh
[ -f "/tmp/sysupgrade.bin" ] || return 0
rm -f /tmp/fs
img-dec /tmp/sysupgrade.bin /tmp/fwinfo /tmp/owinfo /tmp/uboot /tmp/fs
[ -f "/tmp/fs" ] || return 0
echo "4,0,50" > /tmp/up_code

if [ "$2" = "1" ]; then
len=`ls -l /tmp/uboot|awk '{print $5}'`
 if [ "$len" = "196608" ]; then
 mtd write /tmp/uboot Bootloader >/tmp/upgrade.log
 fi
fi

if [ "$1" = "1" ]; then
tar czf /tmp/sysupgrade.tgz  /etc/config /etc/dropbear/ /etc/crontabs/ /etc/hosts /etc/inittab /etc/*.user /etc/dogcom.conf /etc/passwd /etc/shadow /etc/rc.local /etc/adb /etc/adbyby*.txt /etc/dnsmasq.ssr/user.txt /etc/ssr_ip /etc/frpc.ini 2>/dev/null
mtd -r -j /tmp/sysupgrade.tgz write /tmp/fs firmware  >/tmp/upgrade.log
else
mtd -r write /tmp/fs firmware  >/tmp/upgrade.log
fi




