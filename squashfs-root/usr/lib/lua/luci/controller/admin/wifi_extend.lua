local err = require("luci.phicomm.error")

module("luci.controller.admin.wifi_extend", package.seeall)

function index()
	entry({"pc", "wisp.htm"}, template("pc/wisp")).leaf = true
	entry({"pc", "setExtend.htm"}, template("pc/setExtend")).leaf = true
	entry({"h5", "wisp.htm"}, template("h5/wisp")).leaf = true
	entry({"h5", "setExtend.htm"}, template("h5/setExtend")).leaf = true
	entry({"h5", "apList.htm"}, template("h5/apList")).leaf = true

	register_keyword_data("wisp", "config", "get_wisp_conf")
	register_keyword_data("wisp", "ap_list", "get_ap_list")
end

function get_wisp_conf(args, uciname, secname)
	local wifi_extend_plt = require("luci.controller.admin.wifi_extend_plt")
	local error, data
	error, data = wifi_extend_plt.get_wisp_conf_plt(args, uciname, secname)

	return error, data
end

function get_ap_list(args, uciname, secname)
	local wifi_extend_plt = require("luci.controller.admin.wifi_extend_plt")
	local error, data
	error, data = wifi_extend_plt.get_ap_list_plt(args, uciname, secname)

	return error, data
end
