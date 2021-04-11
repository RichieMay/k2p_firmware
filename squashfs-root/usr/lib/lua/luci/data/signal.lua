local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.signal", package.seeall)

function index()
	register_secname_cb("signal_set", "config", "check_signal_config", "apply_signal_config")
end

function check_signal_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			power = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function apply_signal_config(method, uciname, secname, web_para, diff_para, souce_data)
	local signal_plt = require("luci.data.signal_plt")
	local error, data
	error, data = signal_plt.apply_signal_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end
