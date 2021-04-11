#!/bin/sh

######################################################################
# Copyright (C) 2017. Shanghai Feixun Communication Co.,Ltd.
#
# DISCREPTION   : isp region
# AUTHOR        : zhengbao.ou <zhengbao.ou@phicomm.com.cn>
# CREATED DATE  : 2017-07-18
# MODIFIED DATE :
######################################################################

CHECK_IP_URL="http://ip.cn"
CHECK_ISP_URL="http://ip.taobao.com/service/getIpInfo.php?ip="
CHECK_TIME_INTERVAL=60
CPU_SPEED=880

REGION_SETION_NAME="region"
ISP_SETION_NAME="isp"
ISP_REGION_FILE="/permanent_config/isp_region"

usage()
{
	echo "use: $0"
	echo "	error from $1"
}

ip_index="[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"

#public_ip=`wget -O - $CHECK_IP_URL | grep "IP:" | grep -o "$ip_index"`
public_ip=`wget -T 10 -O - $CHECK_IP_URL | grep "IP:" | grep -o "$ip_index"`

if [ -n "$public_ip" ];then
	usage $CHECK_IP_URL
fi

url=${CHECK_ISP_URL}"$public_ip"

#wget -O $ISP_REGION_FILE $url
wget -T 10 -O $ISP_REGION_FILE $url

#运营商信息
region=`cat $ISP_REGION_FILE | awk -F "region" '{print $2}' | awk -F '"' '{print $3}'`
isp=`cat $ISP_REGION_FILE | awk -F "isp" '{print $2}' | awk -F '"' '{print $3}'`

uci set system.system.$REGION_SETION_NAME=$region
uci set system.system.$ISP_SETION_NAME=$isp

uci commit system
