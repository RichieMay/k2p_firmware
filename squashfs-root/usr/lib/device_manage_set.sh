#!/bin/sh
######################################################################
# Copyright (C) 2017. Shanghai Feixun Communication Co.,Ltd.
#
# DISCREPTION   : 终端管理规则配置函数
# AUTHOR        : cong.he <cong.he@phicomm.com.cn>
# CREATED DATE  : 2017-04-28
# MODIFIED DATE :
######################################################################

#set -xv
#set -e

. /lib/functions.sh

CONFIG=device_manage

rate_limit_set() {
	local ip="$1"
	local src_dst="$2"
	local rate="$3"
	local rate_old="$4"

	if [ $rate_old -gt 0 ]; then
		iptables -t mangle -w -D limit_chain --$src_dst $ip -m hashlimit --hashlimit-name ${src_dst}_$section_name \
			--hashlimit ${rate_old}kb/s --hashlimit-burst ${rate_old}kb/s --hashlimit-mode ${src_dst}ip -j RETURN >/dev/null 2>&1
		iptables -t mangle -w -D limit_chain --$src_dst $ip -j DROP >/dev/null 2>&1
	fi

	if [ $rate -gt 0 ]; then
		iptables -t mangle -w -A limit_chain --$src_dst $ip -m hashlimit --hashlimit-name ${src_dst}_$section_name \
			--hashlimit ${rate}kb/s --hashlimit-burst ${rate}kb/s --hashlimit-mode ${src_dst}ip -j RETURN >/dev/null 2>&1
		iptables -t mangle -w -A limit_chain --$src_dst $ip -j DROP >/dev/null 2>&1
	fi
}


policy_init() {
	white_list_status=`uci get white_list.comm_info.enable`
	[ $white_list_status -eq 1 ] && return 0

	local section_iface=$1
	local device ifname
	config_get device "$section_iface" device
	config_get ifname "$section_iface" ifname
	uci set wireless.$device.ac_policy=2
	iwpriv $ifname set AccessPolicy=2
	uci commit wireless
}

entry_set() {
	local section_iface=$1
	local add_del=$2
	local device ifname

	white_list_status=`uci get white_list.comm_info.enable`
	if [ $white_list_status -eq 1 ]; then
		if [ "$add_del" = "add" ]; then
			/usr/bin/white_list_set del_wl "$MAC"
		fi
		return 0
	fi

	config_get device "$section_iface" device
	config_get ifname "$section_iface" ifname
	if [ "$add_del" = "add" ]; then
		iwpriv $ifname set ACLAddEntry="$MAC"
		uci del_list wireless.${device}.ctrl_list="$MAC"
		uci add_list wireless.${device}.ctrl_list="$MAC"
	elif [ "$add_del" = "del" ]; then
		iwpriv $ifname set ACLDelEntry="$MAC"
		uci del_list wireless.${device}.ctrl_list="$MAC"
	fi
	uci commit wireless
}

block_user_set() {
	local if_type="$1"
	local block_user="$2"
	local block_user_old="$3"
	config_load wireless
	if [ $block_user_old -ne 0 ]; then
		if [ "$if_type" = "0" ]; then
			iptables -t mangle -w -D PREROUTING -m mac --mac-source $MAC -j DROP
			iptables -t mangle -w -D PREROUTING -m mac --mac-source $MAC -j H2S >/dev/null 2>&1
		else
			config_foreach entry_set wifi-iface "del"
		fi
	fi
	if [ $block_user -ne 0 ]; then
		if [ "$if_type" = "0" ]; then
			iptables -t mangle -w -I PREROUTING -m mac --mac-source $MAC -j DROP
			iptables -t mangle -w -I PREROUTING 1 -m mac --mac-source $MAC -j H2S >/dev/null 2>&1
		else
			config_foreach entry_set wifi-iface "add"
		fi
	fi
}



hwnat_restart() {
	hwnat-disable.sh
	hwnat-enable.sh
}

change_nat_mode() {
	mode=$1
	ip=$2
	if [ $mode == "swnat" ]; then
		iptables -t mangle -w -D limit_chain -s $ip -j H2S >/dev/null 2>&1
		iptables -t mangle -w -D limit_chain -d $ip -j H2S >/dev/null 2>&1
		iptables -t mangle -w -I limit_chain 1 -s $ip -j H2S >/dev/null 2>&1
		iptables -t mangle -w -I limit_chain 1 -d $ip -j H2S >/dev/null 2>&1
		hwnat -A del $ip 1
		hwnat -A del $ip 2
		uci set $CONFIG.$section_name.nat_mode="swnat"
		uci commit $CONFIG
	elif [ $mode == "hwnat" ]; then
		count=`hwnat -A dump | wc -l`
		if [ $count -lt 65 ]; then
			iptables -t mangle -w -D limit_chain -s $ip -j H2S >/dev/null 2>&1
			iptables -t mangle -w -D limit_chain -d $ip -j H2S >/dev/null 2>&1
			hwnat -A add $ip 1
			hwnat -A add $ip 2
			uci set $CONFIG.$section_name.nat_mode="hwnat"
			uci commit $CONFIG
		else
			iptables -t mangle -w -D limit_chain -s $ip -j H2S >/dev/null 2>&1
			iptables -t mangle -w -D limit_chain -d $ip -j H2S >/dev/null 2>&1
			iptables -t mangle -w -I limit_chain 1 -s $ip -j H2S >/dev/null 2>&1
			iptables -t mangle -w -I limit_chain 1 -d $ip -j H2S >/dev/null 2>&1
			hwnat -A del $ip 1
			hwnat -A del $ip 2
			uci set $CONFIG.$section_name.nat_mode="swnat"
			uci commit $CONFIG
		fi
	fi
}

switch_nat_mode() {
	local ip=$1
	local rx_rate=$2
	local tx_rate=$3
	local rx_rate_old=$4
	local tx_rate_old=$5
	local action=$6
	local rip=${ip//./_}
	local section_name=$7
	local if_type=$8

	if [ $action == "PAGE" ]; then
		#模式改变时才需要切换
		#1.必须是有线接口，才需要进行模式切换
		if [ $if_type == 0 ] ; then
			if [ $rx_rate -ne 0  -o $tx_rate -ne 0 ] && [ $rx_rate_old -eq 0 -a $tx_rate_old -eq 0 ]; then
				change_nat_mode "swnat" $ip
			elif [ $rx_rate -eq 0  -a $tx_rate -eq 0 ] && [ $rx_rate_old -ne 0 -o $tx_rate_old -ne 0 ]; then
				change_nat_mode "hwnat" $ip
			fi
		fi
	fi

	if [ "$action" = "ONLINE" ]; then
		##上线时根据限速值进行初始化转发模式
		##上线时有线为hwnat,无线为swnat
		if [ $if_type != 0 ] ; then
			change_nat_mode "swnat" $ip
		else
			if [ $rx_rate != 0 ] || [ $tx_rate != 0 ] ; then
				change_nat_mode "swnat" $ip
			elif [ $rx_rate == 0 ] && [ $tx_rate == 0 ]; then
				change_nat_mode "hwnat" $ip
			fi
		fi
	elif [ "$action" = "OFFLINE" ]; then
		nat_mode=$(uci get $CONFIG.$section_name.nat_mode)
		##下线时根据转发模式释放规则
		if [ $nat_mode == "swnat" ]; then
			iptables -t mangle -w -D limit_chain -s $ip -j H2S >/dev/null 2>&1
			iptables -t mangle -w -D limit_chain -d $ip -j H2S >/dev/null 2>&1
		elif [ $nat_mode == "hwnat" ]; then
			hwnat -A del $ip 1
			hwnat -A del $ip 2
		fi
	fi
	hwnat -A unbind_all
}

