--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   upnp-plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的UPnP回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/14/2017  SunMeiNing     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.controller.admin.upnp_plt", package.seeall)

function index()

end

function get_upnp_conf_plt(args, uciname, secname)
	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor: get("UPnP", "config", "enable")

	return err.E_NONE, result
end

function get_upnp_list_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local util = require "luci.util"
	local result = {list = {}}
	local leasefile = cursor:get("upnpd", "config", "upnp_lease_file")
	if not leasefile then
		leasefile = "/var/upnp.leases"
	end

	if leasefile then
		local fd = io.open(leasefile, "r")
		if fd then
			local index = 1
			while true do
				local ln = fd:read("*l")
				if not ln then
					break
				end

				local tmp = util.split(ln, ":")
				if not tmp then
					t = {}
					break
				end
				result.list[index] = {
					protocol = tmp[1],
					external_port = tmp[2],
					ip = tmp[3],
					internal_port = tmp[4],
					status = '1',
					descript = tmp[6]
				}
				index = index + 1
			end
		end
	end

	return err.E_NONE, result
end
