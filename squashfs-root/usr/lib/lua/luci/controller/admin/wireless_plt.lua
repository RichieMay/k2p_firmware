--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   wireless_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的WiFi信息的获取函数
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
	-- wirless.wifi-iface
local phic = require "phic"
local ifname_2g = phic.default_2g_wireless_ifname()[1]
local ifname_5g = phic.default_5g_wireless_ifname()[1]

module("luci.controller.admin.wireless_plt", package.seeall)

function index()

end

function get_smart_connect_plt(args, uciname, secname)
	local cursor = uci.cursor()
	local smart_enable = cursor:get("wireless", "smartconnect", "enable") or "0"

	local result = {
		enable = smart_enable
	}
	return err.E_NONE, result
end

function get_wifi_config_plt(args, uciname, secname)
	local errcode = err.E_NONE
	local val_map = {["DE"] = "EU", ["IN"] = "AS"}
	local country = phic.get_wifi_device_config("5G", "country") and phic.get_wifi_device_config("5G", "country")[1]

	local result = {
		country_code = val_map[country] or "AS"
	}

	return errcode, result
end

function get_wifi_5g_config_plt(args, uciname, secname)
	local result = {
		mu_mimo = "1",
		beamforming = "1",
		power = "1"
		}

	local cursor = uci.cursor()
	--local result = {}
	local wifi_5g

	--wirless.wifi-iface文件
	cursor:foreach("wireless","wifi-iface",
		function(h)
			if h.ifname == ifname_5g then
				wifi_5g = h
				return
			end
		end)

	if wifi_5g ~= nil then
		result = {
			--enable
			ssid = wifi_5g.ssid or "",
			password = wifi_5g.key or "",
			hidden = wifi_5g.hidden or ""
		}
	else
		result = {
			--enable
			ssid = "",
			password = "",
			hidden = ""
		}
	end

	--disable（0：启用，1：禁用）
	--enable   1：启用，0：禁用
	local disabled = wifi_5g.disabled
	local val_map = {["0"] = "1", ["1"] = "0"}
	result.enable = val_map[disabled] or ""

	--wireless.wifi-devide.mtk文件
	result.channel = phic.get_wifi_device_config("5G", "channel")
		and phic.get_wifi_device_config("5G", "channel")[1] or ""
	result.ap_isolate = phic.get_wifi_device_config("5G", "noforward")
		and phic.get_wifi_device_config("5G", "noforward")[1] or ""

	--wifimode 14: 11a/n/ac 15: 11n/ac
	--mode    0：11a/n/ac，1：11n/ac
	local wifimode = phic.get_wifi_device_config("5G", "wifimode")
		and phic.get_wifi_device_config("5G", "wifimode")[1] or ""
	local val_map = {["14"] = "0", ["15"] = "1"}
	result.mode = val_map[wifimode] or "0"

	--bw		(0：20MHz，1：20/40MHz，2：80MHz）
	--band_width(0：20MHz，4：20/40MHz，2：80MHz, 1: 40MHz）
	local val_map = {["0"] = "0", ["1"] = "1", ["2"] = "2"}
	local bw = phic.get_wifi_device_config("5G", "bw")
		and phic.get_wifi_device_config("5G", "bw")[1] or ""
	local ht_bsscoexist = phic.get_wifi_device_config("5G", "ht_bsscoexist")
			and phic.get_wifi_device_config("5G", "ht_bsscoexist")[1] or ""
	if bw == "1" and ht_bsscoexist == "1" then
		result.band_width = "4"
	else
		result.band_width = val_map[bw] or ""
	end

	return err.E_NONE, result
end

function get_wifi_2g_config_plt(args, uciname, secname)
	local result = {
		mu_mimo = "1",
		beamforming = "1",
		power = "1"
		}

	local cursor = uci.cursor()
	local wifi_2g

	--wirless.wifi-iface文件
	cursor:foreach("wireless","wifi-iface",
		function(h)
			if h.ifname == ifname_2g then
				wifi_2g = h
				return
			end
		end)

	if wifi_2g ~= nil then
		result = {
			--enable
			ssid = wifi_2g.ssid or "",
			password = wifi_2g.key or "",
			hidden = wifi_2g.hidden or ""
		}
	else
		result = {
		--enable
		ssid = "",
		password = "",
		hidden = ""
		}
	end

	--disable（0：启用，1：禁用）
	--enable   1：启用，0：禁用
	local disabled = wifi_2g.disabled
	local val_map = {["0"] = "1", ["1"] = "0"}
	result.enable = val_map[disabled] or ""

	--wireless.wifi-devide.mtk文件
	result.channel = phic.get_wifi_device_config("2.4G", "channel")
		and phic.get_wifi_device_config("2.4G", "channel")[1] or ""
	result.ap_isolate = phic.get_wifi_device_config("2.4G", "noforward")
		and phic.get_wifi_device_config("2.4G", "noforward")[1] or ""

	--wifimode 9：11b/g/n，0：11b/g，6：11n
	--mode    0：11b/g/n，1：11b/g，2：11n
	local wifimode = phic.get_wifi_device_config("2.4G", "wifimode")
		and phic.get_wifi_device_config("2.4G", "wifimode")[1] or ""
	local val_map = {["9"] = "0", ["0"] = "1", ["6"] = "2"}
	result.mode = val_map[wifimode] or "1"

	--bw		(0：20MHz，2：20/40MHz，1：40MHz）
	--band_width 0：20MHz，1：20/40MHz，2：40MHz）
	local bw = phic.get_wifi_device_config("2.4G", "bw")
		and phic.get_wifi_device_config("2.4G", "bw")[1] or ""
	local val_map = {["0"] = "0", ["2"] = "1", ["1"] = "2"}
	result.band_width = val_map[bw] or ""

	return err.E_NONE, result
end

function get_wifi_5g_status_plt(args, uciname, secname)
	require ("luci.util")
	local result = {}
	local wifi = {}

	local cursor = uci.cursor()
	local device_type_5g = phic.get_wifi_device_config("5G", "type")
		and phic.get_wifi_device_config("5G", "type")[1] or ""

	cursor:foreach("wireless","wifi-iface",
		function(s)
			if s.device == device_type_5g and s.ifname == ifname_5g then
				wifi = s
				return
			end
		end)

	if wifi ~= nil then
		result.ssid = wifi.ssid or ""
	else
		result.ssid = ""
	end

	local mode = wifi.encryption or "none"

	if string.sub(mode,1,4) == "none"  then
		result.safe_mode = "0"
	elseif string.sub(mode,1,4) == "psk+" then
		result.safe_mode = "WPA-PSK"
	elseif string.sub(mode,1,5) == "psk2+" then
		ressult.safe_mode = "WPA2-PSK"
	elseif string.sub(mode,1,10) == "psk-mixed+" then
		result.safe_mode = "WPA-PSK/WPA2-PSK"
	else
		result.safe_mode = "WPA2-PSK"
	end

	-- mac
	result.mac = string.upper(luci.util.exec("cat /sys/class/net/%q/address" % ifname_5g) or "00:00:00:00:00:00")
	-- disable to enable   1：启用，0：禁用
	local disabled = wifi.disabled or ""
	local val_map = {["0"] = "1", ["1"] = "0"}
	result.enable = val_map[disabled] or ""

	-- channel
	local channel = luci.util.exec("iwconfig %q |grep Channel|cut -d \"=\" -f 2 | cut -d \" \" -f 1" % ifname_5g)
	result.channel = string.match(channel,"%d+") or ""

	-- wifimode 14: 11a/n/ac，15: 11n/ac
	-- mode      0：11a/n/ac，1：11n/ac
	local wifimode = phic.get_wifi_device_config("5G", "wifimode")
		and phic.get_wifi_device_config("5G", "wifimode")[1] or ""
	local val_map = {["14"] = "0", ["15"] = "1"}
	result.mode = val_map[wifimode] or "0"

	return err.E_NONE, result
end

function get_wifi_2g_status_plt(args, uciname, secname)
	require ("luci.util")
	local result = {}
	local wifi = {}

	local cursor = uci.cursor()
	local device_type_2g = phic.get_wifi_device_config("2.4G", "type")
		and phic.get_wifi_device_config("2.4G", "type")[1] or ""
	cursor:foreach("wireless","wifi-iface",
		function(s)
			if s.device == device_type_2g and s.ifname == ifname_2g then
				wifi = s
				return
			end
		end)

	if wifi ~= nil then
		result.ssid = wifi.ssid or ""
	else
		result.ssid = ""
	end

	local mode = wifi.encryption or "none"

	if string.sub(mode,1,4) == "none"  then
		result.safe_mode = "0"
	elseif string.sub(mode,1,4) == "psk+" then
		result.safe_mode = "WPA-PSK"
	elseif string.sub(mode,1,5) == "psk2+" then
		ressult.safe_mode = "WPA2-PSK"
	elseif string.sub(mode,1,10) == "psk-mixed+" then
		result.safe_mode = "WPA-PSK/WPA2-PSK"
	else
		result.safe_mode = "WPA2-PSK"
	end

	-- mac
	result.mac = string.upper(luci.util.exec("cat /sys/class/net/%q/address" % ifname_2g) or "00:00:00:00:00:00")
	-- disable to enable   1：启用，0：禁用
	local disabled = wifi.disabled or ""
	local val_map = {["0"] = "1", ["1"] = "0"}
	result.enable = val_map[disabled] or ""

	-- channel
	local channel = luci.util.exec("iwconfig %q |grep Channel|cut -d \"=\" -f 2 | cut -d \" \" -f 1" % ifname_2g)
	result.channel = string.match(channel,"%d+") or ""

	-- wifimode    0：11b/g/n，1：11b/g，2：11n
	local wifimode = phic.get_wifi_device_config("2.4G", "wifimode")
		and phic.get_wifi_device_config("2.4G", "wifimode")[1] or ""

	local val_map = {["9"] = "0", ["0"] = "1", ["6"] = "2"}
	result.mode = val_map[wifimode] or "1"

	return err.E_NONE, result
end

function get_wireless_time_switch_plt(args, uciname, secname)
	local util = require "luci.util"

	local cursor = uci.cursor()
	local result = {}

	local enable = cursor:get("wifi_time_switch", "b2d4gAnd5g", "enable") or ""
	result.enable = enable
	local hour, minute, close_time, open_time
	local down_time = cursor:get("wifi_time_switch", "b2d4gAnd5g", "downTime") or ""
	down_time = util.split(down_time, " ")
	hour = tonumber(down_time[2]) or 0
	minute = tonumber(down_time[1]) or 0
	close_time = hour * 3600 + minute * 60
	result.close_time = close_time

	local up_time = cursor:get("wifi_time_switch", "b2d4gAnd5g", "upTime") or ""
	up_time = util.split(up_time, " ")
	hour = tonumber(up_time[2]) or 0
	minute = tonumber(up_time[1]) or 0
	open_time = hour * 3600 + minute * 60
	result.open_time = open_time

	return err.E_NONE, result
end
