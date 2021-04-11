local err = require("luci.phicomm.error")

module("luci.controller.admin.light_plt", package.seeall)

function index()
end

function get_light_conf_plt(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()

	local result = {
		enable = cursor:get("light_manage","pagelight","ignore"),
		control= cursor:get("light_manage","pagelight","control")
	}

	return err.E_NONE, result
end
