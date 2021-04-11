local err = require("luci.phicomm.error")
local device = require("luci.controller.admin.device")
local cursor = require("luci.model.uci").cursor()
local NETWORK_RELOAD_TIME = cursor:get("dev_feature", "time", "network_restart")

module("luci.data.network_plt", package.seeall)

function index()

end

function apply_network_config_plt(para, method, result)
	local errcode, welcome = device.get_welcome_config()
	local guide = welcome.guide
	local ret = {wait_time = 2}
	local cursor = require("luci.model.uci").cursor()
	if guide == "0" then
		cursor:apply("network", false, true)
		ret.wait_time = NETWORK_RELOAD_TIME
	end
	return err.E_NONE, ret
end

function apply_network_config_wan_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local errcode, welcome = device.get_welcome_config()
	local guide = welcome.guide

	if nil ~= web_para.protocol and "" ~= web_para.protocol then
		cursor:set("network", "wan", "proto", web_para.protocol)
	end

	if nil ~= web_para.clone_mode and "" ~= web_para.clone_mode then
		cursor:set("network", "wan", "macoperate", tostring(tonumber(web_para.clone_mode)+1))
	end

	local clone_mode = diff_para.clone_mode or souce_data.clone_mode
	if clone_mode == "0" then --not clone

		if nil ~= web_para.source_mac and "" ~= web_para.source_mac then
			cursor:set("network", "wan", "macaddr", web_para.source_mac)
		end

		cursor:set("network", "wan", "ignore", "1")
	elseif clone_mode == "1" then --clone_mode

		if nil ~= web_para.mac and "" ~= web_para.mac then
			cursor:set("network", "wan", "mac_addr", web_para.mac)
		end

		cursor:set("network", "wan", "ignore", "0")
	else --nil
		cursor:set("network", "wan", "ignore", "1")
	end

	if guide == "0" then
		--下面的if判断是为了防止H5页面切换为DHCP时不执行apply_network_config_dhcp函数
		--MTU如果上一次是DHCP和STATIC则保留原值,PPPOE则恢复成初始值1500
		--DNS保留PC页面对DHCP的上一次设定
		if web_para.protocol == "dhcp" then
			local dns_mode = cursor:get("network", "wan", "dhcp_dns_mode")
			if dns_mode == "0" then
				cursor:delete("network", "wan", "dns1")
				cursor:delete("network", "wan", "dns2")
				cursor:delete("network", "wan", "dns")
				cursor:set("network", "wan", "peerdns", "1")
			else
				--dns字段可能因pppoe关闭手动配置dns而删除
				local dns1 = cursor:get("network", "wan", "dns1")
				local dns2 = cursor:get("network", "wan", "dns2") or ""
				local dns = dns1 .. " " .. dns2
				cursor:set("network", "wan", "dns", dns)
				cursor:set("network", "wan", "peerdns", "0")
			end

			local ignore_change = cursor:get("network", "wan", "ignore_mtu_change_pppoe")
			if ignore_change == "1" then
				cursor:set("network", "wan", "mtu", "1500")
				cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")
			end
		end

		--删除vpn section
		os.execute("uci del network.vpn && uci commit network")
		os.execute("/etc/init.d/xl2tpd stop")
	end

	cursor:save("network")
	cursor:commit("network")

	return err.E_NONE, {wait_time = 2}
end

function network_reloeded(msg)
	if not msg or not msg.network or not msg.network.wan then
		return false
	end

	return msg.network.wan["_applied"]
end

function apply_network_config_static_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	--local errcode, welcome = device.get_welcome_config()
	--local guide = welcome.guide
	local k, v
	local map = {
		ip = "ipaddr",
		netmask = "netmask",
		gateway = "gateway",
		mtu = "mtu",
		dns_pri = "static_dns1",
		dns_sec = "static_dns2"
		}
	for k, v in pairs(web_para) do
		if nil ~= map[k] then
			cursor:set("network", "wan", map[k], v)
		end
	end

	local dns_pri = diff_para.dns_pri or souce_data.dns_pri
	local dns_sec = diff_para.dns_sec or souce_data.dns_sec
	local dns = dns_pri
	if nil ~= dns_sec and "" ~= dns_sec then
		dns = dns .. " " .. dns_sec
	end
	cursor:set("network", "wan", "dns", dns)
	cursor:set("network", "wan", "peerdns", "0")
	cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")

	--删除vpn section
	os.execute("uci del network.vpn")

	cursor:save("network")
	cursor:commit("network")
	os.execute("/etc/init.d/xl2tpd stop")
--[[
	if guide == "0" then
		if network_reloeded(message) then
			return err.E_NONE, {wait_time = 2}
		else
			cursor:apply("network", false, true)
			return err.E_NONE, {wait_time = NETWORK_RELOAD_TIME}
		end
	else

		--在快速向导中只保存设置,在最后一步无线设置中生效
		return err.E_NONE, {wait_time = 2}
	end
	]]--
	return err.E_NONE, {wait_time = 2}
end

function apply_network_config_dhcp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	--local errcode, welcome = device.get_welcome_config()
	--local guide = welcome.guide

	local k, v
	local map = {
		mtu = "mtu",
		dns_pri = "dns1",
		dns_sec = "dns2"
	}

	for k, v in pairs(web_para) do
		if nil ~= map[k] then
			cursor:set("network", "wan", map[k], v)
		end
	end

	cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")

	local dns_mode = diff_para.dns_mode or souce_data.dns_mode
	if dns_mode == "1" then
		cursor:set("network", "wan", "peerdns", "0")
		cursor:set("network", "wan", "dhcp_dns_mode", "1")

		if nil ~= web_para.dns_pri and "" ~= web_para.dns_pri then
			cursor:set("network", "wan", "dns", web_para.dns_pri .. " " ..  web_para.dns_sec)
		end
	else
		cursor:delete("network", "wan", "dns1")
		cursor:delete("network", "wan", "dns2")
		cursor:delete("network", "wan", "dns")

		cursor:set("network", "wan", "peerdns", "1")
		cursor:set("network", "wan", "dhcp_dns_mode", "0")
	end

	--删除vpn section
	os.execute("uci del network.vpn")

	cursor:save("network")
	cursor:commit("network")
	os.execute("/etc/init.d/xl2tpd stop")
--[[
	if guide == "0" then
		if network_reloeded(message) then
			return err.E_NONE, {wait_time = 2}
		else
			cursor:apply("network", false, true)
			return err.E_NONE, {wait_time = NETWORK_RELOAD_TIME}
		end
	else

		--在快速向导中只保存设置,在最后一步无线设置中生效
		return err.E_NONE, {wait_time = 2}
	end
	]]--
	return err.E_NONE, {wait_time = 2}
end

function apply_network_config_pppoe_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	--local errcode, welcome = device.get_welcome_config()
	--local guide = welcome.guide
	local k, v
	local map = {
		username = "username",
		password = "password",
		dial_mode = "DiaMode",
		server = "service",
		dns_pri = "pppoedns1",
		dns_sec = "pppoedns2"
	}

	for k, v in pairs(web_para) do
		if nil ~= map[k] then
			cursor:set("network", "wan", map[k], v)
		end
	end

	if  nil ~= web_para.mtu and "" ~= web_para.mtu then
		cursor:set("network", "wan", "mtu", tostring(tonumber(web_para.mtu)+8))
	else
		cursor:set("network", "wan", "mtu", "1488")
	end
	cursor:set("network", "wan", "ignore_mtu_change_pppoe", "1")

	local dns_mode = diff_para.dns_mode or souce_data.dns_mode
	if dns_mode == "1" then
		cursor:set("network", "wan", "peerdns", "0")
		cursor:set("network", "wan", "pppoe_dns_mode", "1")

		if nil ~= web_para.dns_pri and "" ~= web_para.dns_pri then
			cursor:set("network", "wan", "dns", web_para.dns_pri .. " " ..  web_para.dns_sec)
		end
	else
		cursor:delete("network", "wan", "pppoedns1")
		cursor:delete("network", "wan", "pppoedns2")
		cursor:delete("network", "wan", "dns")

		cursor:set("network", "wan", "peerdns", "1")
		cursor:set("network", "wan", "pppoe_dns_mode", "0")
	end

	--删除vpn section
	os.execute("uci del network.vpn")

	cursor:save("network")
	cursor:commit("network")
	os.execute("/etc/init.d/xl2tpd stop")
--[[
	if guide == "0" then
		if network_reloeded(message) then
			return err.E_NONE, {wait_time = 2}
		else
			cursor:apply("network", false, true)
			return err.E_NONE, {wait_time = NETWORK_RELOAD_TIME}
		end
	else

		--在快速向导中只保存设置,在最后一步无线设置中生效
		return err.E_NONE, {wait_time = 2}
	end
	]]--
	return err.E_NONE, {wait_time = 2}
end

function apply_network_config_pptp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	--TO DO
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local errcode, welcome = device.get_welcome_config()
	local guide = welcome.guide
	--先删除vpn section
	os.execute("uci del network.vpn && uci commit netowrk")
	--增加vpn section
	cursor:section("network", "interface", "vpn")
	cursor:save("network")
	cursor:commit("network")

	os.execute("/etc/init.d/xl2tpd stop")
	--vpn配置项
	local server = web_para.server
	local username = web_para.username
	local password = web_para.password
	local mtu = web_para.mtu or "1420"

	cursor:set("network", "vpn", "proto", "pptp")
	cursor:set("network", "vpn", "DiaMode", "0")
	cursor:set("network", "vpn", "server", server)
	cursor:set("network", "vpn", "username", username)
	cursor:set("network", "vpn", "password", password)
	cursor:set("network", "vpn", "mtu", mtu)

	local ip_proto = web_para.ip_protocol  --0:dhcp  1:static
	local dns_mode = web_para.dns_mode or "0"-- 0:无dns  1:有dns
	if "0" == ip_proto then --dhcp
		local k, v
		local map = {
			dns_pri = "dns1",
			dns_sec = "dns2"
		}

		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("network", "wan", map[k], v)
			end
		end

		cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")
		cursor:set("network", "wan", "proto", "dhcp")
		if dns_mode == "1" then
			cursor:set("network", "wan", "peerdns", "0")
			cursor:set("network", "wan", "dhcp_dns_mode", "1")

			if nil ~= web_para.dns_pri and "" ~= web_para.dns_pri then
				cursor:set("network", "wan", "dns", web_para.dns_pri .. " " ..  web_para.dns_sec)
			end
		else
			cursor:delete("network", "wan", "dns1")
			cursor:delete("network", "wan", "dns2")
			cursor:delete("network", "wan", "dns")

			cursor:set("network", "wan", "peerdns", "1")
			cursor:set("network", "wan", "dhcp_dns_mode", "0")
		end

		cursor:save("network")
		cursor:commit("network")
	else --static
		local k, v
		local map = {
			ip = "ipaddr",
			netmask = "netmask",
			gateway = "gateway",
			dns_pri = "static_dns1",
			dns_sec = "static_dns2"
		}
		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("network", "wan", map[k], v)
			end
		end

		local dns_pri = web_para.dns_pri
		local dns_sec = web_para.dns_sec
		local dns = dns_pri
		if nil ~= dns_sec and "" ~= dns_sec then
			dns = dns .. " " .. dns_sec
		end
		cursor:set("network", "wan", "dns", dns)
		cursor:set("network", "wan", "proto", "static")
		cursor:set("network", "wan", "peerdns", "0")
		cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")

		cursor:save("network")
		cursor:commit("network")
	end
--[[
	if guide == "0" then
		if network_reloeded(message) then
			return err.E_NONE, {wait_time = 2}
		else
			cursor:apply("network", false, true)
			return err.E_NONE, {wait_time = NETWORK_RELOAD_TIME}
		end
	else
		--在快速向导中只保存设置,在最后一步无线设置中生效
		return err.E_NONE, {wait_time = 2}
	end
]]--
	return err.E_NONE, {wait_time = 2}
end

function apply_network_config_l2tp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	--TO DO
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local errcode, welcome = device.get_welcome_config()
	local guide = welcome.guide
	--先删除vpn section
	os.execute("uci del network.vpn && uci commit netowrk")
	--增加vpn section
	cursor:section("network", "interface", "vpn")
	cursor:save("network")
	cursor:commit("network")
	--vpn配置项
	local server = web_para.server
	local username = web_para.username
	local password = web_para.password
	local mtu = web_para.mtu or "1460"

	cursor:set("network", "vpn", "proto", "l2tp")
	cursor:set("network", "vpn", "DiaMode", "0")
	cursor:set("network", "vpn", "server", server)
	cursor:set("network", "vpn", "username", username)
	cursor:set("network", "vpn", "password", password)
	cursor:set("network", "vpn", "mtu", mtu)

	local ip_proto = web_para.ip_protocol  --0:dhcp  1:static
	local dns_mode = web_para.dns_mode or "0" -- 0:无dns  1:有dns
	if "0" == ip_proto then --dhcp
		local k, v
		local map = {
			dns_pri = "dns1",
			dns_sec = "dns2"
		}

		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("network", "wan", map[k], v)
			end
		end

		cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")
		cursor:set("network", "wan", "proto", "dhcp")
		if dns_mode == "1" then
			cursor:set("network", "wan", "peerdns", "0")
			cursor:set("network", "wan", "dhcp_dns_mode", "1")

			if nil ~= web_para.dns_pri and "" ~= web_para.dns_pri then
				cursor:set("network", "wan", "dns", web_para.dns_pri .. " " ..  web_para.dns_sec)
			end
		else
			cursor:delete("network", "wan", "dns1")
			cursor:delete("network", "wan", "dns2")
			cursor:delete("network", "wan", "dns")

			cursor:set("network", "wan", "peerdns", "1")
			cursor:set("network", "wan", "dhcp_dns_mode", "0")
		end

		cursor:save("network")
		cursor:commit("network")
	else --static
		local k, v
		local map = {
			ip = "ipaddr",
			netmask = "netmask",
			gateway = "gateway",
			dns_pri = "static_dns1",
			dns_sec = "static_dns2"
		}
		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("network", "wan", map[k], v)
			end
		end

		local dns_pri = web_para.dns_pri
		local dns_sec = web_para.dns_sec
		local dns = dns_pri
		if nil ~= dns_sec and "" ~= dns_sec then
			dns = dns .. " " .. dns_sec
		end
		cursor:set("network", "wan", "dns", dns)
		cursor:set("network", "wan", "proto", "static")
		cursor:set("network", "wan", "peerdns", "0")
		cursor:set("network", "wan", "ignore_mtu_change_pppoe", "0")

		cursor:save("network")
		cursor:commit("network")
	end
--[[
	if guide == "0" then
		if network_reloeded(message) then
			return err.E_NONE, {wait_time = 2}
		else
			cursor:apply("network", false, true)
			return err.E_NONE, {wait_time = NETWORK_RELOAD_TIME}
		end
	else
		--在快速向导中只保存设置,在最后一步无线设置中生效
		return err.E_NONE, {wait_time = 2}
	end
]]--
	return err.E_NONE, {wait_time = 2}
end

function disconnect_dhcp(  )
	local sys = require("luci.sys")
	local wan_ifname = cursor:get("network","wan","ifname")
	local cmd = string.format("cat /var/run/udhcpc-%s.pid",wan_ifname)
	local pid = sys.exec(cmd)
	cmd = string.format("kill -s USR2 %s", pid)
	sys.call(cmd)
end

function connect_dhcp(  )
	local sys = require("luci.sys")
	local wan_ifname = cursor:get("network","wan","ifname")
	local cmd = string.format("cat /var/run/udhcpc-%s.pid", wan_ifname)
	local pid = sys.exec(cmd)
	cmd = string.format("kill -s USR1 %s", pid)
	sys.call(cmd)
end

function disconnect_pppoe(  )
	-- TODO, send packet
	local sys = require("luci.sys")
	local wan_ifname = cursor:get("network","wan","ifname")
	local cmd = string.format("ifconfig %s down", wan_ifname)
	sys.call(cmd)

end

function connection_pppoe(  )
	-- TODO. send paacket
	local sys = require("luci.sys")
	local wan_ifname = cursor:get("network","wan","ifname")
	local cmd = string.format("ifconfig %s up", wan_ifname)
	sys.call(cmd)
end

function apply_network_config_connection_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	if nil ~= web_para.action and "" ~= web_para.action then
		local proto = cursor:get("network", "wan", "proto")
		if proto == "dhcp" then
			if tostring(web_para.action) == "1" then
				connect_dhcp()
			else
				disconnect_dhcp()
			end
		elseif proto == "pppoe" then
			if tostring(web_para.action) == "1" then
				connection_pppoe()
			else
				disconnect_pppoe()
			end
		else
			--not support for static, yet
		end
	end
	return err.E_NONE, {wait_time = 2}
end