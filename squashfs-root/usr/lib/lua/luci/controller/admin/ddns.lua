local err = require("luci.phicomm.error")
local dbg = require("luci.phicomm.debug")

module("luci.controller.admin.ddns", package.seeall)

function index()
	entry({"pc", "ddns.htm"}, template("pc/ddns")).leaf = true

	register_keyword_data("ddns", "config", "get_ddns_config")
end

--获取ddns信息
function get_ddns_config(args, uciname, secname)
	local ddns_plt = require("luci.controller.admin.ddns_plt")
	local error, data
	error, data = ddns_plt.get_ddns_conf_plt(args, uciname, secname);

	return error, data
end
