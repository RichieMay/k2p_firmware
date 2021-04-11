local err = require("luci.phicomm.error")

module("luci.controller.admin.signal_condition", package.seeall)

function index()
	entry({"pc", "signalCondition.htm"}, template("pc/signalCondition")).leaf = true
	entry({"h5", "signalCondition.htm"}, template("h5/signalCondition")).leaf = true
	register_keyword_data("signal_condition", "config", "get_signal_condition")
end

function get_signal_condition(args, uciname, secname)
	local signal_condition_plt = require("luci.controller.admin.signal_condition_plt")
	local error, data
	error, data = signal_condition_plt.get_signal_condition_plt(args, uciname, secname)

	return error, data
end