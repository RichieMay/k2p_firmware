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

module("luci.data.upnp_plt", package.seeall)

function index()

end

function apply_upnp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("UPnP", "config", "enable", web_para.enable)
	cursor:save("UPnP")
	cursor:commit("UPnP")

	cursor:apply("UPnP", false, true)

	return err.E_NONE
end