local e=require("luci.phicomm.error")
module("luci.controller.admin.freesocks",package.seeall)

function index()
	entry({"pc","freesocks.htm"},template("pc/freesocks")).leaf=true
	entry({"h5","freesocks.htm"},template("h5/freesocks")).leaf=true
	register_keyword_data("freesocks","config","get_freesocks_config")
	register_keyword_data("freesocks", "freesocks_list", "get_freesocks_list")
end

local err = require("luci.phicomm.error")
function get_freesocks_config(args, uciname, secname)
	local l=require("luci.model.uci").cursor()
	local l={
		server_index=l:get("freesocks","global","server_index")
	}

	return e.E_NONE,l
end

function get_freesocks_list(args, uciname, secname)
	local result = {}

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	cursor:foreach("freesocks", "servers", function(s)
		local c ={
			name = s.alias,
			ip = s.server_ip,
			port = s.server_port,
			password = s.key
		}
		result[#result + 1] = c
	end)

	return err.E_NONE, result
end


