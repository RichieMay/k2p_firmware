local err = require("luci.phicomm.error")

module("luci.controller.admin.upnp", package.seeall)

function index()
	entry({"pc", "upnp.htm"}, template("pc/upnp")).leaf = true

	register_keyword_data("upnp", "config", "get_upnp_config")
	register_keyword_data("upnp", "upnp_list", "get_upnp_list")
end

function get_upnp_config(args, uciname, secname)
	local upnp_plt = require("luci.controller.admin.upnp_plt")
	local error, data
	error, data = upnp_plt.get_upnp_conf_plt(args, uciname, secname)

	return error, data
end

function get_upnp_list(args, uciname, secname)
	local upnp_plt = require("luci.controller.admin.upnp_plt")
	local error, data
	error, data = upnp_plt.get_upnp_list_plt(args, uciname, secname)

	return error, data
end
