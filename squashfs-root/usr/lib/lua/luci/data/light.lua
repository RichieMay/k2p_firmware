local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.light", package.seeall)

function index()
	register_secname_cb("light", "config", "check_light_config", "apply_light_config")
end

function check_light_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function apply_light_config(method, uciname, secname, web_para, diff_para, souce_data)
	local light_plt = require("luci.data.light_plt")
	local error, data
	error, data = light_plt.apply_light_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end
