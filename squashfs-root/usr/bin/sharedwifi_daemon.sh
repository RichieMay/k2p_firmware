#!/bin/sh

interface="`cfg_phic -g wifi ifname sharewifi ifname`"
wifidog_enable=`/sbin/uci get sharedwifi.wifidog.enable`
wifidog_exist=`/bin/ps | /bin/grep wifidog | /bin/grep -v grep`
wifidog_status=`/sbin/uci get sharedwifi.wifidog.status`
sharewifi_exist=`/sbin/ifconfig  | /bin/grep $interface`
reconnection=`/sbin/uci get sharedwifi.wifidog.reconnection`
scheduleClose=`/sbin/uci get sharedwifi.wifidog.scheduleClose`
cur_time=`/bin/date +%s`

# logger -t DEBUG "enable:$wifidog_enable, status:$wifidog_status, exist:$wifidog_exist."
# logger -t DEBUG "reconnection:$reconnection, cur_time:$cur_time, scheduleClose:$scheduleClose."

if [ $wifidog_enable = '1' ] && [ "$wifidog_status" != 'fail' ] && [ -z "$wifidog_exist" ]; then
	logger -t DEBUG "start wifidog...."
	/etc/init.d/sharedwifi start
elif [ $wifidog_enable = '0' ] && [ -n "$sharewifi_exist" ]; then
	logger -t DEBUG "ifconfig $interface donw...."
	/etc/init.d/sharedwifi stop

	/usr/bin/cfg_phic -s ifname sharewifi disabled 0
	/sbin/ifconfig $interface down
fi

if [ $wifidog_enable = '1' ] && [ "$wifidog_status" = 'fail' ] && [ -n "$sharewifi_exist" ]; then
	/usr/bin/cfg_phic -s ifname sharewifi disabled 1
	/sbin/ifconfig $interface down
fi

if [ $wifidog_enable = '1' ] && [ $reconnection != '0' ] && [ $cur_time -ge $reconnection ]; then
	logger -t DEBUG "reconnection wifidog server...."
	/sbin/uci set sharedwifi.wifidog.reconnection=0
	/etc/init.d/sharedwifi restart
fi

# check Whether blocking of the wifidog web server
recv_q=`/bin/netstat -ntl | /bin/grep \`/sbin/uci get network.lan.ipaddr\`:2060 | /usr/bin/awk '{print $2}'`
if [ $wifidog_enable = '1' ] && [ "$wifidog_status" = 'normal' ] && [ $recv_q -gt 0 ]; then
	sleep 60
	recv_q=`/bin/netstat -ntl | /bin/grep \`/sbin/uci get network.lan.ipaddr\`:2060 | /usr/bin/awk '{print $2}'`
	if [ $wifidog_enable = '1' ] && [ "$wifidog_status" = 'normal' ] && [ $recv_q -gt 0 ]; then
		logger -t DEBUG "server blocking , restart ...."
		/etc/init.d/sharedwifi restart
	fi
fi

if [ $wifidog_enable = '1' ] && [ "$scheduleClose" = '1' ]; then
	killall -SIGUSR1 wifidog
	sleep 1
	if [ ! -e /tmp/wifidog_auth_count ]; then
		logger -t DEBUG "scheduleClose wifidog...."
		/sbin/uci set sharedwifi.wifidog.enable=0
		/sbin/uci set sharedwifi.wifidog.scheduleClose=0
		/sbin/uci commit
		/etc/init.d/sharedwifi stop
		/sbin/ifconfig $interface down
		old_sleep_timer=`/sbin/uci get sharedwifi.wifidog.old_sleep_timer`
		if [ $old_sleep_timer = '1' ]; then
			/sbin/uci set sleep_timer.timer.enable=1
			/sbin/uci commit
			/usr/bin/sleep_timer load &
		fi
	fi
fi

echo "end sharedwifi daemon...."
