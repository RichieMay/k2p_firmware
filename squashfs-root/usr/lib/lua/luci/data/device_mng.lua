local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.device_mng", package.seeall)

function index()
	register_secname_cb("device_manage", "client_list", "check_client", "apply_client_config")
end

function check_client(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			mac = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_mac"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.device_mng.check_ip"
			},
			name = {
				[KEY_VALIDATOR] = "luci.data.device_mng.check_name"
			},
			upload_limit = {
				[KEY_VALIDATOR] = "luci.data.device_mng.check_speed",
				[KEY_ARGS] = {0, 4096}
			},
			download_limit = {
				[KEY_VALIDATOR] = "luci.data.device_mng.check_speed",
				[KEY_ARGS] = {0, 4096}
			},
			internet_enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	if "string" ~= type(value) then
		return err.E_INVFMT
	end

	if "" == value then
		return err.E_NONE
	end

	local validator = require("luci.phicomm.validator")
	local result = validator.check_ip(value)

	return result
end


function check_name(value, web_para, diff_para, souce_data)
	if "string" ~= type(value) then
		return err.E_INVFMT
	end

	if 0 == #value then
		return err.E_DIVICE_NAME_BLANK
	end

	if #value > 32 then
		return err.E_DIVICE_NAME_LEN
	end

	return err.E_NONE
end

function check_speed(value, web_para, diff_para, souce_data, min, max)
	local validator = require("luci.phicomm.validator")

	if not validator.check_num_range(value, min, max) then
		return err.E_DIVICE_UP_LIMIT_RANGE
	end

	return err.E_NONE
end

function apply_client_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.device_mng_plt")
	errcode, result = plt.apply_client_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode
end


