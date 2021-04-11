local err = require("luci.phicomm.error")

module("luci.controller.admin.find_pppoe_pwd", package.seeall)

function index()
	entry({"pc", "checkRouterLink.htm"}, template("pc/checkRouterLink")).leaf = true
	entry({"pc", "findPppoePwd.htm"}, template("pc/findPppoePwd")).leaf = true
	entry({"h5", "checkRouterLink.htm"}, template("h5/checkRouterLink")).leaf = true
	entry({"h5", "findPppoePwd.htm"}, template("h5/findPppoePwd")).leaf = true

	register_keyword_data("find_pwd", "link_status", "get_link_status")
	register_keyword_data("find_pwd", "config", "get_find_pwd_conf")
end

function get_link_status(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.find_pppoe_pwd_plt")
	errcode, data = plt.get_link_status_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_find_pwd_conf(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.find_pppoe_pwd_plt")
	errcode, data = plt.get_find_pwd_conf_plt(args, uciname, secname)
	return err.E_NONE, data
end
