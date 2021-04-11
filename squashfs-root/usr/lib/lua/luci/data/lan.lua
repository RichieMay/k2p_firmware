--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   lan.lua
* VERSION    :   1.0
* DESCRIPTION:   LAN设置的回调函数
*
* AUTHOR     :   meining.sun <meining.sun@phicomm.com>
* CREATE DATE:   12/23/2016
*
* HISTORY    :
* 01   12/23/2016  SunMeining  Create.
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.lan", package.seeall)

function index()
	register_secname_cb("network", "lan", "check_lan", "apply_lan_config")
end

function check_lan(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			ip = {
				[KEY_VALIDATOR] = "luci.data.lan.check_ip"
			},
			netmask = {
				[KEY_VALIDATOR] = "luci.data.lan.check_mask"
			}
		}
	)

	return err.E_NONE
end

function check_wan_lan_confilict(lan_ip, lan_netmask)
	local network = require("luci.controller.admin.network")
	local code, wan_status = network.get_wan_status()
	local wan_ip = wan_status.ip
	local wan_netmask = wan_status.netmask

	-- 检查lan ip与wan ip是否在同一网段
	if validator.check_ip(wan_ip) == err.E_NONE and validator.check_mask(wan_netmask) == err.E_NONE then
		local same_lan = validator.check_same_network(wan_ip, lan_ip, lan_netmask)
		local same_wan = validator.check_same_network(wan_ip, lan_ip, wan_netmask)
		if same_lan or same_wan then
			return true
		end
	end

	return false
end

function check_ip(value, web_para, diff_para, souce_data)
	local result = validator.check_ip(value)
	local netmask = web_para.netmask or souce_data.netmask

	if result == err.E_NONE then
		result = validator.check_ip_mask(value, netmask)
	end

	if result ~= err.E_NONE then
		return err.E_INVLANIP
	end

	result = check_wan_lan_confilict(value, netmask)

	if result then
		return err.E_LAN_WAN_CONFLICT
	end

	return err.E_NONE
end

function check_mask(value, web_para, diff_para, souce_data)
	local result = validator.check_mask(value)

	if result ~= err.E_NONE then
		return err.E_INVLANMASK
	end

	result = check_wan_lan_confilict(web_para.ip, value)

	if result then
		return err.E_LAN_WAN_CONFLICT
	end

	return err.E_NONE
end

function apply_lan_config(method, uciname, secname, web_para, diff_para, souce_data)
	local lan_plt = require("luci.data.lan_plt")
	local error, data
	error, data = lan_plt.apply_lan_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end