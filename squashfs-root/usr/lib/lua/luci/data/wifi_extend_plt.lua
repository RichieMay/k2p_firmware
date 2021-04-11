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

module("luci.data.wifi_extend_plt", package.seeall)

function index()

end


--错误适配
function err_app(code)

	--[[
		E_NONE					0,
		1/2/3/6/7/8/9
		E_WISP_SWITCH
		E_WISP_SSID_BLANK
		E_WISP_SSID_LEN
		E_WISP_PWD_LEN
		E_WISP_PWD_BLANK
		E_WISP_PWD_ILLEGAL
		E_WISP_PSK_MODE				1,
		10
		E_WISP_NOT_FOUND			2,
		4
		E_WISP_BAND					3,
		5
		E_WISP_SAFE_MODE			4,

	]]--

		if err.E_WISP_SWITCH == code or err.E_WISP_SSID_BLANK == code
			or err.E_WISP_SSID_LEN == code or err.E_WISP_PWD_LEN == code
			or err.E_WISP_PWD_BLANK == code or err.E_WISP_PWD_ILLEGAL == code
			or err.E_WISP_PSK_MODE == code then
			return 1
		elseif err.E_WISP_NOT_FOUND == code then
			return 2
		elseif err.E_WISP_BAND == code then
			return 3
		elseif E_WISP_SAFE_MODE == code then
			return 4
		else
			return 0
		end

end

--@app:just for app response, true/false
function write_response(code, app)
	local http = require("luci.http")

	if app then
		co = code
		code = err_app(co)
	end

	local data = {}
	data[err.ERR_CODE] = code
	data["module"] = {}
	
	http.prepare_content("text/html")

	http.write_json(data)
	http.close()
end

function apply_wisp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local http = require("luci.http")
	local apcli_lua = require("apcli")
	local cursor = uci.cursor()
	local enable = web_para.enable
	local error_not_found = -89
	local aptype = "0"
	local ret = "0"

	local phiapp = false
	if http.getenv("PHIAPP_REQUEST") then
		phiapp = true
	end

	if enable == "0" then
		apcli_lua.config_normal()
	else
		local ssid = web_para.ssid
		local bssid = web_para.bssid
		local aptype = "0"
		local authmode = web_para.safe_mode

		if authmode == "WPA2-PSK" or authmode == "WPAWPA2-PSK"then
			authmode = "WPA2PSK"
		elseif  authmode == "WPA-PSK" then
			authmode = "WPAPSK"
		elseif authmode == "WPAENT" then
			authmode = "WPA"
		else
			authmode = "OPEN"
		end

		local encryp = web_para.encryption

		if encryp == "TKIPAES" or encryp == "AES" then
			encrpt = "AES"
		elseif encryp == "TKIP" then
			encryp = "TKIP"
		else
			encryp = "NONE"
		end

		local wpapsk = web_para.password or ""

		ret = apcli_lua.config_apcli(ssid,bssid,authmode,encryp,wpapsk,aptype)
	end


	if phiapp then
		if error_not_found == ret.result then
			write_response(err.E_WISP_NOT_FOUND, phiapp)
			return err.E_WISP_NOT_FOUND
		else
			os.execute("(sleep 1; reboot) &")
			write_response(err.E_NONE, phiapp)
			return err.E_NONE, {wait_time = 60}
		end
	else
		if error_not_found == ret.result then
			return err.E_WISP_NOT_FOUND
		else
			os.execute("(sleep 1; reboot) &")
			return err.E_NONE, {wait_time = 60}
		end
	end
end
