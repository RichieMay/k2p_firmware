--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   statistic_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   统计首配方式
*
* AUTHOR     :   Mengqingru <qingru.meng@phicomm.com>
* CREATE DATE:   07/07/2017
*
* HISTORY    :
* 01   07/07/2017  MengQingru     Create.
**********************************************************************************
--]]
local err = require("luci.phicomm.error")
module("luci.phicomm.statistic_plt", package.seeall)

function index()

end

function set_first_config_plt(dev)
	local cursor = require ("luci.model.uci").cursor()
	cursor:set("luci","main","first_config",dev)
	cursor:save("luci")
	cursor:commit("luci")
	return err.E_NONE
end

function login_plt(dev)

	luci.util.exec(
		string.format(
			"statistics_data_event --login %s >/dev/null; ", dev
		)
	)
	return err.E_NONE
end

function diagnosis_plt(wan_status)
	local DIAGNOSIS, WANSTATUS = "diagnosis", "wan_status"
	local cursor = require ("luci.model.uci").cursor()
	cursor:set(DIAGNOSIS, WANSTATUS, "protocol",wan_status.protocol)
	cursor:set(DIAGNOSIS, WANSTATUS, "internet_status",wan_status.internet_status)
	cursor:set(DIAGNOSIS, WANSTATUS, "status_code",wan_status.status_code)
	cursor:set(DIAGNOSIS, WANSTATUS, "daily_used","1")
	cursor:set(DIAGNOSIS, WANSTATUS, "recently_used","1")

	cursor:save(DIAGNOSIS)
	cursor:commit(DIAGNOSIS)

	return err.E_NONE
end