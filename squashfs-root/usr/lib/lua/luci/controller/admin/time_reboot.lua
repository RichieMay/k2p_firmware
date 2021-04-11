local err = require("luci.phicomm.error")

module("luci.controller.admin.time_reboot", package.seeall)

function index()
	entry({"pc", "timeReboot.htm"}, template("pc/timeReboot")).leaf = true
	entry({"h5", "timeReboot.htm"}, template("h5/timeReboot")).leaf = true
	register_keyword_data("time_reboot", "config", "get_reboot_config")
end

function get_reboot_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.time_reboot_plt")
	errcode, data = plt.get_reboot_config_plt(args, uciname, secname)
	return errcode, data
end
