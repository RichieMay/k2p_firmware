--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   wifi_extend-plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的无线扩展回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/18/2017  SunMeiNing     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.controller.admin.wifi_extend_plt", package.seeall)

function index()

end

function get_wisp_conf_plt(args, uciname, secname)
	local ubus = require("ubus")
	local conn = ubus.connect()
	local status = conn:call("network.interface.wan", "status",{})
	local status_vpn = conn:call("network.interface.vpn", "status",{})
	local wisp = conn:call("rth.inet", "get_wisp_link",{})
	local phicomm_lua = require("phic")

	local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliEnable") or {"0"}
	local apcli_2_4G_enable = tmptable[1] --enable

	local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliEnable") or {"0"}
	local apcli_5G_enable = tmptable[1] --enable

	if apcli_2_4G_enable == "1" then
		local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliBssidBak") or {""}
		apcli_bssid = tmptable[1] --mac
		local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliSsid") or {""}
		apcli_ssid = tmptable[1] --ssid
		local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliAuthMode") or {"OPEN"}
		apcli_auth = tmptable[1]  --safe_mode
		local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliEncrypType") or {""}
		apcli_enc = tmptable[1] -- encryption
		local tmptable = phicomm_lua.get_wifi_iface_config("2.4G", "ApCliWPAPSK") or {""}
		apcli_pskkey = tmptable[1] -- password
		apcli_band = "0"
	elseif apcli_5G_enable == "1" then
		local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliBssidBak") or {""}
		apcli_bssid = tmptable[1] --mac
		local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliSsid") or {""}
		apcli_ssid = tmptable[1] --ssid
		local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliAuthMode") or {"OPEN"}
		apcli_auth = tmptable[1]  --safe_mode
		local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliEncrypType") or {""}
		apcli_enc = tmptable[1] -- encryption
		local tmptable = phicomm_lua.get_wifi_iface_config("5G", "ApCliWPAPSK") or {""}
		apcli_pskkey = tmptable[1] -- password
		apcli_band = "1"
	else
		apcli_bssid = "" --mac
		apcli_ssid = "" --ssid
		apcli_auth = "OPEN"  --safe_mode
		apcli_enc = "" -- encryption
		apcli_pskkey = "" -- password
		apcli_band = ""
	end


	if apcli_auth == "WPA2PSK" then
		apcli_auth = "WPA2-PSK"
	elseif apcli_auth == "WPAPSK" or apcli_auth == "WPA1PSK" then
		apcli_auth = "WPA-PSK"
	elseif apcli_auth == "WPA" then
		apcli_auth = "WPAENT"
	elseif apcli_auth == "WPAPSKWPA2PSK" or apcli_auth == "WPA1PSKWPA2PSK" then
		apcli_auth = "WAPWPA2-PSK"
	elseif apcli_auth == "OPEN" then
		apcli_auth = "OPEN"
	else
		apcli_auth = apcil_auth
	end


	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local protocol = cursor:get("network", "vpn", "proto")
	if nil ~= protocol then
		protocol = protocol
	else
		protocol = cursor:get("network", "wan", "proto")
	end

	--proto
	local proto = protocol
	--ip
	local ipaddr = nil
	--gateway
	local gateway = nil
	if "pptp" == proto or "l2tp" == proto then
		local addrs = status_vpn["ipv4-address"]
		ipaddr = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"
		for _, v in ipairs(status_vpn["route"] or { }) do
			if v.target == "0.0.0.0" and v.mask == 0 then
				gateway = v.nexthop or "0.0.0.0"
			end
		end
	else
		local addrs = status["ipv4-address"]
		ipaddr = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"
		for _, v in ipairs(status["route"] or { }) do
			if v.target == "0.0.0.0" and v.mask == 0 then
				gateway = v.nexthop or "0.0.0.0"
			end
		end
	end
	--apcli_link
	local apcli_link = nil

	if wisp["wisp_link"] == "up" then
		apcli_link = "1"
	else
		apcli_link = "0"
	end

	local result = {
		enable = tostring(tonumber(apcli_2_4G_enable) + tonumber(apcli_5G_enable)),
		band = apcli_band,
		bssid = apcli_bssid,
		ssid = apcli_ssid,
		safe_mode = apcli_auth,
		encryption = apcli_enc,
		password = apcli_pskkey,
		protocol = proto,
		ip = ipaddr,
		gateway = gateway,
		connected = apcli_link
	}

	return err.E_NONE, result
end

function get_ap_list_plt(args, uciname, secname)
	local apcli = require("apcli")

	local function trans_safe_mode(mode)
		if "WPAPSKWPA2PSK" == mode or "WPA1PSKWPA2PSK" == mode then
			return "WPAWPA2-PSK"
		elseif "WPAPSK" == mode or "WPA1PSK" == mode then
			return "WPA-PSK"
		elseif "WPA2PSK" == mode then
			return "WPA2-PSK"
		elseif "WPA" == mode then
			return "WPAENT"
		elseif "OPEN" == mode then
			return "OPEN"
		else
			return mode
		end
	end

	local function trans_band(band)
		if 1 == band then
			return "0"
		elseif 2 == band then
			return "1"
		end
	end

	local ap, result = nil, {}
	local ap_list = apcli.get_ap_list("2.4&5")

	for _, ap in ipairs(ap_list) do
		result[#result+1] = {
			bssid = ap.bssid,
			ssid = ap.ssid,
			safe_mode = trans_safe_mode(ap.authmode),
			encryption = ap.security,
			signal = ap.quality,
			channel = ap.channel,
			band = trans_band(ap.aptype)
	}
	end

	local fs = require("luci.fs")
	fs.unlink("/tmp/wisp/aplist")
	fs.unlink("/tmp/wisp/count")
	fs.unlink("/tmp/wisp/timestamp")
	fs.rmdir("/tmp/wisp")

	return err.E_NONE, result
end
