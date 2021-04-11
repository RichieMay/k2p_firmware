local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.signal_condition", package.seeall)

function index()
	register_secname_cb("signal_condition", "config", "check_signal_condition", "apply_signal_condition")
end

function check_signal_condition(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			signal_intensity = {
				[KEY_VALIDATOR] = "luci.data.signal_condition.check_signal_intensity"
			}
		}
	)
	return err.E_NONE
end

function check_signal_intensity(value, web_para, diff_para, souce_data)
	if "1" ~= value and "2" ~= value and "3" ~= value then
		return err.E_SIGNAL_CONDITION_ILLEGAL
	end

	return err.E_NONE
end

function apply_signal_condition(method, uciname, secname, web_para, diff_para, souce_data)
	local signal_condition_plt = require("luci.data.signal_condition_plt")
	local error, data
	error, data = signal_condition_plt.apply_signal_condition_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end