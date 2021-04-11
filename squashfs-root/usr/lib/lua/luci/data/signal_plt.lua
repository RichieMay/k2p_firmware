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

module("luci.data.signal_plt", package.seeall)

function index()

end

function apply_signal_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	phicomm_lua = require("phic")

	if diff_para.power ~= nil then
		phicomm_lua.set_wifi_device_config("2.4G", "power", diff_para.power)
	end

	return err.E_NONE, {wait_time = 40}
end


