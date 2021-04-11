local err = require("luci.phicomm.error")

module("luci.controller.admin.time_sleep", package.seeall)

function index()
	entry({"pc", "timeSleep.htm"}, template("pc/timeSleep")).leaf = true
	entry({"h5", "timeSleep.htm"}, template("h5/timeSleep")).leaf = true

	register_keyword_data("time_sleep", "config", "get_time_sleep_conf")
end

function get_time_sleep_conf(args, uciname, secname)
	local time_plt = require("luci.controller.admin.time_sleep_plt")
	local error, data
	error, data = time_plt.get_time_sleep_conf_plt(args, uciname, secname)

	return error, data
end