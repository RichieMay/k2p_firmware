local err = require("luci.phicomm.error")

module("luci.controller.admin.safe_set_plt", package.seeall)

function index()
end

function get_safe_config_plt(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()

	local result = {
		enable = "1",
		dos = cursor:get("safeset","config","ddos_enable") or "0",
		icmp_flood = cursor:get("safeset","config","icmp_flood") or "1",
		icmp_threshold = cursor:get("safeset","config","icmpflood_rate") or "50",
		udp_flood = cursor:get("safeset","config","udp_flood") or "1",
		udp_threshold = cursor:get("safeset","config","udpflood_rate") or "500",
		tcp_flood = cursor:get("safeset","config","syn_flood") or "1",
		tcp_threshold = cursor:get("safeset","config","synflood_rate") or "50",
		ping_disable = cursor:get("safeset","config","ping_disable") or "0"
	}

	return err.E_NONE, result
end

function get_arp_config_plt(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {
		arp_defence = cursor:get("arp_defence","arp_defence","enable") or "0",
		arp_flood = cursor:get("arp_defence","arplimit","enable") or "0",
		arp_threshold = cursor:get("arp_defence","arplimit","arplimit_num") or "1",
		arp_cheating = cursor:get("arp_defence","anti_cheat","enable") or "0",
		arp_interval = cursor:get("arp_defence","anti_cheat","garp_interval_time") or "1",
		block_list = {}
	}

	cursor:foreach("arp_defence","block_list",
	function(h)
		local x = {
		ip = h.ip,
		mac = h.mac
	}
		result.block_list[#(result.block_list) + 1] = x
	end)

	return err.E_NONE, result
end

function get_bind_list_plt(args, uciname, secname)
	local arp_tb = {}
	local cmd = [[awk '{print $1, $3, $4}' /proc/net/arp]]
	local fd = io.popen(cmd, "r")
	if fd then
		-- skip first line
		local ln = fd:read("*l")
		local idx = 1

		-- read arp items
		while true do
			ln = fd:read("*l")
			if not ln then break end

			local ipaddr = string.match(ln, "%d+%.%d+%.%d+%.%d+")
			local state = string.match(ln, "0x%d")
			local macaddr = string.match(ln, "%x%x:%x%x:%x%x:%x%x:%x%x:%x%x")

			-- state状态 0x6：静态条目，0x2：动态条目，0x0：已失效条目
			if ipaddr and state and macaddr and state == "0x6" or state == "0x2" or state == "0x0" then
				local entry = {
					ip = ipaddr,
					mac = macaddr,
					bind_flag = (state == "0x6") and "1" or "0"
				}

				arp_tb[#arp_tb + 1] = entry
			end

			idx = idx + 1
		end

		fd:close()
	end

	return err.E_NONE, arp_tb
end