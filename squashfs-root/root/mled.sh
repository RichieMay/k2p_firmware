#!/bin/sh
# gpio c <set_mask> <clr_mask> <blinks>              <first_freq>            <sec_freq>  
#        置位掩码    清位掩码   是否闪烁（1表示闪烁）  亮灯时间（100ms为单位）  灭灯时间（100ms为单位）
# gpio c为长期有效
# gpio l <gpio> <on>                    <off>                  <blinks>       <rests>          <times>  
#        gpio口 亮灯时间（100ms为单位）  灭灯时间（100ms为单位）   闪烁         循环等待时间      循环次数    
#         红 蓝 黄
#GPIO k2 :8  10 11 
#GPIO k2p:13 15 14
#256 1024 2048        3072
#8192 32768 16384     49152
local mode=$1

led_on () {
if [ "$1" = "blue" ] ;then
 gpio l 15 4000 0  0 0 0
elif [ "$1" = "red" ] ;then
 gpio l 13 0 4000 0 0 0 
elif [ "$1" = "yellow" ] ;then
 gpio l 14 4000 0 0 0 0
elif [ "$1" = "orange" ] ;then
 gpio l 13 0 4000 0 0 0 
 gpio l 14 4000 0 0 0 0 
elif [ "$1" = "purple" ] ;then
 gpio l 13 0 4000 0 0 0 
 gpio l 15 4000 0  0 0 0
elif [ "$1" = "green" ] ;then
 gpio l 14 4000 0 0 0 0
 gpio l 15 4000 0  0 0 0
else
 gpio l 13 0 4000 0 0 0 
 gpio l 14 4000 0 0 0 0
 gpio l 15 4000 0  0 0 0
fi
}

led_off () {
gpio l 13 4000 0 0 0 0
gpio l 14 0 4000 0 0 0
gpio l 15 0 4000 0 0 0
}

led_blink () {
led_off
sleep 2
if [ $1 = 0 ] ;then
sleep 1
else
gpio l 15 3 7 0 0 $1
sleep $1
fi
if [ $2 = 0 ] ;then
sleep 1
else
gpio l 14 3 7 0 0 $2  
sleep $2
fi
if [ $3 = 0 ] ;then
sleep 1
else
gpio l 13 3 7 0 0 $3 
sleep $3
fi
led_off
sleep 2

}

led_show () {

while [ 1 ]
do
local ontime=1
local offtime=0
led_off 
sleep $offtime
led_on red
sleep $ontime
led_off 
sleep $offtime
led_on blue
sleep $ontime
led_off 
sleep $offtime
led_on yellow
sleep $ontime
led_off 
sleep $offtime
led_on orange
sleep $ontime
led_off 
sleep $offtime
led_on purple
sleep $ontime
led_off 
sleep $offtime
led_on green
sleep $ontime
led_off 
sleep $offtime
led_on white
sleep $ontime
done
}

led_time() {

while [ 1 ]
#local vhour,vmin,vmin_1,vmin_2
do
vhour=`date |awk '{print $4}'|awk -F ':' '{print $1}'`
[ $vhour -gt 12 ] && let vhour=vhour-12
vmin=`date |awk '{print $4}'|awk -F ':' '{print $2}'`
#echo $vmin
let vmin_1=vmin/10
let vmin_2=vmin%10
led_blink $vhour $vmin_1 $vmin_2
#echo $vhour $vmin_1 $vmin_2
led_on purple
sleep 5

done
}

if [ -z "$mode" -o  "$mode" = "show" ] ;then
led_show
elif [ "$mode" = "time" ] ;then
led_time
else
led_off 
led_on $mode
fi

