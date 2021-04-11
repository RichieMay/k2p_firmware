local err = require("luci.phicomm.error")

module("luci.controller.admin.shared_wifi_plt", package.seeall)

function index()

end

function get_shared_wifi_plt(args, uciname, secname)
	local err = require("luci.phicomm.error")
	local cursor = uci.cursor()
	local result = {}

	local enable = cursor:get("sharedwifi", "wifidog", "enable") or ""
	result.enable = enable

	return err.E_NONE, result
end
