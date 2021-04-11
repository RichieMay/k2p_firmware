local err = require("luci.phicomm.error")

module("luci.controller.admin.dhcp", package.seeall)

function index()
	entry({"pc", "dhcp.htm"}, template("pc/dhcp")).leaf = true

	register_keyword_data("dhcpd", "config", "get_dhcpd_config")
	register_keyword_data("dhcpd", "bind_list", "get_bind_list")
end

function get_dhcpd_config(args, uciname, secname)
	local dhcp_plt = require("luci.controller.admin.dhcp_plt")
	local error, data
	error, data = dhcp_plt.get_dhcp_conf_plt(args, uciname, secname);

	return error, data
end

function get_bind_list(args, uciname, secname)
	local dhcp_plt = require("luci.controller.admin.dhcp_plt")
	local error, data
	error, data = dhcp_plt.get_bind_list_plt(args, uciname, secname);

	return error, data
end