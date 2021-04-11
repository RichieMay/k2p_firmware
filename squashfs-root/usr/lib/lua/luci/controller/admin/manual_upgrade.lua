local err = require("luci.phicomm.error")

module("luci.controller.admin.manual_upgrade", package.seeall)

function index()
	entry({"pc", "manualUpgrade.htm"}, template("pc/manualUpgrade")).leaf = true
	entry({"system", "upgrade"}, call("system_upgrade")).leaf = true

	register_keyword_data("system", "upgrade_status", "get_upgrade_status")
end

function system_upgrade()
	local manual_upgrade = require("luci.controller.admin.manual_upgrade_plt")
	local error, data
	error, data = manual_upgrade.system_upgrade_plt();

	return error, data
end

function get_upgrade_status()
	local manual_upgrade = require("luci.controller.admin.manual_upgrade_plt")
	local error, data
	error, data = manual_upgrade.get_upgrade_status_plt();

	return error, data
end