local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.parent_ctrl", package.seeall)

function index()
	register_secname_cb("parent_ctrl", "config", "check_parent_config", "apply_parent_config")
	register_secname_cb("parent_ctrl", "parent_list", "check_parent_list", "apply_parent_list")
end

function check_parent_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function check_parent_list(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			rule_list = {
				[KEY_VALIDATOR] = "luci.data.parent_ctrl.check_rule_list"
			}
		}
	)
	return err.E_NONE
end

function apply_parent_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.parent_ctrl_plt")
	errcode, result = plt.apply_parent_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_parent_list(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.parent_ctrl_plt")
	errcode, result = plt.apply_parent_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_id(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_rule_list(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_name(value, web_para, diff_para, souce_data)
	if "string" ~= type(value) then
		return err.E_PARENTCTRL_NAME_ILLEGAL
	end

	if "" == value then
		return err.E_PARENTCTRL_NAME_BLANK
	end

	if #value > 32 then
		return err.E_PARENTCTRL_NAME_LEN
	end

	return err.E_NONE
end

function check_mac(value, web_para, diff_para, souce_data)
	local result = validator.check_mac(value)

	if result ~= err.E_NONE then
		return err.E_PARENTCTRL_MAC_ILLEGAL
	end

	return err.E_NONE
end

function check_cycle(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_start_time(value, web_para, diff_para, souce_data)
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_PARENTCTRL_START_TIME
	end

	return err.E_NONE
end

function check_end_time(value, web_para, diff_para, souce_data)
	if not validator.check_num_range(value, 0, 86400) then
		return err.E_PARENTCTRL_END_TIME
	end

	if tonumber(value) <= tonumber(web_para.start_time) then
		return err.E_PARENTCTRL_START_END_LESS
	end

	local index, val
	for index, val in ipairs (souce_data) do
		if val.id ~= web_para.id then
			if val.mac == web_para.mac and
			 val.cycle == web_para.cycle and
			 tonumber(val.start_time) == tonumber(web_para.start_time) and
			 tonumber(val.end_time) == tonumber(web_para.end_time) then
				return err.E_PARENTCTRL_RULE_SAME
			end
		end
	end

	return err.E_NONE
end
