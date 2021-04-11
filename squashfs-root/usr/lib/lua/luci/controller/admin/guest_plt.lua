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

module("luci.controller.admin.guest_plt", package.seeall)

function index()

end

function get_guest_wifi_conf_plt(args)
	local err = require("luci.phicomm.error")
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local wifi_guest,result
	local phic = require("phic")
	--local interface = "rax1"	--此处后续需通过dev_feature指定
	local interface = phic.default_access_wireless_ifname()
			and phic.default_access_wireless_ifname()[1] or ""

	cursor:foreach("wireless", "wifi-iface",
		function(h)
			if(h.ifname == interface) then
				wifi_guest = h
				return
			end
		end)

	if wifi_guest ~= nil then
		result = {
			ssid = wifi_guest.ssid or "",
			password = wifi_guest.key or ""
		}
	end

	if wifi_guest ~= nil then
		local disabled = wifi_guest.disabled
		local enable_map = {["0"] = "1", ["1"] = "0"}
		result.enable = enable_map[disabled]
	end

	return err.E_NONE, result
end

function get_guest_wifi_5g_conf_plt(args)
	local err = require("luci.phicomm.error")
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local wifi_guest,result
	local phic = require("phic")
	local interface = phic.default_access5g_wireless_ifname()
			and phic.default_access5g_wireless_ifname()[1] or ""

	cursor:foreach("wireless", "wifi-iface",
		function(h)
			if(h.ifname == interface) then
				wifi_guest = h
				return
			end
		end)

	if wifi_guest ~= nil then
		result = {
			ssid = wifi_guest.ssid or "",
			password = wifi_guest.key or ""
		}
	end

	if wifi_guest ~= nil then
		local disabled = wifi_guest.disabled
		local enable_map = {["0"] = "1", ["1"] = "0"}
		result.enable = enable_map[disabled]
	end

	return err.E_NONE, result
end

function get_guest_time_switch_plt(args)
	local err = require("luci.phicomm.error")
	local util = require "luci.util"

	local cursor = uci.cursor()
	local minute, hour, open_time, close_time
	local result = {}

	local enable = cursor:get("wifi_time_switch", "guest", "enable") or ""
	result.enable = enable

	local down_time = cursor:get("wifi_time_switch", "guest", "downTime") or ""
	down_time = util.split(down_time, " ")
	hour = tonumber(down_time[2]) or 0
	minute = tonumber(down_time[1]) or 0
	close_time = hour * 3600 + minute * 60
	result.close_time = close_time

	local up_time = cursor:get("wifi_time_switch", "guest", "upTime") or ""
	up_time = util.split(up_time, " ")
	hour = tonumber(up_time[2]) or 0
	minute = tonumber(up_time[1]) or 0
	open_time = hour * 3600 + minute * 60
	result.open_time = open_time

	return err.E_NONE, result
end
