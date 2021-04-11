local err = require("luci.phicomm.error")

module("luci.controller.admin.time_sleep_plt", package.seeall)

function index()
end

function get_time_sleep_conf_plt(args, uciname, secname)
	local err = require("luci.phicomm.error")
	local util = require "luci.util"

	local cursor = uci.cursor()
	local minute, hour, open_time, close_time
	local result = {}

	local enable = cursor:get("sleep_timer", "timer", "enable") or ""
	result.enable = enable

	local stop_time = cursor:get("sleep_timer", "timer", "stopTime") or ""
	stop_time = util.split(stop_time, " ")
	hour = tonumber(stop_time[2]) or 0
	minute = tonumber(stop_time[1]) or 0
	close_time = hour * 3600 + minute * 60
	result.close_time = close_time

	local start_time = cursor:get("sleep_timer", "timer", "startTime") or ""
	start_time = util.split(start_time, " ")
	hour = tonumber(start_time[2]) or 0
	minute = tonumber(start_time[1]) or 0
	open_time = hour * 3600 + minute * 60
	result.open_time = open_time

	return err.E_NONE, result
end
