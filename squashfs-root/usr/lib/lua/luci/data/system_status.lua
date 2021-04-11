local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.system_status", package.seeall)

function index()
	register_secname_cb("router_info", "wan", "check_wan", "apply_system_status")
end

function check_wan(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			connection = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function apply_system_status(method, uciname, secname, web_para, diff_para, souce_data)
	local system_status_plt = require("luci.data.system_status_plt")
	local error, data
	error, data = system_status_plt.apply_system_status_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end
