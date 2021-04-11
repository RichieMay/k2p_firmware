local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.auto_upgrade", package.seeall)

function index()
	register_secname_cb("system", "upgrade", "check_upgrade", "apply_upgrade")
end

function check_upgrade_time(value, web_para, diff_para, souce_data)
	if "0" == web_para.mode then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_UPGRADE_TIME_ILLEGAL
	end

	return err.E_NONE
end

function check_upgrade(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			mode = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			upgrade_time = {
				[KEY_VALIDATOR] = "luci.data.auto_upgrade.check_upgrade_time"
			}
		}
	)

	return err.E_NONE
end

function apply_upgrade(method, uciname, secname, web_para, diff_para, souce_data)
	local auto_upgrade_plt = require("luci.data.auto_upgrade_plt")
	local error, data
	error, data = auto_upgrade_plt.apply_upgrade_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end