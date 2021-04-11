local err = require("luci.phicomm.error")

module("luci.controller.admin.remote_mng", package.seeall)

function index()
	entry({"pc", "remoteMng.htm"}, template("pc/remoteMng")).leaf = true
	entry({"h5", "remoteMng.htm"}, template("h5/remoteMng")).leaf = true

	register_keyword_data("firewall", "remote_manager", "get_remote_manager_info")
end

function get_remote_manager_info(args, uciname, secname)
--[[
	local result = {
		enable = "1",
		ip = "255.255.255.255",
		port = "8181"
	}
--]]

	local errcode, data
	local plt = require("luci.controller.admin.remote_mng_plt")
	errcode, data = plt.get_remote_manager_info_plt(args, uciname, secname)
	return errcode, data

end