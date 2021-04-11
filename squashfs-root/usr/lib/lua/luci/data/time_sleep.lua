local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.time_sleep", package.seeall)

function index()
	register_secname_cb("time_sleep", "config", "check_time_sleep", "apply_time_sleep_config")
end

function check_time_sleep(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
	{
		enable = {
			[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
		},
		close_time = {
			[KEY_VALIDATOR] = "luci.data.time_sleep.check_close_time"
		},
		open_time = {
			[KEY_VALIDATOR] = "luci.data.time_sleep.check_open_time"
		},
	})

	return err.E_NONE
end

function check_close_time(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_TIME_SLEEP_CLOSE_TIME
	end

	return err.E_NONE
end

function check_open_time(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_TIME_SLEEP_OPEN_TIME
	end

	return err.E_NONE
end

function apply_time_sleep_config(method, uciname, secname, web_para, diff_para, souce_data)
	local time_plt = require("luci.data.time_sleep_plt")
	local error, data
	error, data = time_plt.apply_time_sleep_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end
