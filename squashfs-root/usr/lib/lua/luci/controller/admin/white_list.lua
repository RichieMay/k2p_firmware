local err = require("luci.phicomm.error")

module("luci.controller.admin.white_list", package.seeall)

function index()
	entry({"pc", "whiteList.htm"}, template("pc/whiteList")).leaf = true
	entry({"pc", "onlineList.htm"}, template("pc/onlineList")).leaf = true
	entry({"h5", "whiteList.htm"}, template("h5/whiteList")).leaf = true
	entry({"h5", "onlineList.htm"}, template("h5/onlineList")).leaf = true

	register_keyword_data("white_list", "config", "get_white_list_config")
end

function get_white_list_config(args, uciname, secname)
	local white_list_plt = require("luci.controller.admin.white_list_plt")
	local error, data
	error, data = white_list_plt.get_white_list_config_plt(args, uciname, secname)

	return error, data
end