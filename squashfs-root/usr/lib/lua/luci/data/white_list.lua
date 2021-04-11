local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.white_list", package.seeall)

function index()
	register_secname_cb("white_list", "config", "check_white_list_config", "apply_white_list_config")
end

function check_white_list_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			clear_all = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			white_list = {
				[KEY_VALIDATOR] = "luci.data.white_list.check_white_list"
			},
			block_list = {
				[KEY_VALIDATOR] = "luci.data.white_list.check_block_list"
			}
		}
	)
	return err.E_NONE
end

function apply_white_list_config(method, uciname, secname, web_para, diff_para, souce_data)
	local white_list_plt = require("luci.data.white_list_plt")
	local error, data
	error, data = white_list_plt.apply_white_list_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end

function check_white_list(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_block_list(value, web_para, diff_para, souce_data)
	return err.E_NONE
end
