local err = require("luci.phicomm.error")

module("luci.controller.admin.dmz_plt", package.seeall)

function index()
end

function get_dmz_conf_plt(args)
	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor: get("DMZ", "DMZ", "enable")
	result.ip = cursor: get("DMZ", "DMZ", "dmz_ip")

	return err.E_NONE, result
end