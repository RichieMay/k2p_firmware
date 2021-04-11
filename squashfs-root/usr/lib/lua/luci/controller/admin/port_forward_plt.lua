local err = require("luci.phicomm.error")

module("luci.controller.admin.port_forward_plt", package.seeall)

function index()

end

function get_forward_config_plt(args, uciname, secname)
	local result = {
		--enable = "0"
	}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor: get("appportfwd", "config", "enable")

	return err.E_NONE, result
end

function get_forward_list_plt(args, uciname, secname)
	local result = {}

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local val_map = {["tcp"] = "1", ["udp"] = "2", ["tcp+udp"] = "3"}
	local util = require "luci.util"
	cursor:foreach("appportfwd", "setting", function(s)
		local tmp_exterport = util.split(s.exterport, "-")
		local tmp_interport = util.split(s.interport, "-")
		local c ={
			id = s.id,
			name = s.name,
			ip = s.serverip,
			extern_port_start = tmp_exterport[1],
			extern_port_end = tmp_exterport[2] or tmp_exterport[1],
			inner_port_start = tmp_interport[1],
			inner_port_end = tmp_interport[2] or tmp_interport[1],
			protocol = val_map[s.proto]
		}
		result[#result + 1] = c
	end)

	return err.E_NONE, result
end
