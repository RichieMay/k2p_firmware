#!/bin/sh

WIFI_TIME=30
SLEEP_TIME=30

sleep_status=`uci get sleep_timer.timer.lastSleepStatus`
upgrade_hour=`uci get system.upgrade.start_hour`
upgrade_minute=`uci get system.upgrade.start_minute`
upgrade_enable=`uci get system.upgrade.mode`
sleep_start=`uci get sleep_timer.timer.stopTime`
sleep_stop=`uci get sleep_timer.timer.startTime`
sleep_enable=`uci get sleep_timer.timer.enable`
wifi_down=`uci get wifi_time_switch.b2d4gAnd5g.downTime`
wifi_up=`uci get wifi_time_switch.b2d4gAnd5g.upTime`
wifi_enable=`uci get wifi_time_switch.b2d4gAnd5g.enable`
guest_down=`uci get wifi_time_switch.guest.downTime`
guest_up=`uci get wifi_time_switch.guest.upTime`
guest_enalble=`uci get wifi_time_switch.guest.enable`
reboot_hour=`uci get timereboot.timereboot.hour`
reboot_minute=`uci get timereboot.timereboot.minute`

upgrade_time=$upgrade_minute" "$upgrade_hour
reboot_time=$reboot_minute" "$reboot_hour


do_wifi_down() {
	if [ "$wifi_down" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$wifi_down" = "$sleep_stop" -a "$sleep_enable" = "1" ];then
		sleep $SLEEP_TIME
	fi
	
	/usr/bin/wifi_time_switch b2d4gAnd5g down &
}

do_wifi_up() {
	if [ "$wifi_up" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$wifi_up" = "$sleep_stop" -a "$sleep_enable" = "1" ];then
		sleep $SLEEP_TIME
	fi
	
	/usr/bin/wifi_time_switch b2d4gAnd5g up &
}

do_guest_down() {
	if [ "$guest_down" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$guest_down" = "$sleep_stop" -a "$sleep_enable" = "1" ];then
		sleep $SLEEP_TIME
	fi
	
	/usr/bin/wifi_time_switch guest down &
}

do_guest_up() {
	if [ "$guest_up" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$guest_up" = "$sleep_stop" -a "$sleep_enable" = "1" ];then
		sleep $SLEEP_TIME
	fi
	
	/usr/bin/wifi_time_switch guest up &
}

do_upgrade() {
	if [ "$sleep_status" = "1" ]; then
		exit
	fi

	if [ "$upgrade_time" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$upgrade_time" = "$sleep_stop" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	fi

	if [ "$upgrade_time" = "$wifi_down" -a "$wifi_enable" = "1" ]; then
		sleep $WIFI_TIME
	elif [ "$upgrade_time" = "$wifi_up" -a "$wifi_enable" = "1" ]; then
		sleep $WIFI_TIME
	fi

	if [ "$upgrade_time" = "$guest_down" -a "$guest_enable" = "1" ]; then
		sleep $WIFI_TIME
	elif [ "$upgrade_time" = "$guest_up" -a "$guest_enable" = "1" ]; then
		sleep $WIFI_TIME
	fi
	
	regular_task &
}

do_reboot() {
	if [ "$sleep_status" = "1" ]; then
		exit
	fi

	if [ "$reboot_time" = "$upgrade_time" -a "$upgrade_enable" = "1" ]; then
		exit
	fi

	if [ "$reboot_time" = "$sleep_start" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	elif [ "$reboot_time" = "$sleep_stop" -a "$sleep_enable" = "1" ]; then
		sleep $SLEEP_TIME
	fi

	if [ "$reboot_time" = "$wifi_down" -a "$wifi_enable" = "1" ]; then
		sleep $WIFI_TIME
	elif [ "$reboot_time" = "$wifi_up" -a "$wifi_enable" = "1" ]; then
		sleep $WIFI_TIME
	fi

	if [ "$reboot_time" = "$guest_down" -a "$guest_enable" = "1" ]; then
		sleep $WIFI_TIME
	elif [ "$reboot_time" = "$guest_up" -a "$guest_enable" = "1" ]; then
		sleep $WIFI_TIME
	fi
	
	reboot -f
}


case $1 in
	sleep)
		if [ $2 = "start" ]; then
			/usr/bin/sleep_timer sleep &
		elif [ $2 = "stop" ]; then
			/usr/bin/sleep_timer wakeup &
		fi
	;;
	b2d4gAnd5g)
		if [ $2 = "down" ]; then
			do_wifi_down
		elif [ $2 = "up" ]; then
			do_wifi_up
		fi
	;;
	guest)
		if [ $2 = "down" ]; then
			do_guest_down
		elif [ $2 = "up" ]; then
			do_guest_up
		fi
	;;
	auto_upgrade)
		do_upgrade
	;;
	auto_reboot)
		do_reboot
	;;
esac
