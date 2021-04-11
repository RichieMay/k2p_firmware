local err = require("luci.phicomm.error")

module("luci.controller.admin.dmz", package.seeall)

function index()
	entry({"pc", "dmz.htm"}, template("pc/dmz")).leaf = true

	register_keyword_data("firewall", "dmz", "get_dmz_config")
end

function get_dmz_config(args, uciname, secname)
	local dmz_plt = require("luci.controller.admin.dmz_plt")
	local error, data
	error, data = dmz_plt.get_dmz_conf_plt(args, uciname, secname);

	return error, data
end