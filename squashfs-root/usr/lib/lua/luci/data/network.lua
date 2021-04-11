--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   network.lua
* VERSION    :   1.0
* DESCRIPTION:   上网设置的回调函数
*
* AUTHOR     :   SunMeining <meining.sun@phicomm.com>
* CREATE DATE:   12/23/2016
*
* HISTORY    :
* 01   12/23/2016  SunMeining     Create.
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args
local K_MODULE = ds.KEY_MODULE
local NEED_APPLY = "need_apply"


module("luci.data.network", package.seeall)

function index()
	register_secname_cb("network", "wan", "check_wan", "apply_network_config_wan")
	register_secname_cb("network", "static", "check_static", "apply_network_config_static")
	register_secname_cb("network", "dhcp", "check_dhcp", "apply_network_config_dhcp")
	register_secname_cb("network", "pppoe", "check_pppoe", "apply_network_config_pppoe")
	register_secname_cb("network", "pptp", "check_pptp", "apply_network_config_pptp")
	register_secname_cb("network", "l2tp", "check_l2tp", "apply_network_config_l2tp")
	register_secname_cb("network", "wan_connection", "check_connection", "apply_network_config_connection")
end

function check_wan(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			protocol = {
				[KEY_VALIDATOR] = "luci.data.network.check_protocol"
			},
			clone_mode = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mac = {
				[KEY_VALIDATOR] = "luci.data.network.check_mac"
			}
		}
	)

	return err.E_NONE
end

function check_static(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			ip = {
				[KEY_VALIDATOR] = "luci.data.network.check_ip"
			},
			netmask = {
				[KEY_VALIDATOR] = "luci.data.network.check_netmask"
			},
			gateway = {
				[KEY_VALIDATOR] = "luci.data.network.check_gateway",
				[KEY_ARGS] = {0, 8}
			},
			mtu = {
				[KEY_VALIDATOR] = "luci.data.network.check_mtu",
				[KEY_ARGS] = {576, 1500, "static"}
			},
			dns_pri = {
				[KEY_VALIDATOR] = "luci.data.network.check_pridns"
			},
			dns_sec = {
				[KEY_VALIDATOR] = "luci.data.network.check_secdns"
			}
		}
	)

	return err.E_NONE
end

function check_dhcp(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			mtu = {
				[KEY_VALIDATOR] = "luci.data.network.check_mtu",
				[KEY_ARGS] = {576, 1500, "dhcp"}
			},
			dns_mode = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			dns_pri = {
				[KEY_VALIDATOR] = "luci.data.network.check_pridns"
			},
			dns_sec = {
				[KEY_VALIDATOR] = "luci.data.network.check_secdns"
			}
		}
	)

	return err.E_NONE
end

function check_pppoe(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			username = {
				[KEY_VALIDATOR] = "luci.data.network.check_username"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.network.check_password"
			},
			dial_mode = {
				[KEY_VALIDATOR] = "luci.data.network.check_dial_mode"
			},
			server = {
				[KEY_VALIDATOR] = "luci.data.network.check_server_name"
			},
			mtu = {
				[KEY_VALIDATOR] = "luci.data.network.check_mtu",
				[KEY_ARGS] = {576, 1492, "pppoe"}
			},
			dns_mode = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			dns_pri = {
				[KEY_VALIDATOR] = "luci.data.network.check_pridns"
			},
			dns_sec = {
				[KEY_VALIDATOR] = "luci.data.network.check_secdns"
			}
		}
	)

	return err.E_NONE
end

function check_pptp(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			server = {
				[KEY_VALIDATOR] = "luci.data.network.check_server"
			},
			username = {
				[KEY_VALIDATOR] = "luci.data.network.check_username"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.network.check_password"
			},
			ip_protocol = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mtu = {
				[KEY_VALIDATOR] = "luci.data.network.check_mtu",
				[KEY_ARGS] = {576, 1420, "pptp"}
			},
			dns_mode = {
				[KEY_VALIDATOR] = "luci.data.network.check_vpn_dns_mode"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.network.check_ip"
			},
			netmask = {
				[KEY_VALIDATOR] = "luci.data.network.check_netmask"
			},
			gateway = {
				[KEY_VALIDATOR] = "luci.data.network.check_gateway",
				[KEY_ARGS] = {0, 8}
			},
			dns_pri = {
				[KEY_VALIDATOR] = "luci.data.network.check_pridns"
			},
			dns_sec = {
				[KEY_VALIDATOR] = "luci.data.network.check_secdns"
			}
		}
	)

	return err.E_NONE
end

function check_l2tp(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			server = {
				[KEY_VALIDATOR] = "luci.data.network.check_server"
			},
			username = {
				[KEY_VALIDATOR] = "luci.data.network.check_username"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.network.check_password"
			},
			ip_protocol = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mtu = {
				[KEY_VALIDATOR] = "luci.data.network.check_mtu",
				[KEY_ARGS] = {576, 1460, "l2tp"}
			},
			dns_mode = {
				[KEY_VALIDATOR] = "luci.data.network.check_vpn_dns_mode"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.network.check_ip"
			},
			netmask = {
				[KEY_VALIDATOR] = "luci.data.network.check_netmask"
			},
			gateway = {
				[KEY_VALIDATOR] = "luci.data.network.check_gateway",
				[KEY_ARGS] = {0, 8}
			},
			dns_pri = {
				[KEY_VALIDATOR] = "luci.data.network.check_pridns"
			},
			dns_sec = {
				[KEY_VALIDATOR] = "luci.data.network.check_secdns"
			}
		}
	)

	return err.E_NONE
end

function check_connection(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			action = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function apply_network_config(para, method, retdata)
	local result = retdata
	local errcode, ret
	local plt = require("luci.data.network_plt")
	errcode, ret = plt.apply_network_config_plt(para, method, result)
	if err.E_NONE == errcode then
		result[K_MODULE].network.wait_time = ret.wait_time
	end

	return result
end

function apply_network_config_wan(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_wan_plt(method, uciname, secname, web_para, diff_para, souce_data)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end

function apply_network_config_static(method, uciname, secname, web_para, diff_para, souce_data, message)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_static_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end

function apply_network_config_dhcp(method, uciname, secname, web_para, diff_para, souce_data, message)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_dhcp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end

function apply_network_config_pppoe(method, uciname, secname, web_para, diff_para, souce_data, message)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_pppoe_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end

function apply_network_config_pptp(method, uciname, secname, web_para, diff_para, souce_data, message)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_pptp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end


function apply_network_config_l2tp(method, uciname, secname, web_para, diff_para, souce_data, message)
	local errcode, result
	local plt = require("luci.data.network_plt")
	errcode, result = plt.apply_network_config_l2tp_plt(method, uciname, secname, web_para, diff_para, souce_data, message)
	if nil == result then
		result = {}
	end
	result[NEED_APPLY] = 1
	return errcode, result
end

function apply_network_config_connection(method, uciname, secname, web_para, diff_para, souce_data)
	local plt = require("luci.data.network_plt")
	local error, data
	error, data = plt.apply_network_config_connection_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function check_protocol(value, web_para, diff_para, souce_data)
	local protocol = {"dhcp","pppoe","static","pptp","l2tp"}
	for _, v in ipairs(protocol) do
		if v == value then
			return err.E_NONE
		end
	end

	return err.E_NETWORK_PROTOCOL
end

function check_mac(value, web_para, diff_para, souce_data)
	if 1 == web_para.clone_mode or "1" == web_para.clone_mode then
		if value == "" then
			return err.E_MACCLONE_MAC_BLANK
		end

		local result = validator.check_mac(value)

		if result == E_INVMACFMT then
			return E_MACCLONE_MAC_ILLEGAL
		end

		if result ~= err.E_NONE then
			return result
		end
	end

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	local lan = require("luci.controller.admin.lan")
	local code, data = lan.get_lan_config()
	local lan_ip = data.ip
	local lan_netmask = data.netmask
	local wan_netmask = web_para.netmask or souce_data.netmask

	local result = validator.check_ip(value)
	if result ~= err.E_NONE then
		return err.E_NETWORK_IP_ILLEGAL
	end
--[[
	--No Need anymore
	local same_lan = validator.check_same_network(lan_ip, value, lan_netmask)
	local same_wan = validator.check_same_network(lan_ip, value, wan_netmask)
	if same_lan or same_wan then
		return err.E_NETLANSAME
	end
]]--
	return err.E_NONE
end

function check_netmask(value, web_para, diff_para, souce_data)
	local result = validator.check_mask(value)

	if result ~= err.E_NONE then
		return err.E_NETWORK_NETMASK_ILLEGAL
	end

	return err.E_NONE
end

function check_gateway(value, web_para, diff_para, souce_data)
	local result = validator.check_ip(value)

	if result ~= err.E_NONE then
		return err.E_NETWORK_GATEWAY_ILLEGAL
	end

	if validator.check_ip(web_para.ip) == err.E_NONE and validator.check_mask(web_para.netmask) == err.E_NONE then
		local same_net = validator.check_same_network(web_para.ip, value, web_para.netmask)
		if not same_net then
			return err.E_NETWORK_GATEWAY_ILLEGAL
		end
	end

	if web_para.ip == value then
		return err.E_NETWORK_IP_GATEWAY_SAME
	end

	return err.E_NONE
end

function check_mtu(value, web_para, diff_para, souce_data, min, max, wan_type)
	--mtu不能为空
	if "" == value then
		if wan_type == "static" then
			return err.E_NETWORK_STATIC_MTU_BLANK
		elseif wan_type == "dhcp" then
			return err.E_NETWORK_DHCP_MTU_BLANK
		elseif wan_type == "pppoe" then
			return err.E_NETWORK_PPPOE_MTU_BLANK
		elseif wan_type == "pptp" then
			return err.E_NETWORK_PPTP_MTU_BLANK
		else
			return err.E_NETWORK_L2TP_MTU_BLANK
		end
	end

	--mtu应在min、max范围之间
	if not validator.check_num_range(value, min, max) then
		if wan_type == "static" then
			return err.E_NETWORK_STATIC_MTU_ILLEGAL
		elseif wan_type == "dhcp" then
			return err.E_NETWORK_DHCP_MTU_ILLEGAL
		elseif wan_type == "pppoe" then
			return err.E_NETWORK_PPPOE_MTU_ILLEGAL
		elseif wan_type == "pptp" then
			return err.E_NETWORK_PPTP_MTU_ILLEGAL
		else
			return err.E_NETWORK_L2TP_MTU_ILLEGAL
		end
	end

	return err.E_NONE
end

function check_server(value, web_para, diff_para, souce_data)
	local result_ip = validator.check_ip(value)
	local result_domain = validator.check_domain(value)

	if result_ip ~= err.E_NONE and result_domain == false then
		return err.E_NETWORK_PPTP_SERVER_ILLEGAL
	end

	return err.E_NONE

end

function check_vpn_dns_mode(value, web_para, diff_para, souce_data)
	if "" == value then
		return err.E_NONE
	end

	local result = validator.check_bool(value)

	if result ~= err.E_NONE then
		return err.E_NETWORK_DNS_MODE
	end

	return err.E_NONE

end

function check_pridns(value, web_para, diff_para, souce_data)
	if web_para.dns_mode ~= "0" then
		if "" == value then
			return err.E_NETWORK_DNSPRI_BLANK
		end

		local result = validator.check_ip(value)

		if result ~= err.E_NONE then
			return err.E_NETWORK_DNSPRI_ILLEGAL
		end

		if value == web_para.dns_sec then
			return err.E_NETWORK_DNSPRI_DNSSEC_SAME
		end
	end

	return err.E_NONE

end

function check_secdns(value, web_para, diff_para, souce_data)
	if web_para.dns_mode ~= "0" then
		if "" == value then
			return err.E_NONE
		end

		local result = validator.check_ip(value)

		if result ~= err.E_NONE then
			return err.E_NETWORK_DNSSEC_ILLEGAL
		end

		if value == web_para.dns_pri then
			return err.E_NETWORK_DNSPRI_DNSSEC_SAME
		end
	end

	return err.E_NONE
end

function check_username(value, web_para, diff_para, souce_data)
	--账号不能为空
	if type(value) ~= "string" or "" == value then
		return err.E_NETWORK_PPPOE_USERNAME_BLANK
	end

	--账号长度非法
	local usernamelen = #value
	if usernamelen > 32 or usernamelen <= 0 then
		return err.E_NETWORK_PPPOE_USERNAME_LEN
	end

	return err.E_NONE
end

function check_password(value, web_para, diff_para, souce_data)
	--密码不能为空
	if type(value) ~= "string" or "" == value then
		return err.E_NETWORK_PPPOE_PWD_BLANK
	end

	--密码长度非法
	local pwdlen = #value
	if pwdlen > 32 or pwdlen <= 0 then
		return err.E_NETWORK_PPPOE_PWD_LEN
	end

	--密码含非法字符
	local ASCII_RANGE_END = 127
	for i = 1, pwdlen do
		local chr_num = string.byte(value, i, i)
		if chr_num > ASCII_RANGE_END then
			return err.E_NETWORK_PPPOE_PWD_ILLEGAL
		end
	end

	return err.E_NONE
end

function check_dial_mode(value, web_para, diff_para, souce_data)
	local modes = {0, 1, 2, 3, 4, "0", "1", "2", "3", "4"}
	local i, v
	for i, v in pairs(modes) do
		if v == value then
			return err.E_NONE
		end
	end

	return err.E_NETWORK_PPPOE_DIALMODE
end

function check_server_name(value, web_para, diff_para, souce_data)
	return err.E_NONE
end
