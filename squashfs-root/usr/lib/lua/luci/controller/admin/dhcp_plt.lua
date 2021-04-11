local err = require("luci.phicomm.error")

module("luci.controller.admin.dhcp_plt", package.seeall)

function index()
end

function get_dhcp_conf_plt(uciname, secname, args)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	ipaddr = cursor:get("network", "lan", "ipaddr")
	-- ip3, ip2, ip1, ip0 = string.match(ipaddr, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
	-- ip_int = ip3 * math.pow(256, 3) + ip2 * math.pow(256, 2) + ip1 * math.pow(256, 1) + ip0
	netmask = cursor:get("network", "lan", "netmask")
	nm3, nm2, nm1, nm0 = string.match(netmask, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
	nm_int = nm3 * math.pow(256, 3) + nm2 * math.pow(256, 2) + nm1 * math.pow(256, 1) + nm0

	local bit = require("nixio").bit
	-- ip_and_nm = bit.band(ip_int, nm_int)
	-- ip_nm3, ip_and_nm = math.modf(ip_and_nm / math.pow(256, 3))
	-- ip_nm2, ip_and_nm = math.modf(ip_and_nm * 256)
	-- ip_nm1, ip_and_nm = math.modf(ip_and_nm * 256)
	-- ip_nm0, ip_and_nm = math.modf(ip_and_nm * 256)

	num = 0
	while (nm_int > 0) do
		nm_int = nm_int - math.pow(2, 31 - num)
		num = num + 1
	end

	-- ipaddr_table = {tostring(ip_nm3), ".", tostring(ip_nm2), ".", tostring(ip_nm1), ".", tostring(ip_nm0), "/", tostring(num)}
	-- ipaddr_range = table.concat(ipaddr_table)
	ipaddr_range = ipaddr .. "/" .. tostring(num)

	local pool_start = cursor:get("dhcp", "lan", "start")
	local pool_end = tonumber(pool_start) + tonumber(cursor:get("dhcp", "lan", "limit")) - 1
	local result = {
		enable = cursor:get("dhcp", "lan", "dynamicdhcp") or "1",
		pool_start = pool_start,
		pool_end = tostring(pool_end),
		network_address = ipaddr_range
	}

	return err.E_NONE, result
end

function get_bind_list_plt(uciname, secname, args)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local result, section_name, name
	cursor:foreach("dhcp", "host", function (clients)
		local lan_mac = cursor:get("network", "lan", "macaddr")
		if lan_mac ~= clients.mac then
			result = result or {}
			section_name = string.gsub(clients.mac, ":", "_")

			local name = cursor:get("device_manage", section_name, "hostname") or "UnKnown"
			local brand = cursor:get("device_manage", section_name, "brand") or "UnKnown"

			clients_name = cursor:get("common_host", section_name, "hostname") or name
			local res = {
				id = string.gsub(clients.mac, ":", "_"),
				name =  clients_name,
				ip = clients.ip,
				brand = brand,
				mac = clients.mac
			}
			result[#result + 1] = res
		end
	end)

	return err.E_NONE, result
end