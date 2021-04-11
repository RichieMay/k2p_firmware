local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.upnp", package.seeall)

function index()
	register_secname_cb("upnp", "config", "check_upnp_config", "apply_upnp_config")
end

function check_upnp_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function apply_upnp_config(method, uciname, secname, web_para, diff_para, souce_data)
	local upnp_plt = require("luci.data.upnp_plt")
	local error, data
	error, data = upnp_plt.apply_upnp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end