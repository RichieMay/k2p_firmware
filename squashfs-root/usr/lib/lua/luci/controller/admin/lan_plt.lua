local err = require("luci.phicomm.error")

module("luci.controller.admin.lan_plt", package.seeall)

function index()
end

function get_lan_conf_plt(args)
	local result = {}

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	result.ip = cursor:get("network","lan","ipaddr") or "0.0.0.0"
	result.netmask = cursor:get("network","lan","netmask") or "0.0.0.0"
	result.gateway = cursor:get("network","lan","gateway") or ""
	result.dnsip = cursor:get("network","lan","dns") or ""
	result.mac = string.upper(cursor:get("network","lan","macaddr") or "00:00:00:00:00:00")

	return err.E_NONE, result
end
