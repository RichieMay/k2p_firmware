local i=require("luci.phicomm.error")
local e=require("luci.controller.ds")
local a=e.filter_key.validator

module("luci.data.tools",package.seeall)

function index()
register_secname_cb("tools","config","check_tools_config","apply_tools_config")
end

function check_tools_config(t,c,l,t,t,t)
e.register_secname_filter(c,l,{index={[a]="luci.phicomm.validator.check_num"}})
return i.E_NONE
end

function apply_tools_config(e,e,e,l,e,e)
if l.index==0 then
 if l.value then
  local cronfile = "/etc/crontabs/root" 
  nixio.fs.writefile("/etc/crontabs/root", l.value:gsub("\r\n", "\n"))
  luci.sys.call("/usr/bin/crontab %q" % cronfile)
 end
elseif l.index==1 then
 if l.value then
  nixio.fs.writefile("/etc/rc.local", l.value:gsub("\r\n", "\n"))
 end
elseif l.index==2 then
 if l.value then
  nixio.fs.writefile("/etc/hosts", l.value:gsub("\r\n", "\n"))
 end
elseif l.index==3 then
 if l.value then
  nixio.fs.writefile("/etc/adb/usr.txt", l.value:gsub("\r\n", "\n"))
  luci.sys.call("cat /etc/dnsmasq.conf |grep conf-dir=/etc/adb >/dev/null||echo conf-dir=/etc/adb >> /etc/dnsmasq.conf ")
  luci.sys.call("/etc/init.d/dnsmasq restart")
 end
elseif l.index==4 then
local ee=require("luci.model.uci").cursor()
ee:set("tools","config","ssh_enable",l.value)
ee:set("tools","config","telnet_enable",l.value2)
ee:commit("tools")

 if l.value == "1" then
 luci.sys.call("/etc/init.d/dropbear restart")
 else
 luci.sys.call("/etc/init.d/dropbear stop")
 end
 if l.value2 == "1" then
 luci.sys.call("killall telnetd;sleep 2;/usr/sbin/telnetd -l /bin/login.sh &")
 else
 luci.sys.call("killall telnetd")
 end

elseif l.index==5 then
local mver=luci.util.exec("uci get version.num.ver") or ""
local runcmd="echo -n `curl http://iytc.net/ver.php?softname=k2pmtk\\&ver=" .. mver .. "` > /tmp/checkinfo"
 luci.sys.call(runcmd)
elseif l.index==6 then
 luci.sys.call("/root/autoup.sh &")
end

return i.E_NONE,{wait_time=1}
end


