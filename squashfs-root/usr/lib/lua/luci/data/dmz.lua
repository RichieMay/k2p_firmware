--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   dmz.lua
* VERSION    :   1.0
* DESCRIPTION:   dmz主机的回调函数
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

module("luci.data.dmz", package.seeall)

function index()
	register_secname_cb("firewall", "dmz", "check_dmz", "apply_dmz_config")
end

function check_dmz(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.dmz.check_ip"
			}
		}
	)

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	-- IP地址为空
	if "" == value then
		return err.E_DMZ_IP_BLANK
	end

	-- IP地址非法
	local result = validator.check_ip(value)
	if result ~= err.E_NONE then
		return err.E_DMZ_IP_ILLEGAL
	end

	local lan = require("luci.controller.admin.lan")
	local code, data = lan.get_lan_config()
	local lan_ip = data.ip
	local lan_netmask = data.netmask

	result = validator.check_ip_mask(value, lan_netmask)
	if result ~= err.E_NONE then
		return err.E_DMZ_IP_ILLEGAL
	end

	-- IP地址等于LAN口IP地址
	if value == lan_ip then
		return err.E_DMZ_IP_LANIP_SAME
	end

	-- IP地址和LAN口IP地址不在同一网段
	local same_lan = validator.check_same_network(lan_ip, value, lan_netmask)
	if not same_lan then
		return err.E_DMZ_IP_LANIP_SUBNET
	end

	return err.E_NONE
end

function apply_dmz_config(method, uciname, secname, web_para, diff_para, souce_data)
	local dmz_plt = require("luci.data.dmz_plt")
	local error, data
	error, data = dmz_plt.apply_dmz_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end