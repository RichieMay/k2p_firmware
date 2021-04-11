local err = require("luci.phicomm.error")

module("luci.controller.admin.ddns_plt", package.seeall)

function index()
end

function get_ddns_conf_plt(args)
	local cursor = require("luci.model.uci").cursor()

	local result = {
		enable = cursor:get("ddns","myddns","enabled") or "0",
		provider = cursor:get("ddns","myddns","service_name") or "",
		user = cursor:get("ddns","myddns","username") or "",
		password = cursor:get("ddns","myddns","password") or "",
		domain = cursor:get("ddns","myddns","domain") or ""
	}

	return err.E_NONE, result
end