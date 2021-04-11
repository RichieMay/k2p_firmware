--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   guest-plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的访客网络回调函数
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

module("luci.data.guest_plt", package.seeall)

function index()

end

function apply_guest_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	local phicomm_lua = require("phic")

	local map_enable = {
		["0"] = "1",
		["1"] = "0"
	}

	if diff_para.enable ~= nil then
		phicomm_lua.set_wifi_iface_config("Guest", "disabled", map_enable[diff_para.enable])
	end

	if diff_para.password ~= nil and "1" == web_para.enable then
		if diff_para.password == "" then
			phicomm_lua.set_wifi_iface_config("Guest", "encryption", "none")
		else
			phicomm_lua.set_wifi_iface_config("Guest", "encryption", "psk-mixed+tkip+ccmp")
		end
		phicomm_lua.set_wifi_iface_config("Guest", "key", diff_para.password)
	end

	if diff_para.ssid ~= nil and "1" == web_para.enable then
		phicomm_lua.set_wifi_iface_config("Guest", "ssid", diff_para.ssid)
	end

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "guest", "guestStatus", web_para.enable)
		cursor:commit("wifi_time_switch")
	end

	cursor:apply("wireless", false, true)

	return err.E_NONE, {wait_time = 28}
end

function apply_guest_5g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()
	local phicomm_lua = require("phic")

	local map_enable = {
		["0"] = "1",
		["1"] = "0"
	}

	if diff_para.enable ~= nil then
		phicomm_lua.set_wifi_iface_config("Guest_5G", "disabled", map_enable[diff_para.enable])
	end

	if diff_para.password ~= nil and "1" == web_para.enable then
		if diff_para.password == "" then
			phicomm_lua.set_wifi_iface_config("Guest_5G", "encryption", "none")
		else
			phicomm_lua.set_wifi_iface_config("Guest_5G", "encryption", "psk-mixed+tkip+ccmp")
		end
		phicomm_lua.set_wifi_iface_config("Guest_5G", "key", diff_para.password)
	end

	if diff_para.ssid ~= nil and "1" == web_para.enable then
		phicomm_lua.set_wifi_iface_config("Guest_5G", "ssid", diff_para.ssid)
	end

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "guest", "guestStatus", web_para.enable)
		cursor:commit("wifi_time_switch")
	end


	return err.E_NONE, {wait_time = 28}
end

function apply_guest_time_switch_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()

	if web_para.enable ~= nil then
		cursor:set("wifi_time_switch", "guest", "enable", web_para.enable)
	end

	local minute, hour, down_time, up_time
	if web_para.close_time ~= nil and "1" == web_para.enable then
		hour = web_para.close_time / 3600 - web_para.close_time / 3600 % 1
		minute = web_para.close_time % 3600 / 60
		down_time = minute .. ' ' .. hour
		cursor:set("wifi_time_switch", "guest", "downTime", down_time)
	end

	if web_para.open_time ~= nil and "1" == web_para.enable then
		hour = web_para.open_time / 3600 - web_para.open_time / 3600 % 1
		minute = web_para.open_time % 3600 / 60
		up_time = minute .. ' ' .. hour
		cursor:set("wifi_time_switch", "guest", "upTime", up_time)
	end

	cursor:commit("wifi_time_switch")

	os.execute("/usr/bin/wifi_time_switch")

	return err.E_NONE
end
