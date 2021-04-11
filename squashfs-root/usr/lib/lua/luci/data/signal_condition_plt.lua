--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   signal_condition_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的信号调节回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   08/18/2017  ShiQi          Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.data.signal_condition_plt", package.seeall)

function index()

end

function apply_signal_condition_plt(method, uciname, secname, web_para, diff_para, souce_data)
	--To Do
	local cursor = require("luci.model.uci").cursor()
	phicomm_lua = require("phic")

	local signal = web_para.signal_intensity
	cursor:set("signal-condition", "config", "power", signal)
	cursor:commit("signal-condition")

	if "3" == signal then
		phicomm_lua.set_wifi_device_config("2.4G", "txpower", 100)
		phicomm_lua.set_wifi_device_config("5G", "txpower", 100)
	elseif "2" == signal then
		phicomm_lua.set_wifi_device_config("2.4G", "txpower", 50)
		phicomm_lua.set_wifi_device_config("5G", "txpower", 50)
	else
		phicomm_lua.set_wifi_device_config("2.4G", "txpower", 25)
		phicomm_lua.set_wifi_device_config("5G", "txpower", 25)
	end

	os.execute("(sleep 1; reboot) &")

	return err.E_NONE
end
