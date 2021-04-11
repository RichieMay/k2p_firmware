--[[
**********************************************************************************
* Copyright (c) 2017 Shanghai Phicomm Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   wireless.lua
* VERSION    :   1.0
* DESCRIPTION:   WiFi的配置函数
*
* AUTHOR     :   feng.kang <feng.kang@phicomm.com>
* CREATE DATE:   01/24/2017
*
* HISTORY    :
* 01   01/24 /2017  KangFeng  Create.
**********************************************************************************
--]]
local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local validator = require("luci.phicomm.validator")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args
local K_MODULE = ds.KEY_MODULE

module("luci.data.wireless", package.seeall)

function index()
	register_secname_cb("wireless", "smart_connect", "check_smart_connect", "apply_smart_connect")
	register_secname_cb("wireless", "wifi_config", "check_wifi_config", "apply_wifi_config")
	register_secname_cb("wireless", "wifi_2g_config", "check_wifi_2g_config", "apply_wifi_2g_config")
	register_secname_cb("wireless", "wifi_5g_config", "check_wifi_5g_config", "apply_wifi_5g_config")
	register_secname_cb("wireless", "wireless_time_switch", "check_wireless_time_switch", "apply_wireless_time_switch")
end

function check_smart_connect(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_wifi_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			country_code = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_country_code"
			}
		}
	)

	return err.E_NONE
end

function check_wifi_2g_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ssid = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_ssid_2g"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_pwd_2g"
			},
			hidden = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mode = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_mode_2g"
			},
			channel = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_channel_2g"
			},
			band_width = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_band_width_2g"
			},
			ap_isolate = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			power = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mu_mimo = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			beamforming = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_wifi_5g_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ssid = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_ssid_5g"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_pwd_5g"
			},
			hidden = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mode = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_mode_5g"
			},
			channel = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_channel_5g"
			},
			band_width = {
				[KEY_VALIDATOR] = "luci.data.wireless.check_band_width_5g"
			},
			ap_isolate = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			power = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			mu_mimo = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			beamforming = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_ssid_2g(value, web_para, diff_para, souce_data)
	local result = validator.check_ssid(value)

	if result == err.E_SSID_BLANK then
		return err.E_WIFI2G_SSID_BLANK
	end

	if result == err.E_SSID_LEN then
		return err.E_WIFI2G_SSID_LEN
	end

	if result == err.E_SSID_ILLEGAL then
		return err.E_INVFMT
	end

	--无线SSID和访客网络SSID不能相等
	local guest = require("luci.controller.admin.guest")
	if guest then
		local code, data = guest.get_guest_wifi_conf()
		if data ~= nil then
			local guest_ssid = data.ssid
			local guest_enable = data.enable
			if guest_ssid == value and "1" == guest_enable then
				return err.E_WIFI2G_SSID_GUEST_SAME
			end
		end
	end
	local dev_fea = require("luci.controller.admin.dev_feature")
	local err_code, guest_wifi = dev_fea.get_guest_wifi_feature()
	if guest and "1" == guest_wifi.guest_5g then
		local code, data = guest.get_guest_wifi_5g_conf()
		local guest_ssid = data.ssid
		local guest_enable = data.enable
		if guest_ssid == value and "1" == guest_enable then
			return err.E_WIFI2G_SSID_GUEST5G_SAME
		end
	end

	return err.E_NONE
end

function check_pwd_2g(value, web_para, diff_para, souce_data)
	local result = validator.check_wlan_pwd(value)

	if result == err.E_WIFI_PWD_LEN then
		return err.E_WIFI2G_PWD_LEN
	end

	if result == err.E_WIFI_PWD_ILLEGAL then
		return err.E_WIFI2G_PWD_ILLEGAL
	end

	return err.E_NONE
end

function check_mode_2g(value, web_para, diff_para, souce_data)
	if "0" ~= value and "1" ~= value and "2" ~= value then
		return err.E_WIFI2G_MODE
	end

	return err.E_NONE
end

function check_channel_2g(value, web_para, diff_para, souce_data)
	if not validator.check_num_range(value, 0, 13) then
		return err.E_WIFI2G_CHANNEL
	end

	return err.E_NONE
end

function check_country_code(value, web_para, diff_para, souce_data)
	local dev_feature = require("luci.controller.admin.dev_feature")
	local errcode, ccl = dev_feature.get_feature({}, "dev_feature", "wifi")
	local country_code_list = ccl.country_code or nil
	if country_code_list == nil then
		return err.E_INVFMT
	end

	for k,v in pairs(country_code_list) do
		if value == v then
			return err.E_NONE
		end
	end

	return err.E_INVFMT
end

function check_band_width_2g(value, web_para, diff_para, souce_data)
	if "0" ~= value and "1" ~= value and "2" ~= value then
		return err.E_WIFI2G_BANDWIDTH
	end

	return err.E_NONE
end

function check_ssid_5g(value, web_para, diff_para, souce_data)
	local result = validator.check_ssid(value)

	if result == err.E_SSID_BLANK then
		return err.E_WIFI5G_SSID_BLANK
	end

	if result == err.E_SSID_LEN then
		return err.E_WIFI5G_SSID_LEN
	end

	if result == err.E_SSID_ILLEGAL then
		return err.E_INVFMT
	end

	--无线SSID和访客网络SSID不能相等
	local guest = require("luci.controller.admin.guest")
	if guest then
		local code, data = guest.get_guest_wifi_conf()
		if data ~= nil then
			local guest_ssid = data.ssid
			local guest_enable = data.enable
			if guest_ssid == value and "1" == guest_enable then
				return err.E_WIFI5G_SSID_GUEST_SAME
			end
		end
	end
	local dev_fea = require("luci.controller.admin.dev_feature")
	local err_code, guest_wifi = dev_fea.get_guest_wifi_feature()
	if guest and "1" == guest_wifi.guest_5g then
		local code, data = guest.get_guest_wifi_5g_conf()
		local guest_ssid = data.ssid
		local guest_enable = data.enable
		if guest_ssid == value and "1" == guest_enable then
			return err.E_WIFI5G_SSID_GUEST5G_SAME
		end
	end

	return err.E_NONE
end

function check_pwd_5g(value, web_para, diff_para, souce_data)
	if "" ==  value then
		return err.E_NONE
	end

	if #value < 8 or #value > 64 then
		return err.E_WIFI5G_PWD_LEN
	end

	local result = validator.check_wlan_pwd(value)
	if result ~= err.E_NONE then
		return err.E_WIFI5G_PWD_ILLEGAL
	end

	return err.E_NONE
end

function check_mode_5g(value, web_para, diff_para, souce_data)
	if "0" ~= value and "1" ~= value then
		return err.E_WIFI5G_MODE
	end

	return err.E_NONE
end

function check_channel_5g(value, web_para, diff_para, souce_data)
	local channel = {"0","36","40","44","48","52","56","60","64","149","153","157","161","165"}
	for _, v in ipairs(channel) do
		if v == value then
			return err.E_NONE
		end
	end

	return err.E_WIFI5G_CHANNEL
end

function check_band_width_5g(value, web_para, diff_para, souce_data)
	local band_width = {"0","1","2","3","4"}
	for _, v in ipairs(band_width) do
		if v == value then
			return err.E_NONE
		end
	end

	return err.E_WIFI5G_BANDWIDTH
end

function check_wireless_time_switch(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
	{
		enable = {
			[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
		},
		close_time = {
			[KEY_VALIDATOR] = "luci.data.wireless.check_close_time"
		},
		open_time = {
			[KEY_VALIDATOR] = "luci.data.wireless.check_open_time"
		},
	})

	return err.E_NONE
end

function check_close_time(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_WIFI_CLOSE_TIME
	end

	return err.E_NONE
end

function check_open_time(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_WIFI_OPEN_TIME
	end

	return err.E_NONE
end

function apply_smart_connect(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.wireless_plt")
	errcode, result = plt.apply_smart_connect_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_wifi_2g_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.wireless_plt")
	errcode, result = plt.apply_wifi_2g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end


function apply_wifi_5g_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.wireless_plt")
	errcode, result = plt.apply_wifi_5g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_wireless_time_switch(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.wireless_plt")
	errcode, result = plt.apply_wireless_time_switch_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_wifi_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.wireless_plt")
	errcode, result = plt.apply_wifi_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_wireless_config(para, method, retdata)
	local result = retdata
	local errcode, ret
	local plt = require("luci.data.wireless_plt")
	errcode, ret = plt.apply_wireless_config_plt(para, method, result)
	if err.E_NONE == errcode then
		result[K_MODULE].wireless.wait_time = ret.wait_time
	end
	return result
end