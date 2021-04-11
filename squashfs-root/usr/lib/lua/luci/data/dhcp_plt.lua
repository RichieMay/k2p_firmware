local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
module("luci.data.dhcp_plt", package.seeall)

function index()
end

function apply_dhcp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local lan = cursor:get_all("dhcp", "lan")
	local port_num = 53 --DNS port

	local pool_start = tonumber(web_para.pool_start or souce_data.pool_start)
	local pool_end = tonumber(web_para.pool_end or souce_data.pool_end)

	web_para.enable = web_para.enable or souce_data.enable
	lan.dynamicdhcp = web_para.enable
	if web_para.enable == "0" then
		--disable DNS server
		port_num = 0
	end
	cursor:section("dhcp", "dnsmasq", "@dnsmasq[0]", {authoritative = web_para.enable, port = port_num})

	lan.start = pool_start
	if pool_start > pool_end then
		lan.limit = pool_start - pool_end + 1
	else
		lan.limit = pool_end - pool_start + 1
	end

	cursor:tset("dhcp", "lan", lan)
	cursor:save("dhcp")
	cursor:commit("dhcp")
	cursor:apply("dhcp", false, true)


	return err.E_NONE, {wait_time = 3}
end

function apply_bind_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local id = web_para.id
	local mac = web_para.mac
	local macStr = string.gsub(mac, ":", "_")

	local function find_bind_entry(mac)
		local target
		cursor:foreach("dhcp", "host", function(h)
			if h.mac == mac then
				target = h
			end
		end)

		return target
	end

	if ds.METHOD_ADD == method then
		local target = find_bind_entry(mac)
		if target then
			return err.E_DHCPD_CONFLICT_MAC
		else
			if cursor:get("common_host", macStr, "hostname") == nil then
				if web_para.name ~= nil and web_para.name ~= "Unknown" then
					cursor:section("common_host", "host", macStr, {hostname = web_para.name})
					cursor:commit("common_host")
				end
			end

			cursor:section("dhcp", "host", nil, {ip = web_para.ip, mac = web_para.mac})
			cursor:save("dhcp")
			cursor:commit("dhcp")
			--sync with arp table
			luci.sys.exec("busybox arp -s %s %s" % {web_para.ip, web_para.mac})
		end
	elseif ds.METHOD_DELETE == method then
		local target = find_bind_entry(mac)
		if not target then
			-- entry not found
			return err.E_ENTRYNOTEXIST
		else
			cursor:delete("dhcp", target[".name"])
			cursor:save("dhcp")
			cursor:commit("dhcp")
			--sync with arp table
			luci.sys.exec("busybox arp -d %s" % {target.ip})
		end
	elseif ds.METHOD_MODIFY == method then
		local target = find_bind_entry(string.gsub(id, "_", ":"))
		if not target then
			-- entry not found
			return err.E_ENTRYNOTEXIST
		else
			target.ip = web_para.ip
			target.mac = web_para.mac
			--sync with arp table
			luci.sys.exec("busybox arp -d %s" % {target.ip})
			cursor:tset("dhcp", target[".name"], target)
			cursor:save("dhcp")
			cursor:commit("dhcp")
			--sync with arp table
			luci.sys.exec("busybox arp -s %s %s" % {web_para.ip, web_para.mac})

			if cursor:get("common_host", macStr, "hostname") == nil then
				if web_para.name ~= nil and web_para.name ~= "Unknown" then
					cursor:section("common_host", "host", macStr, {hostname = web_para.name})
					cursor:commit("common_host")
				end
			end
		end
	else
		return err.E_INVARG
	end

	-- apply config
	cursor:apply("dhcp", false, true)

	return err.E_NONE, {wait_time = 3}
end
