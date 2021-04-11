local err = require("luci.phicomm.error")

module("luci.data.time_sleep_plt", package.seeall)

function index()
end

function apply_time_sleep_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()

	if web_para.enable ~= nil then
		cursor:set("sleep_timer", "timer", "enable", web_para.enable)
	end

	local minute, hour, stop_time, start_time
	if web_para.close_time ~= nil then
		hour = web_para.close_time / 3600 - web_para.close_time / 3600 % 1
		minute = web_para.close_time % 3600 / 60
		stop_time = minute .. ' ' .. hour
		cursor:set("sleep_timer", "timer", "stopTime", stop_time)
	end

	if web_para.open_time ~= nil then
		hour = web_para.open_time / 3600 - web_para.open_time / 3600 % 1
		minute = web_para.open_time % 3600 / 60
		start_time = minute .. ' ' .. hour
		cursor:set("sleep_timer", "timer", "startTime", start_time)
	end

	cursor:commit("sleep_timer")

	os.execute("/usr/bin/sleep_timer load &")

	return err.E_NONE, {wait_time = 2}
end
