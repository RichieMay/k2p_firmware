local err = require("luci.phicomm.error")

module("luci.controller.admin.shared_wifi", package.seeall)

function index()
	register_keyword_data("shared_wifi", "config", "get_shared_wifi")
end

function get_shared_wifi(args, uciname, secname)
	local shared_wifi_plt = require("luci.controller.admin.shared_wifi_plt")
	local error, data
	error, data = shared_wifi_plt.get_shared_wifi_plt(args, uciname, secname)

	return error, data
end