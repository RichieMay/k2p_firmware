--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   remote_mng.lua
* VERSION    :   1.0
* DESCRIPTION:   远程管理的回调函数
*
* AUTHOR     :   meining.sun <meining.sun@phicomm.com>
* CREATE DATE:   12/26/2016
*
* HISTORY    :
* 01   12/26/2016  SunMeining  Create.
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local dbg = require("luci.phicomm.debug")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.remote_mng", package.seeall)

function index()
	register_secname_cb("firewall", "remote_manager", "check_remote", "apply_remote_config")
end

function check_remote(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			appenable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.remote_mng.check_ip"
			},
			port = {
				[KEY_VALIDATOR] = "luci.data.remote_mng.check_port"
			}
		}
	)

	return err.E_NONE
end


function apply_remote_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.remote_mng_plt")
	errcode, result = plt.apply_remote_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_ip(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	if "" == value then
		return err.E_REMOTE_IP_BLANK
	end

	-- 255.255.255.255表示允许所有远程终端管理路由器
	if "255.255.255.255" == value then
		return err.E_NONE
	end

	local result = validator.check_ip(value)
	if result ~= err.E_NONE then
		return err.E_REMOTE_IP_ILLEGAL
	end

	local lan = require("luci.controller.admin.lan")
	local code, data = lan.get_lan_config()
	local lan_ip = data.ip
	local lan_netmask = data.netmask
	local same_lan = validator.check_same_network(lan_ip, value, lan_netmask)
	if same_lan then
		return err.E_REMOTE_IP_LANIP_SUBNET
	end

	return err.E_NONE
end

function check_port(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	if "" ==  value then
		return err.E_REMOTE_PORT_BLANK
	end

	if not validator.check_num_range(value, 1, 65535) then
		return err.E_REMOTE_PORT_RANGE
	end
	local port_forward = require("luci.controller.admin.port_forward")
	local pf_code, pf_config = port_forward.get_forward_config()
	if pf_code == err.E_NONE and pf_config.enable == "1" then
		local code, forward_list = port_forward.get_forward_list()
		for i,v in ipairs(forward_list) do
			if tonumber(value) >= tonumber(v.extern_port_start) and tonumber(value) <= tonumber(v.extern_port_end) then
				return err.E_REMOTE_PORT_FORWARD_CONFLICT
			end
		end
	end
	return err.E_NONE
end
