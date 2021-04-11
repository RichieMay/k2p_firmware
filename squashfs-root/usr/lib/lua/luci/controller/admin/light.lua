local err = require("luci.phicomm.error")

module("luci.controller.admin.light", package.seeall)

function index()
	entry({"pc", "light.htm"}, template("pc/light")).leaf = true
	entry({"h5", "light.htm"}, template("h5/light")).leaf = true

	register_keyword_data("light", "config", "get_light_config")
end

function get_light_config(args, uciname, secname)
	local light_plt = require("luci.controller.admin.light_plt")
	local error, data
	error, data = light_plt.get_light_conf_plt(args, uciname, secname)

	return error, data
end
