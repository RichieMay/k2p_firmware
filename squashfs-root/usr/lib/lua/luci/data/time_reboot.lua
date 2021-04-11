local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local validator = require("luci.phicomm.validator")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.time_reboot", package.seeall)

function index()
	register_secname_cb("time_reboot", "config", "check_time_reboot", "apply_time_reboot")
end

function check_time_reboot(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			reboot_hour = {
				[KEY_VALIDATOR] = "luci.data.time_reboot.check_reboot_hour"
			},
			reboot_minute = {
				[KEY_VALIDATOR] = "luci.data.time_reboot.check_reboot_minute"
			}
		}
	)

	return err.E_NONE
end

function apply_time_reboot(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.time_reboot_plt")
	errcode, result = plt.apply_time_reboot_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode
end

function check_reboot_hour(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num_range(value, 0, 23) then
		return err.E_TIMEREBOOT_HOUR
	end

	return err.E_NONE
end

function check_reboot_minute(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end
	if not validator.check_num(value) then
		return err.E_TIMEREBOOT_MINUTE
	end

	local val = tonumber(value)
	local min
	for min = 0, 55, 5 do
		if val == min then
			return err.E_NONE
		end
	end

	return err.E_TIMEREBOOT_MINUTE
end


