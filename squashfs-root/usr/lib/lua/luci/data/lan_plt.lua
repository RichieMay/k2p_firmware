local err = require("luci.phicomm.error")

module("luci.data.lan_plt", package.seeall)

function index()
end

function apply_lan_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local ip = web_para.ip
	local netmask = web_para.netmask or souce_data.netmask
	local gateway = web_para.gateway
	local dnsip = web_para.dnsip 

	--LAN口IP MAC绑定、更新
	local lan_mac = cursor:get("network", "lan", "macaddr")
	local target
	cursor:foreach("dhcp", "host", function(h)
		if h.mac == lan_mac then
			target = h
		end
	end)
	if not target then
		cursor:section("dhcp", "host", nil, {ip = ip, mac = lan_mac})
	else
		target.ip = ip
		cursor:tset("dhcp", target[".name"], target)
	end

	--DHCP 地址池更新
	local bit = require("nixio").bit
	nm3, nm2, nm1, nm0 = string.match(netmask, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
	ip3, ip2, ip1, ip0 = string.match(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
	local pool_start = bit.band(tonumber(nm0), tonumber(ip0)) + 1
	local pool_limit = bit.bxor(tonumber(nm0), 255) - 1
	local pool_end = pool_start + pool_limit -1

	local lan = cursor:get_all("dhcp", "lan")
	if tonumber(lan.start) < pool_start or (tonumber(lan.start) + tonumber(lan.limit) - 1) > pool_end then
		lan.start = pool_start
		lan.limit = pool_limit
	end
	cursor:tset("dhcp", "lan", lan)
	cursor:save("dhcp")
	cursor:commit("dhcp")

	cursor:set("network", "lan", "ipaddr", ip)
	cursor:set("network", "lan", "netmask", netmask)
	cursor:set("network", "lan", "gateway", gateway)
	cursor:set("network", "lan", "dns", dnsip)

	luci.sys.call("sed -i -e 's/\\(.*\\) \\(phicomm.me\\)/%s \\2/' /etc/hosts" % ip)
	luci.sys.call("sed -i -e 's/\\(.*\\) \\(p.to\\)/%s \\2/' /etc/hosts" % ip)
	cursor:save("network")
	cursor:commit("network")
	cursor:apply("network", false, true)

	return err.E_NONE, {wait_time = 35}
end
