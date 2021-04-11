--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   statistics.lua
* VERSION    :   1.0
* DESCRIPTION:   statistic login info.
*
* AUTHOR     :   MengQingru <qingru.meng@phicomm.com>
* CREATE DATE:   5/3/2017
*
* HISTORY    :
* 01   5/3/2017  qingru.meng     Create.
**********************************************************************************
]]--

local err = require("luci.phicomm.error")

module("luci.phicomm.statistic", package.seeall)

function get_device_type()
	local http = require("luci.http")
	local protocol = require("luci.http.protocol")
	local para, dev

	para = http.jsondata()
	para = para or json.decode(http.get_raw_data() or "", protocol.urldecode) or {}
	--暂时还未对APP接口添加_deviceType字段，故默认情况下认为是APP
	local dev = para._deviceType or "app";
	return dev
end

function login()
	local dev = get_device_type()

	local plt = require("luci.phicomm.statistic_plt")
	plt.login_plt(dev);

	return err.E_NONE
end

function first_config()
	local dev
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()
	local statistic = require("luci.phicomm.statistic_plt")
	dev = get_device_type()
	statistic.set_first_config_plt(dev);
	return err.E_NONE
end

function diagnosis(wan_status)
	local plt = require("luci.phicomm.statistic_plt")
	plt.diagnosis_plt(wan_status)
	return err.E_NONE
end
