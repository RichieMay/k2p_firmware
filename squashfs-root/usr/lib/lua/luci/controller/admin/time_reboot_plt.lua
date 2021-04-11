local err = require("luci.phicomm.error")

module("luci.controller.admin.time_reboot_plt", package.seeall)

function index()

end

function get_reboot_config_plt(args, uciname, secname)
	local result = {
		enable = "0",
		reboot_hour = 0,
		reboot_minute = 0
	}
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor:get("timereboot","timereboot","enable")
	result.reboot_hour = cursor:get("timereboot","timereboot","hour")
	result.reboot_minute = cursor:get("timereboot","timereboot","minute")

	return err.E_NONE, result
end