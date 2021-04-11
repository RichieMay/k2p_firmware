local err = require("luci.phicomm.error")

module("luci.data.auto_upgrade_plt", package.seeall)

function index()
end

function apply_upgrade_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()
	local time
	local hour
	local minute
	local second

	cursor:set("system","upgrade","mode", web_para.mode)

	if web_para.mode == "1" then
		if "string" == type(web_para.upgrade_time) then
			time = tonumber(web_para.upgrade_time)
		elseif "number" == type(web_para.upgrade_time) then
			time = web_para.upgrade_time
		else
			return err.E_INVARG
		end

		second = time % 60
		time = (time - second) / 60
		minute = time % 60
		time = (time - minute) / 60
		hour = time

		cursor:set("system","upgrade","start_hour", tostring(hour))
		cursor:set("system","upgrade","start_minute", tostring(minute))
		cursor:set("system","upgrade","start_second", tostring(second))
	end
	cursor:save("system")
	cursor:commit("system")
	os.execute("/usr/sbin/regular_check &")

	return err.E_NONE
end
