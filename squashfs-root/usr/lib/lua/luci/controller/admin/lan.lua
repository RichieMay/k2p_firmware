local err = require("luci.phicomm.error")

module("luci.controller.admin.lan", package.seeall)

function index()
	entry({"pc", "lanSet.htm"}, template("pc/lanSet")).leaf = true
	entry({"h5", "lanSet.htm"}, template("h5/lanSet")).leaf = true

	register_keyword_data("network", "lan", "get_lan_config")
end

function get_lan_config(args, uciname, secname)
	local lan_plt = require("luci.controller.admin.lan_plt")
	local error, data
	error, data = lan_plt.get_lan_conf_plt(args, uciname, secname);

	return error, data
end