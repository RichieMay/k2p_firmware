local err = require("luci.phicomm.error")

module("luci.controller.admin.signal", package.seeall)

function index()
	entry({"pc", "signalSet.htm"}, template("pc/signalSet")).leaf = true
	register_keyword_data("signal_set", "config", "get_signal_config")
end

function get_signal_config(args, uciname, secname)
	local signal_plt = require("luci.controller.admin.signal_plt")
	local error, data
	error, data = signal_plt.get_signal_conf_plt(args, uciname, secname)

	return error, data
end
