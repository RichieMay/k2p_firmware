local err = require("luci.phicomm.error")

module("luci.controller.admin.port_forward", package.seeall)

function index()
	entry({"pc", "portForwad.htm"}, template("pc/portForwad")).leaf = true

	register_keyword_data("port_forward", "config", "get_forward_config")
	register_keyword_data("port_forward", "forward_list", "get_forward_list")
end

function get_forward_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.port_forward_plt")
	errcode, data = plt.get_forward_config_plt(args, uciname, secname)
	return errcode, data
end

function get_forward_list(args, uciname, secname)
--[[
	返回值范例
	local result = {
		{
			id = "1",
			name = "AAAAAA",
			ip = "192.168.2.100",
			extern_port_start = "1",
			extern_port_end = "1",
			inner_port_start = "10",
			inner_port_end = "10",
			protocol = "1"
		},
		{
			id = "2",
			name = "BBBBBB",
			ip = "192.168.2.200",
			extern_port_start = "1",
			extern_port_end = "1",
			inner_port_start = "10",
			inner_port_end = "10",
			protocol = "1"
		}
	}
]]--

	local errcode, data
	local plt = require("luci.controller.admin.port_forward_plt")
	errcode, data = plt.get_forward_list_plt(args, uciname, secname)
	return errcode, data
end
