local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args
local bit = require("luci.phicomm.lib.bit").bit

module("luci.data.dhcp", package.seeall)

function index()
	register_secname_cb("dhcpd", "config", "check_dhcp", "apply_dhcp")
	register_secname_cb("dhcpd", "bind_list", "check_bind_list", "apply_bind_list")
end

function apply_dhcp(method, uciname, secname, web_para, diff_para, souce_data)
	local dhcp_plt = require("luci.data.dhcp_plt")
	local error, data
	error, data = dhcp_plt.apply_dhcp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function apply_bind_list(method, uciname, secname, web_para, diff_para, souce_data)
	local dhcp_plt = require("luci.data.dhcp_plt")
	local error, data
	error, data = dhcp_plt.apply_bind_list_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function check_dhcp(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			pool_start = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_pool_start"
			},
			pool_end = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_pool_end"
			}
		}
	)

	return err.E_NONE
end

function check_pool_start(value, web_para, diff_para, souce_data)
	return check_pool(value, web_para, err.E_DHCPPOOLSTART)
end

function check_pool_end(value, web_para, diff_para, souce_data)
	return check_pool(value, web_para, err.E_DHCPPOOLEND)
end

function check_pool(value, web_para, err_code)

--[[
	local subnet_mask = tonumber(string.match(web_para.network_address, "%d+/(%d+)"))
	local pool_max = 2^(32 - subnet_mask) - 2

	if validator.check_num_range(value, 1, pool_max) then
		--起始地址大于结束地址
		if validator.check_num(web_para.pool_start) then
			if validator.check_num(web_para.pool_end) then
				local pool_start = tonumber(web_para.pool_start)
				local pool_end = tonumber(web_para.pool_end)

				if pool_start > pool_end then
					return err.E_POOLSTARTGRATEREND
				end
			else
				return err.E_DHCPPOOLEND
			end
		else
			return err.E_DHCPPOOLSTART
		end
	else
		return err_code
	end
]]--

	return err.E_NONE
end

function check_bind_list(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			id = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_id"
			},
			name = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_name"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_ip"
			},
			mac = {
				[KEY_VALIDATOR] = "luci.data.dhcp.check_mac"
			}
		}
	)
	return err.E_NONE
end

function check_id(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_name(value, web_para, diff_para, souce_data)
	if "string" ~= type(value) then
		return err.E_DHCPD_NAME_ILLEGAL
	end

	if 0 == #value or #value > 32 then
		return err.E_DHCPD_NAME_LEN
	end

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	local lan = require("luci.controller.admin.lan")
	local errcode,data = lan.get_lan_config()
	local lan_ip = data.ip
	local lan_netmask = data.netmask

	local result = validator.check_ip(value)
	if err.E_NONE ~= result then
		return err.E_DHCPD_IP_ILLEGAL
	end

	local u32_lan_ip = validator.trans_ip(lan_ip)
	local u32_ip = validator.trans_ip(value)
	local u32_lan_netmask = validator.trans_ip(lan_netmask)

	if u32_ip == bit:bit_and(u32_ip, u32_lan_netmask)
		or bit:bit_not(u32_lan_netmask) == (u32_ip - bit:bit_and(u32_ip, u32_lan_netmask)) then
		return err.E_DHCPD_IP_ILLEGAL
	end
	--[[
	if bit:bit_and(u32_lan_ip, u32_lan_netmask) ~= bit:bit_and(u32_ip, u32_lan_netmask) then
		return err.E_DHCPD_IP_LANIP_SAME
	end
	]]--

	if u32_lan_ip == u32_ip then
		return err.E_DHCPD_IP_LANIP_SAME
	end

	for i,v in ipairs(souce_data) do
		if v.id ~= web_para.id then
			if v.ip == value then
				return err.E_DHCPD_CONFLICT_IP
			end
		end
	end

	return err.E_NONE

end

function check_mac(value, web_para, diff_para, souce_data)
	local result = validator.check_mac(value)
	if err.E_NONE ~= result then
		return err.E_DHCPD_MAC_ILLEGAL
	end

	for i,v in ipairs(souce_data) do
		if v.id ~= web_para.id then
			if string.lower(v.mac) == string.lower(value) then
				return err.E_DHCPD_CONFLICT_MAC
			end
		end
	end

	return err.E_NONE

end