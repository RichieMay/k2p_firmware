--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   time_reboot_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   定时重启
*
* AUTHOR     :   MengQingru <qingru.meng@phicomm.com>
* CREATE DATE:   07/12/2017
*
* HISTORY    :
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.data.time_reboot_plt", package.seeall)

function index()

end

function apply_time_reboot_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("timereboot","timereboot","enable",web_para.enable)
	if web_para.enable == "1" then
		cursor:set("timereboot","timereboot","hour",web_para.reboot_hour)
		cursor:set("timereboot","timereboot","minute",web_para.reboot_minute)
	end
	cursor:save("timereboot")
	cursor:commit("timereboot")
	os.execute("/usr/sbin/timereboot &")
	return err.E_NONE
end