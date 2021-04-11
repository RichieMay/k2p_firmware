local i=require("luci.phicomm.error")
local e=require("luci.controller.ds")
local a=e.filter_key.validator
local hostname = luci.model.uci.cursor():get_first("system", "system", "hostname")

module("luci.data.kms",package.seeall)

function index()
register_secname_cb("kms","config","check_kms_config","apply_kms_config")
end

function check_kms_config(t,c,l,t,t,t)
return i.E_NONE
end

function apply_kms_config(e,e,e,l,e,e)
local e=require("luci.model.uci").cursor()
e:set("kms","kms","autokms",l.autokms)
e:set("kms","kms","enable",l.enable)

e:commit("kms")

if l.autokms == "1" then
	luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
	luci.sys.call("echo srv-host=_vlmcs._tcp.lan,".. hostname ..".lan,1688,0,100 >> /etc/dnsmasq.conf")
else
	luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
end

if l.enable=="0" then
 luci.sys.call("/etc/init.d/kms disable")
 luci.sys.call("/etc/init.d/kms stop")
else
 luci.sys.call("/etc/init.d/kms enable")
 luci.sys.call("/etc/init.d/kms stop;sleep 1")
 luci.sys.call("/etc/init.d/kms start")
 luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null")
end

return i.E_NONE,{wait_time=2}
end


