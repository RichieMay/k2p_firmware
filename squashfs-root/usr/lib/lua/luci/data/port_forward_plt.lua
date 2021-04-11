local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.port_forward_plt", package.seeall)

function index()

end

function apply_forward_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("appportfwd", "config", "enable", web_para.enable)
	cursor:save("appportfwd")
	cursor:commit("appportfwd")
	cursor:apply("appportfwd", false, true)
	return err.E_NONE
end

function apply_forward_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local section
	if method ~= "del" then
		if tonumber(web_para.id) then
				cursor:foreach("appportfwd", "setting",
				function(s)
					if s.id == web_para.id then
						section = s[".name"]
						return
					end
			end)
		else
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			web_para.id = tostring(math.random())
			section = cursor:add("appportfwd", "setting")
		end

		local map = {
			id = "id",
			name = "name",
			ip = "serverip",
			protocol = "proto"
		}

		local k, v
		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("appportfwd", section, map[k], v)
			end
		end

		local exterport, interport
		if web_para.extern_port_start == web_para.extern_port_end then
			exterport = web_para.extern_port_start
		else
			exterport = web_para.extern_port_start.."-"..web_para.extern_port_end
		end
		if web_para.inner_port_start == web_para.inner_port_end then
			interport = web_para.inner_port_start
		else
			interport = web_para.inner_port_start.."-"..web_para.inner_port_end
		end
		cursor:set("appportfwd", section, "exterport", exterport)
		cursor:set("appportfwd", section, "interport", interport)
		local val_map = {["1"] = "tcp", ["2"] = "udp", ["3"] = "tcp+udp"}
		cursor:set("appportfwd", section, "proto", val_map[web_para.protocol] or "")
	else
		if tonumber(web_para.id) then
			cursor:foreach("appportfwd", "setting",
			function(s)
				if s.id == web_para.id then
					section = s[".name"]
					return
				end
			end)
		end
		cursor:delete("appportfwd", section)
	end

	cursor:save("appportfwd")
	cursor:commit("appportfwd")
	cursor:apply("appportfwd", false, true)

	return err.E_NONE
end
