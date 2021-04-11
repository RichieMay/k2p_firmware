local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local validator = require("luci.phicomm.validator")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.wifi_extend", package.seeall)

function index()
	register_secname_cb("wisp", "config", "check_wisp_config", "apply_wisp_config")
end

function check_wisp_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			band = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_band"
			},
			ssid = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_ssid_wisp"
			},
			safe_mode = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_safe_mode"
			},
			encryption = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_encryption"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_pwd_wisp"
			},
			bssid = {
				[KEY_VALIDATOR] = "luci.data.wifi_extend.check_bssid"
			}
		}
	)

	return err.E_NONE
end

function check_band(value, web_para, diff_para, souce_data)
	local result = validator.check_bool(value)

	if "" ==  value then
		return err.E_NONE
	end

	if result ~= err.E_NONE then
		return err.E_INVBOOL
	end

	return err.E_NONE
end

function check_ssid_wisp(value, web_para, diff_para, souce_data)
	local result = validator.check_ssid(value)

	if result == err.E_SSID_BLANK then
		return err.E_WISP_SSID_BLANK
	end

	if result == err.E_SSID_LEN then
		return err.E_WISP_SSID_LEN
	end

	if result == err.E_SSID_ILLEGAL then
		return err.E_INVFMT
	end

	return err.E_NONE
end

function check_safe_mode(value, web_para, diff_para, souce_data)
	local safe_mode = {"OPEN", "WPA-PSK", "WPA2-PSK", "WPAWPA2-PSK", "WPAENT"}
	local mode

	for _, mode in pairs(safe_mode) do
		if mode == value then
			return err.E_NONE
		end
	end

	return err.E_WISP_SAFE_MODE
end

function check_encryption(value, web_para, diff_para, souce_data)
	local encryptions = {"NONE", "TKIP", "AES", "TKIPAES"}
	local encrypt

	for _, encrypt in pairs(encryptions) do
		if encrypt == value then
			return err.E_NONE
		end
	end

	return err.E_WISP_PSK_MODE
end

function check_pwd_wisp(value, web_para, diff_para, souce_data)
	if web_para.safe_mode ~= "OPEN" then
		if "" ==  value then
			return err.E_WISP_PWD_BLANK
		end

		local result = validator.check_wlan_pwd(value)

		if result == err.E_WIFI_PWD_LEN then
			return err.E_WISP_PWD_LEN
		end

		if result == err.E_WIFI_PWD_ILLEGAL then
			return err.E_WISP_PWD_ILLEGAL
		end

		return err.E_NONE
	end

	return err.E_NONE
end

function check_bssid(value, web_para, diff_para, souce_data)
	local result = validator.check_mac(value)

	if "" ==  value then
		return err.E_NONE
	end

	if result ~= err.E_NONE then
		return err.E_DIVICE_MAC_ILLEGAL
	end

	return err.E_NONE
end

function apply_wisp_config(method, uciname, secname, web_para, diff_para, souce_data)
	local wifi_extend_plt = require("luci.data.wifi_extend_plt")
	local error, data
	error, data = wifi_extend_plt.apply_wisp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end