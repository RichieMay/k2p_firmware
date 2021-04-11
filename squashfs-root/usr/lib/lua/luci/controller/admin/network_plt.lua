local err = require("luci.phicomm.error")

module("luci.controller.admin.network_plt", package.seeall)

function index()

end

function get_wan_config_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local protocol = cursor:get("network", "vpn", "proto")
	if nil ~= protocol then
		protocol = protocol
	else
		protocol = cursor:get("network", "wan", "proto")
	end
	local result = {
		--protocol = cursor:get("network", "wan", "proto") ,
		protocol = protocol,
		mac = cursor:get("network", "wan", "mac_addr") or "",--clone_mode
		source_mac = cursor:get("network", "wan", "macaddr") or ""--not clone
	}
	--macoperate 1：禁止克隆  2：克隆mac
	--clone_mode 0：禁止克隆  1：克隆mac
	local macoperate = cursor:get("network", "wan", "macoperate")
	local val_map = {["1"] = "0", ["2"] = "1"}
	result.clone_mode = val_map[macoperate] or ""

	return err.E_NONE, result
end

function get_static_config_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	--static mode initial config
	require ("ubus")
	local conn = ubus.connect()
	local status = conn:call("network.interface.wan", "status", {})
	--ip
	local addrs = status["ipv4-address"]
	local ip = addrs and #addrs > 0 and addrs[1].address
	--gateway
	local gateway = "0.0.0.0"
	local _, route, gateway
	for _, route in ipairs(status["route"] or { }) do
		if route.target == "0.0.0.0" and route.mask == 0 then
			gateway = route.nexthop or "0.0.0.0"
		else
			gateway = "0.0.0.0"
		end
	end
	--netmask
	local ipc = require "luci.ip"
	local netmask = ( addrs and #addrs > 0 and ipc.IPv4("0.0.0.0/%d" % addrs[1].mask):mask():string())
	--dns
	local dns_pri, dns_sec
	if cursor:get("network", "wan", "peerdns") == "0" then
		----手动配置DNS
		if protocol == "dhcp" then
			dns_pri = cursor:get("network", "wan", "dns1") or ""
			dns_sec = cursor:get("network", "wan", "dns2") or ""
		else
			dns_pri = cursor:get("network", "wan", "pppoedns1") or ""
			dns_sec = cursor:get("network", "wan", "pppoedns2") or ""
		end
	else
		local dns = { }
		local _, addr
		for _, addr in ipairs(status["dns-server"] or { }) do
			if not addr:match(":") then
				dns[#dns+1] = addr
			end
		end
		dns_pri = dns[1] or ""
		dns_sec = dns[2] or ""
	end
	--end of static mode initial config

	local result = {
		ip = cursor:get("network", "wan", "ipaddr") or ip,
		netmask = cursor:get("network", "wan", "netmask") or netmask,
		gateway = cursor:get("network", "wan", "gateway") or gateway,
		dns_mode = "1",
		dns_pri = cursor:get("network", "wan", "static_dns1") or dns_pri,
		dns_sec = cursor:get("network", "wan", "static_dns2") or ""
	}
	local ignore = cursor:get("network", "wan", "ignore_mtu_change_pppoe")

	--mtu的改变是PPPOE造成的
	if ignore == "1" then
		result.mtu = "1500"
	--mtu的改变是DHCP或STATIC造成的
	else
		result.mtu = cursor:get("network", "wan", "mtu")
	end

	return err.E_NONE, result
end

function get_dhcp_config_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local result = {
		dns_pri = cursor:get("network", "wan", "dns1") or "",
		dns_sec = cursor:get("network", "wan", "dns2") or "",
		dns_mode = cursor:get("network", "wan", "dhcp_dns_mode")
	}
	local ignore = cursor:get("network", "wan", "ignore_mtu_change_pppoe")

	--mtu的改变是PPPOE造成的
	if ignore == "1" then
		result.mtu = "1500"
	--mtu的改变是DHCP或STATIC造成的
	else
		result.mtu = cursor:get("network", "wan", "mtu")
	end

	return err.E_NONE, result
end

function get_pppoe_config_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local result = {
		username = cursor:get("network", "wan", "username") or "",
		password = cursor:get("network", "wan", "password") or "",
		dial_mode = cursor:get("network", "wan", "DiaMode") or "",
		server = cursor:get("network", "wan", "service") or "",
		dns_pri = cursor:get("network", "wan", "pppoedns1") or "",
		dns_sec = cursor:get("network", "wan", "pppoedns2") or "",
		dns_mode = cursor:get("network", "wan", "pppoe_dns_mode")
	}
	local mtu = cursor:get("network", "wan", "mtu")
	local ignore = cursor:get("network", "wan", "ignore_mtu_change_pppoe")

	--mtu的改变是PPPOE造成的
	if ignore == "1" then
		result.mtu = tostring(tonumber(mtu)-8)
	--mtu的改变是DHCP或STATIC造成的
	else
		result.mtu = "1480"
	end

	return err.E_NONE, result
end

function calc_mask(args)
	local res = 0
	local num = args
	for i=num, 1, -1 do
		res = res + math.pow(2, i)
	end
	res = res * math.pow(2, 7-args)
	return tostring(res)
end

function get_byte_mask(args)
	local mask = "0"
	if (args >= 8) then
		mask = "255"
	elseif (args <= 0) then
		mask = "0"
	else
		mask = calc_mask(args)
	end
	return mask
end

function get_mask(args)
	local mask1 = "0"
	local mask2 = "0"
	local mask3 = "0"
	local mask4 = "0"

	mask1 = get_byte_mask(args)
	args = args - 8
	mask2 = get_byte_mask(args)
	args = args - 8
	mask3 = get_byte_mask(args)
	args = args - 8
	mask4 = get_byte_mask(args)

	mask = mask1 .. "." .. mask2 .. "." .. mask3 .. "." .. mask4
	return mask
end

function get_pptp_config_plt(args, uciname, secname)
	local ubus = require("ubus")
	local conn = ubus.connect()
	local status = conn:call("network.interface.wan", "status",{})

	local result = {}
	local ip_protocol = nil
	local dns_pri = nil
	local dns_sec = nil
	local dns_mode = nil
	local ip = nil
	local gateway = nil
	local netmask = nil

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local proto = cursor:get("network", "vpn", "proto")
	if "pptp" == proto then
		local server = cursor:get("network", "vpn", "server")
		local username = cursor:get("network", "vpn", "username")
		local password = cursor:get("network", "vpn", "password")
		local mtu = cursor:get("network", "vpn", "mtu")
		local wan_proto = cursor:get("network", "wan", "proto")
		local peerdns = cursor:get("network", "wan", "peerdns")
		if "dhcp" == wan_proto then --dhcp
			ip_protocol = "0"
			--dns
			if "0" == peerdns then
				dns_pri = cursor:get("network", "wan", "dns1") or ""
				dns_sec = cursor:get("network", "wan", "dns2") or ""
				--dns_mode = cursor:get("network", "wan", "dhcp_dns_mode")
				dns_mode = "1"
			else
				local dns_all = status["dns-server"]
				dns_pri = (dns_all and #dns_all > 0 and dns_all[1]) or "0.0.0.0"
				dns_sec = (dns_all and #dns_all > 0 and dns_all[2]) or "0.0.0.0"
				dns_mode = "0"
			end
			--ip
			local addrs = status["ipv4-address"]
			ip = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"
			--mask bit
			local maskbit = (addrs and #addrs > 0 and addrs[1].mask) or 0
			--gateway

			for _, v in ipairs(status["route"] or { }) do
				if v.target == "0.0.0.0" and v.mask == 0 then
					gateway = v.nexthop or "0.0.0.0"
				end
			end
			-- netmask
			if 0 == maskbit then
				netmask = "0.0.0.0"
			else
				netmask = get_mask(maskbit)
			end
		else -- static
			ip_protocol = "1"
			ip = cursor:get("network", "wan", "ipaddr")
			netmask = cursor:get("network", "wan", "netmask")
			gateway = cursor:get("network", "wan", "gateway")
			dns_mode = "1"
			dns_pri = cursor:get("network", "wan", "static_dns1") or "0.0.0.0"
			dns_sec = cursor:get("network", "wan", "static_dns2") or "0.0.0.0"
		end
		result = {
			server = server,
			username = username,
			password = password,
			ip_protocol = ip_protocol,
			ip = ip,
			netmask = netmask,
			gateway = gateway,
			mtu = mtu,
			dns_mode = dns_mode,
			dns_pri = dns_pri,
			dns_sec = dns_sec
		}
	else
		result = {
			server = "",
			username = "",
			password = "",
			ip_protocol = "0",
			ip = "",
			netmask = "",
			gateway = "",
			mtu = "1420",
			dns_mode = "0",
			dns_pri = "",
			dns_sec = ""
		}
	end

	return err.E_NONE, result
end

function get_l2tp_config_plt(args, uciname, secname)
	local ubus = require("ubus")
	local conn = ubus.connect()
	local status = conn:call("network.interface.wan", "status",{})

	local result = {}
	local ip_protocol = nil
	local dns_pri = nil
	local dns_sec = nil
	local dns_mode = nil
	local ip = nil
	local gateway = nil
	local netmask = nil

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local proto = cursor:get("network", "vpn", "proto")
	if "l2tp" == proto then
		local server = cursor:get("network", "vpn", "server")
		local username = cursor:get("network", "vpn", "username")
		local password = cursor:get("network", "vpn", "password")
		local mtu = cursor:get("network", "vpn", "mtu")
		local wan_proto = cursor:get("network", "wan", "proto")
		local peerdns = cursor:get("network", "wan", "peerdns")
		if "dhcp" == wan_proto then --dhcp
			ip_protocol = "0"
			--dns
			if "0" == peerdns then
				dns_pri = cursor:get("network", "wan", "dns1") or ""
				dns_sec = cursor:get("network", "wan", "dns2") or ""
				--dns_mode = cursor:get("network", "wan", "dhcp_dns_mode")
				dns_mode = "1"
			else
				local dns_all = status["dns-server"]
				dns_pri = (dns_all and #dns_all > 0 and dns_all[1]) or "0.0.0.0"
				dns_sec = (dns_all and #dns_all > 0 and dns_all[2]) or "0.0.0.0"
				dns_mode = "0"
			end
			--ip
			local addrs = status["ipv4-address"]
			ip = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"
			--mask bit
			local maskbit = (addrs and #addrs > 0 and addrs[1].mask) or 0
			--gateway
			for _, v in ipairs(status["route"] or { }) do
				if v.target == "0.0.0.0" and v.mask == 0 then
					gateway = v.nexthop or "0.0.0.0"
				end
			end
			-- netmask
			if 0 == maskbit then
				netmask = "0.0.0.0"
			else
				netmask = get_mask(maskbit)
			end
		else -- static
			ip_protocol = "1"
			ip = cursor:get("network", "wan", "ipaddr")
			netmask = cursor:get("network", "wan", "netmask")
			gateway = cursor:get("network", "wan", "gateway")
			dns_mode = "1"
			dns_pri = cursor:get("network", "wan", "static_dns1") or "0.0.0.0"
			dns_sec = cursor:get("network", "wan", "static_dns2") or "0.0.0.0"
		end
		result = {
			server = server,
			username = username,
			password = password,
			ip_protocol = ip_protocol,
			ip = ip,
			netmask = netmask,
			gateway = gateway,
			mtu = mtu,
			dns_mode = dns_mode,
			dns_pri = dns_pri,
			dns_sec = dns_sec
		}
	else
		result = {
			server = "",
			username = "",
			password = "",
			ip_protocol = "0",
			ip = "",
			netmask = "",
			gateway = "",
			mtu = "1460",
			dns_mode = "0",
			dns_pri = "",
			dns_sec = ""
		}
	end

	return err.E_NONE, result
end

function pingalive(addr)
	local num = 1
	local size = 64

	local re = {
		wan_loss = 0,
		wan_bad = 0
	}

	if not addr or "" == addr then
		return re
	end

	local util = io.popen("ping -c %s -s %s -W 1 -w 2 %q 2>&1" % {num, size, addr})
	if util then
		while true do
			local ln = util:read("*l")
			if not ln then break end
			local _,x = string.find(tostring(ln),"100%% packet loss")
			local _,y = string.find(tostring(ln),"bad address")
			if x then
				re.wan_loss = 1
				break
			end
			if y then
				re.wan_bad = 1
				break
			end
		end
	end
	util:close()

	return re
end

--获取WAN口错误码
function get_wan_status_code(args)
	require ("ubus")
	local conn = ubus.connect()
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local status_code = ""
	local status = ""

	--判断无线扩展状态
	local wisp_enable = 0 --0,无线扩展关闭，1，无线扩展开启
	local wisp_connect = 0 --0，无线扩展连接不成功，1，无线扩展连接成功
	local phicomm_lua = require("phic")
	local wisp_2gname = phicomm_lua.default_2g_wisp_ifname()[1]
	local wisp_5gname = phicomm_lua.default_5g_wisp_ifname()[1]
	wan_ifname = cursor:get("network","wan","ifname")

	if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
		wisp_enable = 1
		status = conn:call("rth.inet", "get_wisp_link", {})
		if status["wisp_link"] == "down" then
			--无线扩展连接不成功,返回“wan口未连接”错误码
			status_code = "1"
			return status_code
		end
	end

	status = conn:call("rth.inet", "get_inet_link", {})
	if status["inet_link"] == "up" then
		--可以上网
		status_code = "0"
	else
		--不能上网
		status = conn:call("rth.inet", "get_wan_link", {})
		if wisp_enable == 0 and status["wan_link"] == "down" then
				--WAN口未连接
				--开启无线扩展,并且连接算是WAN口正常连接
				status_code = "1"
		else
			status = conn:call("network.interface.wan", "status", {})
			--protocol
			local protocol = ""
			protocol = cursor:get("network", "wan", "proto")
			--ip
			local ipaddr = ""
			local addrs = status["ipv4-address"]
			ipaddr = (addrs and #addrs > 0 and addrs[1].address) or ""

			if protocol == "dhcp" or protocol == "pppoe" then
				--DHCP和PPPOE协议
				if ipaddr == "" or ipaddr == "0.0.0.0" then
					--没有IP地址
					if protocol == "pppoe" then
						status = conn:call("rth.inet", "get_pppd_status", {})
						status_code = status["pppd_status"] --pppoe错误码
						if status_code == "0" then
							status_code = "9"
						elseif status_code == "down" then
							status_code = "2" --ipcp down
						end
					else --protocol == "dhcp"
						status_code = "7"--DHCP server no response,
					end
				else
					--有IP地址
					--gateway
					local gwaddr = ""
					local _, route
					for _, route in ipairs(status["route"] or { }) do
						if route.target == "0.0.0.0" and route.mask == 0 then
							gwaddr = route.nexthop or ""
						end
					end

					local res = pingalive(gwaddr)
					if res.wan_loss == 1 or res.wan_bad == 1 then
						--网关PING不通
						status_code = "3" --gateway no response,
					else
						--网关能ping通
						--dns
						local dns_pri = ""
						local dns_sec = ""
						if cursor:get("network", "wan", "peerdns") == "0" then
							----手动配置DNS
							if protocol == "dhcp" then
								dns_pri = cursor:get("network", "wan", "dns1") or ""
								dns_sec = cursor:get("network", "wan", "dns2") or ""
							else
								dns_pri = cursor:get("network", "wan", "pppoedns1") or ""
								dns_sec = cursor:get("network", "wan", "pppoedns2") or ""
							end
						else
							local dns = { }
							local _, addr
							for _, addr in ipairs(status["dns-server"] or { }) do
								if not addr:match(":") then
									dns[#dns+1] = addr
								end
							end
							dns_pri = dns[1] or ""
							dns_sec = dns[2] or ""
						end

						local opt_value = cursor:get("network", "wan", "peerdns")
						if opt_value == nil or opt_value == "1" then
							--自动获取DNS
							if (#dns_pri == 0 or dns_pri == "")
								and (#dns_sec == 0 or dns_sec == "") then
								--dns地址为空
								status_code = "4" --no DNS address,
							else
								--dns地址不为空
								status_code = "5" --DNS no response,
							end
						else
							--自定义dns
							status_code = "6" --custom DNS error,
						end
					end
				end
			end
		end
	end
	return status_code
end

function get_wisp_connect(ifname)
	local stat, iwinfo = pcall(require, "iwinfo")
	local wisp_status = 0
	levle = iwinfo.get_wisp_connect(ifname)
	for k, v in ipairs(levle or { }) do
		if k or v then
			wisp_status = v
		end
	end
	return wisp_status
end


function get_wan_status_plt(args, uciname, secname)
	require ("ubus")

	local conn = ubus.connect()
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local wan_link = conn:call("rth.inet","get_wan_link",{})
	local phy_status = wan_link["wan_link"]

	local result = {
		protocol = cursor:get("network", "vpn", "proto")
	}

	if nil == result.protocol then
		result = {
			protocol = cursor:get("network", "wan", "proto")
		}
	end

	local phicomm_lua = require("phic")

	local wisp_2gname = phicomm_lua.default_2g_wisp_ifname()[1]
	local wisp_5gname = phicomm_lua.default_5g_wisp_ifname()[1]
	--wisp status
	local wisp_2g_status = get_wisp_connect(wisp_2gname)
	local wisp_5g_status = get_wisp_connect(wisp_5gname)

	wan_ifname = cursor:get("network","wan","ifname")

	--mac
	require ("luci.util")

	if wan_ifname == wisp_2gname then
		local wan_mac = luci.util.exec("ifconfig %q | grep HWaddr" % wisp_2gname)
		result.mac = string.upper(string.match(wan_mac,"%w+:%w+:%w+:%w+:%w+:%w+") or "00:00:00:00:00:00")
	elseif wan_ifname == wisp_5gname then
		local wan_mac = luci.util.exec("ifconfig %q | grep HWaddr" % wisp_5gname)
		result.mac = string.upper(string.match(wan_mac,"%w+:%w+:%w+:%w+:%w+:%w+") or "00:00:00:00:00:00")
	else
		if cursor:get("network","wan","ignore") == "1" then
			result.mac = string.upper(cursor:get("network","wan","macaddr") or "00:00:00:00:00:00")
		else
			result.mac = string.upper(cursor:get("network","wan","mac_addr") or "00:00:00:00:00:00")
		end
	end

	local status = conn:call("network.interface.vpn", "status", {})
	--判断当前是否是vpn连接
	if nil == status then
		status = conn:call("network.interface.wan", "status", {})
	end
	--ip
	local addrs = status["ipv4-address"]
	local ip = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"

	--若是无线扩展，否则，wan口已连接，则显示真实ip，若不然，ip为 0.0.0.0
	if ip and ((wan_ifname == wisp_2gname or wan_ifname == wisp_5gname) or phy_status == "up") then
        if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
            if wan_ifname == wisp_2gname and wisp_2g_status == 0 then
				result.ip = "0.0.0.0"
			end
            if wan_ifname == wisp_5gname and wisp_5g_status == 0 then
				result.ip = "0.0.0.0"
			end
		end
		result.ip = ip
	else
		result.ip = "0.0.0.0"
	end

	--netmask
	local ipc = require "luci.ip"
	local netmask = ( addrs and #addrs > 0 and
	ipc.IPv4("0.0.0.0/%d" % addrs[1].mask):mask():string()) or "0.0.0.0"

	if netmask and ((wan_ifname == wisp_2gname or wan_ifname == wisp_5gname) or phy_status == "up") then
        if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
            if wan_ifname == wisp_2gname and wisp_2g_status == 0 then
				result.netmask = "0.0.0.0"
			end
            if wan_ifname == wisp_5gname and wisp_5g_status == 0 then
				result.netmask = "0.0.0.0"
			end
		end
		result.netmask = netmask
	else
		result.netmask = "0.0.0.0"
	end

	--gateway
	local gateway = "0.0.0.0"
	local _, route
	for _, route in ipairs(status["route"] or { }) do
		if route.target == "0.0.0.0" and route.mask == 0 then
			gateway = route.nexthop or "0.0.0.0"
		else
			gateway = "0.0.0.0"
		end
	end

	if gateway and ((wan_ifname == wisp_2gname or wan_ifname == wisp_5gname) or phy_status == "up") then
        if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
            if wan_ifname == wisp_2gname and wisp_2g_status == 0 then
				result.gateway = "0.0.0.0"
			end
            if wan_ifname == wisp_5gname and wisp_5g_status == 0 then
				result.gateway = "0.0.0.0"
			end
		end
		result.gateway = gateway
	else
		result.gateway = "0.0.0.0"
	end

	--dns
	local dns_pri = "0.0.0.0"
	local dns_sec = "0.0.0.0"

	if result.protocol == "pptp" or result.proto == "l2tp" then
		local dns = { }
		local _, addr
		for _, addr in ipairs(status["dns-server"] or { }) do
			if not addr:match(":") then
				dns[#dns+1] = addr
			end
		end
		dns_pri = dns[1] or "0.0.0.0"
		dns_sec = dns[2] or "0.0.0.0"
	end
	--ip 为0.0.0.0 或空
	if nil == result.ip or "0.0.0.0" == result.ip then
		dns_pri = "0.0.0.0"
		dns_sec = "0.0.0.0"
	elseif nil == dns_pri or "0.0.0.0" == dns_pri then --vpn dns 为空或0.0.0.0
		status = conn:call("network.interface.wan", "status", {})
		wan_protocol = cursor:get("network", "wan", "proto")

		if wan_protocol == "static" then
			dns_pri = cursor:get("network", "wan", "static_dns1") or "0.0.0.0"
			dns_sec = cursor:get("network", "wan", "static_dns2") or "0.0.0.0"
		else
			if cursor:get("network", "wan", "peerdns") == "0" then
				----手动配置DNS
				if wan_protocol == "dhcp" then
					dns_pri = cursor:get("network", "wan", "dns1") or "0.0.0.0"
					dns_sec = cursor:get("network", "wan", "dns2") or "0.0.0.0"
				else
					dns_pri = cursor:get("network", "wan", "pppoedns1") or "0.0.0.0"
					dns_sec = cursor:get("network", "wan", "pppoedns2") or "0.0.0.0"
				end
			else
				local dns = { }
				local _, addr
				for _, addr in ipairs(status["dns-server"] or { }) do
					if not addr:match(":") then
						dns[#dns+1] = addr
					end
				end
				dns_pri = dns[1] or "0.0.0.0"
				dns_sec = dns[2] or "0.0.0.0"
			end
		end
	end

	if dns_pri and dns_sec and ((wan_ifname == wisp_2gname or wan_ifname == wisp_5gname) or phy_status == "up") then
        if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
            if wan_ifname == wisp_2gname and wisp_2g_status == 0 then
				result.dns_pri = "0.0.0.0"
				result.dns_sec = "0.0.0.0"
			end
            if wan_ifname == wisp_5gname and wisp_5g_status == 0 then
				result.dns_pri = "0.0.0.0"
				result.dns_sec = "0.0.0.0"
			end
		end
		result.dns_pri = dns_pri
		result.dns_sec = dns_sec
	else
		result.dns_pri = "0.0.0.0"
		result.dns_sec = "0.0.0.0"
	end
	--upload_speed,download_speed单位B/s
	--get_wan_speed 单位B/s
	--status = conn:call("rth.inet", "get_wan_speed", {})
	--result.upload_speed = tostring(status["tx_rate"]) or "0"
	--result.download_speed = tostring(status["rx_rate"]) or "0"

	--修改upload_speed和down_speed字段的实现方式，不利用ubus从WAN口去读，而是使用各个在线终端速度的总和
	local client_list
	local device_mng_lib = require("luci.adapter.device_mng")
	_, client_list = device_mng_lib.client_list()

	local upload_speed = 0
	local download_speed = 0
	for i = 1, #client_list do
		if client_list[i].online_status == "1" then
			upload_speed = upload_speed + client_list[i].upload_speed
			download_speed = download_speed + client_list[i].download_speed
		end
	end
	result.upload_speed = upload_speed
	result.download_speed = download_speed


	--inet_link 	down-不能上网 up-可以上网
	--internet_status 0-不能上网 1-可以上网
	local status = conn:call("network.interface.vpn", "status", {})
	local is_vpn = status == nil and 0 or 1
	if is_vpn == 0 then
		status = conn:call("network.interface.wan", "status", {})
	end
	result.status_code = get_wan_status_code()
	if is_vpn == 1 then
		result.internet_status ="0"
		if true == status["up"] then  --vpn 接口起来
			local addrs = status["ipv4-address"]
			ipaddr = (addrs and #addrs > 0 and addrs[1].address) or ""
			if ipaddr ~= "" and ipaddr ~= "0.0.0.0" and result.status_code == "0" then --拿到ip并且能上网
				result.internet_status = "1"
			end
		end
	else
		status = conn:call("rth.inet", "get_inet_link", {})
		if status["inet_link"] == "up" then
			result.internet_status = "1"
		else
			result.internet_status = "0"
		end
	end

	return err.E_NONE, result
end

function __get_wan_detection(args)
	--默认检测结果为0,代表static,检测结果异常时同样返回static
	local result_code = 0
	local result = {
		--检测未开始
		running_status = "0",
	}
	result.status_code = get_wan_status_code()
	--WAN口已连接
	if result.status_code ~= "1" then
		if args.action == "start" then
			result.running_status = "1"
			result.protocol = "static"
			--后台执行检测命令
			os.execute("autodetect &")
		elseif args.action == "get" then
			local file = io.open("/tmp/autodetect", "r")
			if file ~= nil then
				local data = file:read("*a");
				local d_status = string.sub(data, -1, -1)
				local d_result = string.sub(data, 1, 1)
				--检测中
				if d_status == "1" then
					result.running_status = "1"
					result.protocol = "static"
					--检测完成
				elseif d_status == "2" then
					result_code = tonumber(d_result)
					result.running_status = "2"
					local val_map = {"static", "dhcp", "pppoe", "static"}
					result.protocol = val_map[result_code + 1]
				else
					result.running_status = "0"
					result.protocol = "static"
				end
			else
				result.running_status = "0"
				result.protocol = "static"
			end
		else
			result.running_status = "0"
			result.protocol = "static"
		end
	--WAN口未连接
	else
		result.running_status = "2"
		result.protocol = "static"
	end

	return err.E_NONE, result
end

function get_wan_detection_plt(args, uciname, secname)
	local http = require("luci.http")
	local fs = require("luci.fs")
	local nixio = require("nixio")
	local seconds = 10
	local result_code = 0
	local result = {}
	local file_autodetect = "/tmp/autodetect"
	local val_map = {"static", "dhcp", "pppoe", "static"}
	local file

	--页面请求
	if not http.getenv("PHIAPP_REQUEST") then
		return __get_wan_detection(args)
	end

	--APP请求
	os.execute("rm -rf " .. file_autodetect)
	os.execute("autodetect > /dev/null 2>1 &")

	while seconds > 0 do
		nixio.nanosleep(1, 0)
		seconds = seconds - 1
		if fs.access(file_autodetect) then
			break
		end
	end

	result.status_code = get_wan_status_code()
	result.running_status = "2"
	result.protocol = "static"

	while seconds > 0 do
		nixio.nanosleep(1, 0)
		seconds = seconds - 1

		file = io.open(file_autodetect, "r")
		if file then
			local data = file:read("*a");
			local d_status = string.sub(data, -1, -1)
			local d_result = string.sub(data, 1, 1)

			if d_status == "2" and d_result then
				result_code = tonumber(d_result) or 0
				result.protocol = val_map[result_code + 1] or "static"
				file:close()
				break
			end
			file:close()
		end
	end

	return err.E_NONE, result
end

function get_wan_status_ap_plt(args, uciname, secname)
	require ("ubus")

	local conn = ubus.connect()

	local result = {}
	local status = conn:call("rth.inet", "get_inet_link", {})
	if status["inet_link"] == "up" then
		result.status_code = "1"
	else
		result.status_code = "0"
	end

	return err.E_NONE, result
end
