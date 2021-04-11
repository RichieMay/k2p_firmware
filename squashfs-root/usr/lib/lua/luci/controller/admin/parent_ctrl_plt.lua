local err = require("luci.phicomm.error")

module("luci.controller.admin.parent_ctrl_plt", package.seeall)
function index()

end

function get_parent_config_plt(args, uciname, secname)
	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor: get("parentctl", "config", "enabled")
	return err.E_NONE, result
end

function get_parent_list_plt(args, uciname, secname)
	local version = args["version"]

	local sec_type = ""
	if version == "V1" then
		sec_type = "rule"
	else
		sec_type = "setting"
	end

	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local util = require "luci.util"
	cursor:foreach("parentctl", sec_type, function(s)
		local cycle_list = {0,0,0,0,0,0,0}
		local tmp = util.split(s.weekdays, ",")
		for i,v in ipairs(tmp) do
			cycle_list[tonumber(v)] = "1"
		end
		local cycle_str = ""
		for i,v in ipairs(cycle_list) do
			cycle_str = cycle_str..cycle_list[i]
		end

		local tmp_start_time = util.split(s.start_time, ":")
		local start_time = tonumber(tmp_start_time[1])*3600 + tonumber(tmp_start_time[2])*60
		local tmp_end_time = util.split(s.stop_time, ":")
		local end_time = tonumber(tmp_end_time[1])*3600 + tonumber(tmp_end_time[2])*60

		local section_name = string.gsub(s.src_mac, ":", "_")
		local name = cursor:get("device_manage", section_name, "hostname") or "UnKnown"
		local brand = cursor:get("device_manage", section_name, "brand") or "UnKnown"

		local c = {
			id = s.ruleindex,
			mac = s.src_mac,
			brand = brand,
			name = cursor:get("common_host", section_name, "hostname") or name,
			cycle = cycle_str,
			start_time = start_time,
			end_time = end_time
			}
			result[#result + 1] = c
	end)

	return err.E_NONE, result
end
