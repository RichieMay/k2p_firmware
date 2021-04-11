local i=require("luci.phicomm.error")
local e=require("luci.controller.ds")
local a=e.filter_key.validator
local plmu = require("luci.model.uci").cursor()

module("luci.data.myset",package.seeall)

function index()
register_secname_cb("myset","config","check_myset_config","apply_myset_config")
end

function check_myset_config(t,c,l,t,t,t)
return i.E_NONE
end

function apply_myset_config(e,e,e,l,e,e)


if l.type == "reconnect" then
 if l.protocol == "pppoe" then
	luci.sys.call("/sbin/ifup wan")
       luci.sys.call("sleep 5 > /dev/null 2>&1")
 elseif l.protocol == "dhcp" then
            luci.sys.call("killall -SIGUSR1 udhcpc > /dev/null 2>&1")
            local ifname = plmu:get("network", "wan", "ifname")
            if ifname == "apcli0" or ifname == "apclix0" then
                luci.sys.call("sleep 7 > /dev/null 2>&1")
            else 
                luci.sys.call("sleep 2 > /dev/null 2>&1")
            end
  end
end



return i.E_NONE,{wait_time=2}
end



