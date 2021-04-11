local err = require("luci.phicomm.error")

module("luci.controller.admin.safe_set", package.seeall)

function index()
	entry({"pc", "safeMng.htm"}, template("pc/safeMng")).leaf = true

	register_keyword_data("safe_set", "config", "get_safe_config")
	register_keyword_data("safe_set", "arp_config", "get_arp_config")
	register_keyword_data("safe_set", "arp_bind_list", "get_arp_bind_list")
end

function get_safe_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.safe_set_plt")
	errcode, data = plt.get_safe_config_plt(args, uciname, secname)
	return errcode, data
end

function get_arp_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.safe_set_plt")
	errcode, data = plt.get_arp_config_plt(args, uciname, secname)
	return errcode, data
end

function get_arp_bind_list(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.safe_set_plt")
	errcode, data = plt.get_bind_list_plt(args, uciname, secname)
	return errcode, data
end
