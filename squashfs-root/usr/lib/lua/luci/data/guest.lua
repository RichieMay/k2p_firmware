--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   guest-network.lua
* VERSION    :   1.0
* DESCRIPTION:   访客网络的回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.guest", package.seeall)

function index()
	register_secname_cb("wireless", "guest_wifi", "check_guest", "apply_guest_config")
	register_secname_cb("wireless", "guest_wifi_5g", "check_guest_5g", "apply_guest_5g_config")
	register_secname_cb("wireless", "guest_time_switch", "check_guest_time_switch", "apply_guest_time_switch")
	register_secname_cb("wireless", "guest_speed_limit", "check_guest_speed_limit", "apply_guest_speed_limit")
end

function check_guest(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ssid = {
				[KEY_VALIDATOR] = "luci.data.guest.check_guest_ssid"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.guest.check_guest_pwd"
			}
		}
	)

	return err.E_NONE
end

function check_guest_ssid(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	local result = validator.check_ssid(value)

	if result == err.E_SSID_BLANK then
		return err.E_GUEST_SSID_BLANK
	end

	if result == err.E_SSID_LEN then
		return err.E_GUEST_SSID_LEN
	end

	if result == err.E_SSID_ILLEGAL then
		return err.E_WLVISSSIDILLEGAL
	end

	--访客网络SSID和无线SSID不能相等
	local wireless = require("luci.controller.admin.wireless")
	if wireless then
		local code, data = wireless.get_wifi_2g_config()
		local wireless_ssid = data.ssid
		if wireless_ssid == value then
			return err.E_GUESET_SSID_WIFI2G_SAME
		end
	end
	local dev_fea = require("luci.controller.admin.dev_feature")
	local err_code, dual_band_support = dev_fea.get_dual_band_feature()
	if wireless and "1" == dual_band_support.support then
		local code, data = wireless.get_wifi_5g_config()
		local wireless_ssid = data.ssid
		if wireless_ssid == value then
			return err.E_GUESET_SSID_WIFI5G_SAME
		end
	end

	return err.E_NONE
end

function check_guest_pwd(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	local result = validator.check_wlan_pwd(value)

	if result == err.E_WIFI_PWD_LEN then
		return err.E_GUEST_PWD_LEN
	end

	if result == err.E_WIFI_PWD_ILLEGAL then
		return err.E_GUEST_PWD_ILLEGAL
	end

	return err.E_NONE
end

function check_guest_5g(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			ssid = {
				[KEY_VALIDATOR] = "luci.data.guest.check_guest_ssid_5g"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.guest.check_guest_pwd_5g"
			}
		}
	)

	return err.E_NONE
end

function check_guest_ssid_5g(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	local result = validator.check_ssid(value)

	if result == err.E_SSID_BLANK then
		return err.E_GUEST5G_SSID_BLANK
	end

	if result == err.E_SSID_LEN then
		return err.E_GUEST5G_SSID_LEN
	end

	if result == err.E_SSID_ILLEGAL then
		return err.E_WLVISSSIDILLEGAL
	end

	--访客网络SSID和无线SSID不能相等
	local wireless = require("luci.controller.admin.wireless")
	if wireless then
		local code, data = wireless.get_wifi_2g_config()
		local wireless_ssid = data.ssid
		if wireless_ssid == value then
			return err.E_GUESET5G_SSID_WIFI2G_SAME
		end
	end
	local dev_fea = require("luci.controller.admin.dev_feature")
	local err_code, dual_band_support = dev_fea.get_dual_band_feature()
	if wireless and "1" == dual_band_support.support then
		local code, data = wireless.get_wifi_5g_config()
		local wireless_ssid = data.ssid
		if wireless_ssid == value then
			return err.E_GUESET5G_SSID_WIFI5G_SAME
		end
	end

	return err.E_NONE
end

function check_guest_pwd_5g(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	local result = validator.check_wlan_pwd(value)

	if result == err.E_WIFI_PWD_LEN then
		return err.E_GUEST5G_PWD_LEN
	end

	if result == err.E_WIFI_PWD_ILLEGAL then
		return err.E_GUEST5G_PWD_ILLEGAL
	end

	return err.E_NONE
end

function check_guest_time_switch(method, uciname, secname, web_para, diff_para, souce_data)
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

function check_guest_speed_limit(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
	{
		enable = {
			[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
		},
		upload_limit = {
			[KEY_VALIDATOR] = "luci.data.guest.check_speed",
			[KEY_ARGS] = {0, 10000, "UP"}
		},
		download_limit = {
			[KEY_VALIDATOR] = "luci.data.guest.check_speed",
			[KEY_ARGS] = {0, 10000, "DOWN"}
		},
	})

	return err.E_NONE
end

function check_speed(value, web_para, diff_para, souce_data, min, max, limit_type)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, min, max) then
		if "UP" == limit_type then
			return err.E_GUEST_UP_LIMIT_RANG
		else
			return err.E_GUEST_DOWN_LIMIT_RANG
		end
	end

	return err.E_NONE
end

function apply_guest_config(method, uciname, secname, web_para, diff_para, souce_data)
	local guest_plt = require("luci.data.guest_plt")
	local error, data
	error, data = guest_plt.apply_guest_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function apply_guest_5g_config(method, uciname, secname, web_para, diff_para, souce_data)
	local guest_plt = require("luci.data.guest_plt")
	local error, data
	error, data = guest_plt.apply_guest_5g_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function apply_guest_time_switch(method, uciname, secname, web_para, diff_para, souce_data)
	local guest_plt = require("luci.data.guest_plt")
	local error, data
	error, data = guest_plt.apply_guest_time_switch_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function apply_guest_speed_limit(method, uciname, secname, web_para, diff_para, souce_data)
	local guest_plt = require("luci.data.guest_plt")
	local error, data
	error, data = guest_plt.apply_guest_speed_limit_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end