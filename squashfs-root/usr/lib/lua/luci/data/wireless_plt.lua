--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   wireless_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的WiFi信息设置函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/12/2017  MengQingru     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local cursor = require("luci.model.uci").cursor()
local WIRELESS_RELOAD_TIME = cursor:get("dev_feature", "time", "wireless_restart")
module("luci.data.wireless_plt", package.seeall)

function index()

end
function apply_smart_connect_plt(method, uciname, secname, web_para, diff_para, souce_data)
	-- TO DO
	local cursor = require("luci.model.uci").cursor()
	if web_para.enable ~= nil then
		cursor:set("wireless", "smartconnect", "enable", web_para.enable)
		cursor:commit("wireless")
	end
	return err.E_NONE
end

function apply_wifi_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	-- TO DO
	phicomm_lua = require("phic")
	local country = web_para.country_code
	if nil ~= country then
		if country == "EU" then
			phicomm_lua.set_wifi_device_config("2.4G","country","DE")
			phicomm_lua.set_wifi_device_config("5G","country","DE")
			phicomm_lua.set_wifi_device_config("5G","aregion","6")
		else
			phicomm_lua.set_wifi_device_config("2.4G","country","IN")
			phicomm_lua.set_wifi_device_config("5G","country","IN")
			phicomm_lua.set_wifi_device_config("5G","aregion","10")
		end
	end
	return err.E_NONE
end

function apply_wifi_2g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	phicomm_lua = require("phic")

	local map_iface = {
		ssid = "ssid",
		password = "key",
		hidden = "hidden"
	}
	local map_device = {
		channel = "channel",
		ap_isolate = "noforward"
	}
	local map_wifimode = {
		["0"] = "9",
		["1"] = "0",
		["2"] = "6"
	}
	local map_enable = {
		["0"] = "1",
		["1"] = "0"
	}
	local map_bw = {
		["0"] = "0",
		["1"] = "2",
		["2"] = "1"
	}

	if diff_para.band_width ~= nil   then
		if diff_para.band_width == "1" then
			phicomm_lua.set_wifi_device_config("2.4G","ht_bsscoexist","1")
		else
			phicomm_lua.set_wifi_device_config("2.4G","ht_bsscoexist","0")
		end
	end

	if diff_para.band_width ~= nil then
		phicomm_lua.set_wifi_device_config("2.4G","bw",map_bw[diff_para.band_width])
	end

	if diff_para.enable ~= nil then
		phicomm_lua.set_wifi_iface_config("2.4G","disabled", map_enable[diff_para.enable])
	end

	if diff_para.mode ~= nil then
		phicomm_lua.set_wifi_device_config("2.4G","wifimode",map_wifimode[diff_para.mode])
	end

	if diff_para.password ~= nil then
		if diff_para.password == "" then
			phicomm_lua.set_wifi_iface_config("2.4G","encryption", "none")
		else
			phicomm_lua.set_wifi_iface_config("2.4G","encryption", "psk-mixed+tkip+ccmp")
		end
		phicomm_lua.set_wifi_iface_config("2.4G","key", diff_para.password)
	end

	local k, v
	for  k, v in pairs(diff_para) do
		if map_iface[k] ~= nil then
			phicomm_lua.set_wifi_iface_config("2.4G", map_iface[k], v)
		end

		if map_device[k] ~=nil then
			phicomm_lua.set_wifi_device_config("2.4G", map_device[k],v)
		end
	end

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b2d4gStatus", web_para.enable)
		cursor:commit("wifi_time_switch")
	end

	return err.E_NONE, {wait_time = 2}
end

function apply_wifi_5g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	phicomm_lua = require("phic")

	local map_iface = {
		ssid = "ssid",
		password = "key",
		hidden = "hidden"
	}
	local map_device = {
		channel = "channel",
		ap_isolate = "noforward"
	}
	local map_wifimode = {
		["0"] = "14",
		["1"] = "15",
	}
	local map_enable = {
		["0"] = "1",
		["1"] = "0"
	}
	local map_bw = {
		["0"] = "0",
		["2"] = "2"
	}

	if diff_para.band_width ~= nil   then
		if diff_para.band_width == "1" then
			phicomm_lua.set_wifi_device_config("5G", "ht_bsscoexist", "0")
			phicomm_lua.set_wifi_device_config("5G", "bw", "1")
		elseif diff_para.band_width == "4" then
			phicomm_lua.set_wifi_device_config("5G", "ht_bsscoexist", "1")
			phicomm_lua.set_wifi_device_config("5G", "bw", "1")
		else
			phicomm_lua.set_wifi_device_config("5G", "bw", map_bw[diff_para.band_width])
		end
	end

	if diff_para.enable ~= nil then
		phicomm_lua.set_wifi_iface_config("5G","disabled", map_enable[diff_para.enable])
	end

	if diff_para.mode ~= nil then
		phicomm_lua.set_wifi_device_config("5G","wifimode",map_wifimode[diff_para.mode])
	end

	if diff_para.password ~= nil then
		if diff_para.password == "" then
			phicomm_lua.set_wifi_iface_config("5G","encryption", "none")
		else
			phicomm_lua.set_wifi_iface_config("5G","encryption", "psk-mixed+tkip+ccmp")
		end
		phicomm_lua.set_wifi_iface_config("5G","key", diff_para.password)
	end

	local k, v
	for  k, v in pairs(diff_para) do
		if map_iface[k] ~= nil then
			phicomm_lua.set_wifi_iface_config("5G", map_iface[k], v)
		end

		if map_device[k] ~=nil then
			phicomm_lua.set_wifi_device_config("5G", map_device[k],v)
		end
	end

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b5gStatus", web_para.enable)
		cursor:commit("wifi_time_switch")
	end

	return err.E_NONE, {wait_time = 2}
end


function apply_wireless_time_switch_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	phicomm_lua = require("phic")

	local minute, hour, down_time, up_time, state_2g, state_5g

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "enable", web_para.enable)
	end

	if web_para.close_time ~= nil then
		hour = web_para.close_time / 3600 - web_para.close_time / 3600 % 1
		minute = web_para.close_time % 3600 / 60
		down_time = minute .. ' ' .. hour
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "downTime", down_time)
	end

	if web_para.open_time ~= nil then
		hour = web_para.open_time / 3600 - web_para.open_time / 3600 % 1
		minute = web_para.open_time % 3600 / 60
		up_time = minute .. ' ' .. hour
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "upTime", up_time)
	end

	state_2g = phicomm_lua.get_wifi_iface_config("2.4G", "disabled")
	state_5g = phicomm_lua.get_wifi_iface_config("5G", "disabled")

	if state_2g[1] == "1" then
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b2gStatus", "0")
	else
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b2gStatus", "1")
	end

	if state_5g[1] == "1" then
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b5gStatus", "0")
	else
		cursor:set("wifi_time_switch", "b2d4gAnd5g", "b5gStatus", "1")
	end

	cursor:commit("wifi_time_switch")

	os.execute("/usr/bin/wifi_time_switch")

	return err.E_NONE
end

function apply_wireless_config_plt(para, method, result)
	local ret = {wait_time = 2}
	local cursor = require("luci.model.uci").cursor()
	cursor:apply("wireless", false, true)
	ret.wait_time = WIRELESS_RELOAD_TIME
	return err.E_NONE, ret
end
