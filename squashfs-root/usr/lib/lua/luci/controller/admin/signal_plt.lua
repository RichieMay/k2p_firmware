--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   signal-plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的健康节能回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/11/2017  SunMeiNing     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.controller.admin.signal_plt", package.seeall)

function index()

end

function get_signal_conf_plt(args, uciname, secname)
	local result = {}
	local phic = require "phic"
	result.power = phic.get_wifi_device_config("2.4G", "power")
		and phic.get_wifi_device_config("2.4G", "power")[1] or "1"
	return err.E_NONE, result
end
