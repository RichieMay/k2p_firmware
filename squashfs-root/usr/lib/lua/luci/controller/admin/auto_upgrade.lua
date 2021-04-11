local err = require("luci.phicomm.error")

module("luci.controller.admin.auto_upgrade", package.seeall)

function index()
	entry({"pc", "sysUpgrade.htm"}, template("pc/sysUpgrade")).leaf = true
	entry({"h5", "sysUpgrade.htm"}, template("h5/sysUpgrade")).leaf = true

	register_keyword_data("system", "upgrade", "get_upgrade_config")
	register_keyword_data("system", "upgrade_info", "do_online_upgrade")
end

function get_upgrade_config(args, uciname, secname)
	local auto_upgrade_plt = require("luci.controller.admin.auto_upgrade_plt")
	local error, data
	error, data = auto_upgrade_plt.get_upgrade_conf_plt(uciname, secname, args);

	return error, data
end

function do_online_upgrade(para)
	local auto_upgrade_plt = require("luci.controller.admin.auto_upgrade_plt")
	local error, data
	error, data = auto_upgrade_plt.get_online_upgrade_plt(para);

	return error, data
end