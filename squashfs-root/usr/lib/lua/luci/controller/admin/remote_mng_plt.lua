local err = require("luci.phicomm.error")

module("luci.controller.admin.remote_mng_plt", package.seeall)

function index()

end

function get_remote_manager_info_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local result = {
		appenable=cursor:get("remote","remote","app_enable"),
		enable = cursor:get("remote", "remote", "remote_enable"),
		ip = cursor:get("remote", "remote", "remote_ip"),
		port = cursor:get("remote", "remote", "remote_port")
	}

	return err.E_NONE, result
end

