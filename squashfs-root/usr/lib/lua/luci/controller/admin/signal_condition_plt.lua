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

module("luci.controller.admin.signal_condition_plt", package.seeall)

function index()

end

function get_signal_condition_plt(args, uciname, secname)
	--To Do
	local cursor = require("luci.model.uci").cursor()
	local signal = cursor:get("signal-condition", "config", "power") or "3"
	local result = {
		signal_intensity = signal
	}

	return err.E_NONE, result
end
