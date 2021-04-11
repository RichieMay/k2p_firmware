--[[
**********************************************************************************
* Copyright (c) 2017 Shanghai Phicomm Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   wireless.lua
* VERSION    :   1.0
* DESCRIPTION:   WiFi的获取信号和配置函数
*
* AUTHOR     :   xi.chen <xi.chen@phicomm.com>    feng.kang <feng.kang@phicomm.com>
* CREATE DATE:   02/08/2017
*
* HISTORY    :
* 01   02/08 /2016  ChenXi  Create.
* 02   02/08 /2016  KangFeng  Add
**********************************************************************************
--]]
local err = require("luci.phicomm.error")
local dbg = require("luci.phicomm.debug")
local ds = require("luci.controller.ds")

module("luci.controller.admin.wireless", package.seeall)

function index()
	entry({"pc", "wifiConfig.htm"}, template("pc/wifiConfig")).leaf = true
	entry({"h5", "wifiConfig.htm"}, template("h5/wifiConfig")).leaf = true
	entry({"data", "wireless"}, call("ds_wireless"), "wireless set").leaf = true

	register_keyword_data("wireless", "smart_connect", "get_smart_connect")
	register_keyword_data("wireless", "wifi_2g_config", "get_wifi_2g_config")
	register_keyword_data("wireless", "wifi_5g_config", "get_wifi_5g_config")
	register_keyword_data("wireless", "wifi_config", "get_wifi_config")
	register_keyword_data("wireless", "wifi_2g_status", "get_wifi_2g_status")
	register_keyword_data("wireless", "wifi_5g_status", "get_wifi_5g_status")
	register_keyword_data("wireless", "wireless_time_switch", "get_wireless_time_switch")
end

function ex_wireless(para, method, retdata)
	local ret = retdata or {}
	if "set" == method and err.E_NONE == retdata.error_code then
		local ap_wireless = require("luci.data.wireless")
		ret = ap_wireless.apply_wireless_config(para, method, retdata)
	end
	return ret
end

function ds_wireless()
	ds.ds(ex_wireless)
end

function get_smart_connect(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, result
	errcode, data = plt.get_smart_connect_plt(args, uciname, secname)
	return errcode, data
end

function get_wifi_config(args, uciname, secname)
--[[
	返回值范例
	local wifi_config = {
		country_code = "EU"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, result
	errcode, data = plt.get_wifi_config_plt(args, uciname, secname)
	return errcode, data
end

function get_pwd_safety(pwd)
	local safety = 0

	-- 有小写字母
	if string.find(pwd, "%l") then
		safety = safety + 1
	end

	-- 有大写字母
	if string.find(pwd, "%u") then
		safety = safety + 1
	end

	-- 有数字
	if string.find(pwd, "%d") then
		safety = safety + 1
	end

	-- 有除了小写，大写和数字
	if string.find(pwd, "%W") then
		safety = 3
	end

	return safety
end

function get_wifi_2g_config(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1",
		ssid = "@PHICOMM_XX",
		password = "12345678",
		hidden = "1",
		mode = "0",
		channel = "0",
		band_width = "0",
		ap_isolate = "1",
		mu_mimo = "1",
		beamforming = "1",
		power = "1"
		safety = "1"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, result
	errcode, result = plt.get_wifi_2g_config_plt()
	if errcode == err.E_NONE then
		-- convert wifi password safety function
		result["safety"] = get_pwd_safety(result.password)
	end
	return errcode, result
end

function get_wifi_5g_config(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1",
		ssid = "@PHICOMM_XX_5G",
		password = "12345678",
		hidden = "1",
		mode = "0",
		channel = "0",
		band_width = "0",
		ap_isolate = "1",
		mu_mimo = "1",
		beamforming = "1",
		power = "1"
		safety = "1"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, result
	errcode, result = plt.get_wifi_5g_config_plt()
	if errcode == err.E_NONE then
		-- convert wifi password safety function
		result["safety"] = get_pwd_safety(result.password)

	end
	return errcode, result
end

function get_wifi_2g_status(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1",
		ssid = "@PHICOMM_XX",
		safe_mode = "1",
		mode = "0",
		channel = "1",
		mac = "00:11:22:33:44:55"
	}
]]--

	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, data
	errcode, data = plt.get_wifi_2g_status_plt(args, uciname, secname)

	return errcode, data
end

function get_wifi_5g_status(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1",
		ssid = "@PHICOMM_XX_5G",
		safe_mode = "1",
		mode = "0",
		channel = "149",
		mac = "00:11:22:33:44:55"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, data
	errcode, data = plt.get_wifi_5g_status_plt(args, uciname, secname)

	return errcode, data

end

function get_wireless_time_switch(args, uciname, secname)
--[[
	返回值范例
	local result = {
		enable = "1",
		close_time = "3600"
		open_time = "3900"
	}
]]--
	local plt = require("luci.controller.admin.wireless_plt")
	local errcode, data
	errcode, data = plt.get_wireless_time_switch_plt(args, uciname, secname)

	return errcode, data

end
