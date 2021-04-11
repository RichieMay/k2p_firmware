local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.safe_set_plt", package.seeall)

function index()
end

function apply_safe_set_plt(method, uciname, secname, web_para, diff_para, souce_data)
	require ("luci.sys")
	local cursor = require("luci.model.uci").cursor()

	if nil ~= web_para.enable and "" ~= web_para.enable then
		cursor:set("safeset","config","spi_enable",web_para.enable)
	else
		cursor:set("safeset","config","spi_enable","1")
	end

	if web_para.enable == "1" and nil ~= web_para.dos and "" ~= web_para.dos then
		cursor:set("safeset","config","ddos_enable",web_para.dos)
	else
		cursor:set("safeset","config","ddos_enable","0")
	end

	if web_para.enable == "1" and web_para.dos == "1" and "1" == web_para.icmp_flood then
		cursor:set("safeset","config","icmp_flood",web_para.icmp_flood)
		cursor:set("safeset","config","icmpflood_rate",web_para.icmp_threshold)
	elseif nil ~= web_para.icmp_flood then
		cursor:set("safeset","config","icmp_flood",web_para.icmp_flood)
	end

	if web_para.enable == "1" and web_para.dos == "1" and "1" == web_para.udp_flood then
		cursor:set("safeset","config","udp_flood",web_para.udp_flood)
		cursor:set("safeset","config","udpflood_rate",web_para.udp_threshold)
	elseif nil ~= web_para.udp_flood then
		cursor:set("safeset","config","udp_flood",web_para.udp_flood)
	end

	if web_para.enable == "1" and web_para.dos == "1" and "1" == web_para.tcp_flood then
		cursor:set("safeset","config","syn_flood",web_para.tcp_flood)
		cursor:set("safeset","config","synflood_rate",web_para.tcp_threshold)
	elseif nil ~= web_para.tcp_flood then
		cursor:set("safeset","config","syn_flood",web_para.tcp_flood)
	end

	if web_para.enable == "1" and web_para.dos == "1" and nil ~= web_para.ping_disable and "" ~= web_para.ping_disable then
		cursor:set("safeset","config","ping_disable",web_para.ping_disable)
	end

	cursor:save("safeset")
	cursor:commit("safeset")
	cursor:apply("safeset", false, true)

	return err.E_NONE
end

function apply_arp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	require ("luci.sys")
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("arp_defence","arp_defence","enable",web_para.arp_defence or "0")
	cursor:set("arp_defence","arplimit","enable",web_para.arp_flood or "0")
	cursor:set("arp_defence","arplimit","arplimit_num",web_para.arp_threshold or "20")
	cursor:set("arp_defence","anti_cheat","enable",web_para.arp_cheating or "0")
	cursor:set("arp_defence","anti_cheat","garp_interval_time",web_para.arp_interval or "2")
	cursor:save("arp_defence")
	cursor:commit("arp_defence")
	-- cursor:apply("arp_defence", false, true)
	return err.E_NONE
end

function apply_bind_list(macaddr, ipaddr, method)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local mac = macaddr
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

	if "add" == method then
		local target = find_bind_entry(mac)
		if target then
			return err.E_DHCPD_CONFLICT_MAC
		else
			cursor:section("dhcp", "host", nil, {ip = ipaddr, mac = macaddr})
			cursor:save("dhcp")
			cursor:commit("dhcp")
		end
	elseif "delete" == method then
		local target = find_bind_entry(mac)
		if not target then
			-- entry not found
			return err.E_ENTRYNOTEXIST
		else
			cursor:delete("dhcp", target[".name"])
			cursor:save("dhcp")
			cursor:commit("dhcp")
		end
	else
		return err.E_INVARG
	end
	-- apply config
	cursor:apply("dhcp", false, true)
end

function apply_arp_bind_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	require ("luci.sys")
	if web_para.bind_flag == "1" then
		luci.sys.exec("arp_defence -s %s %s" % {web_para.ip, web_para.mac})
		apply_bind_list(web_para.mac, web_para.ip, "add")
	else
		luci.sys.exec("arp_defence -d %s" % {web_para.ip})
		apply_bind_list(web_para.mac, web_para.ip, "delete")
	end
	return err.E_NONE
end

function apply_bind_list_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	--实现一键清空ARP拦截列表功能
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:foreach("arp_defence","block_list",
		function(h)
			cursor:delete("arp_defence", h[".name"])
		end)

	cursor:save("arp_defence")
	cursor:commit("arp_defence")

	return err.E_NONE
end

