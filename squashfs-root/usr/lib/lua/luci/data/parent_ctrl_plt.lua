local err = require("luci.phicomm.error")
local cursor = require("luci.model.uci").cursor()
--local util = require("luci.util")
module("luci.data.parent_ctrl_plt", package.seeall)
local src_mac_t = {}

function index()

end

function apply_parent_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("parentctl", "config", "enabled", web_para.enable)
	cursor:save("parentctl")
	cursor:commit("parentctl")
	cursor:apply("parentctl", false, true)

	return err.E_NONE
end

function freshruleindex(version)
	local count = 0
	local uci_t = require("luci.model.uci")
	local cur = uci_t.cursor()
	local sec_type = ""
	if version == "V1" then
		sec_type = "rule"
	else
		sec_type = "setting"
	end
	cur:foreach("parentctl", sec_type,
		function(s)
		count = count + 1
			cur:set("parentctl", s[".name"], "ruleindex", count)
		end)
	cur:commit("parentctl")
end

function add_rules(web_para)
	local section = ""
	local cycle_str = ""
	local index_cycle = 1
	local version = web_para["version"]
	local sec_type
	if version == "V1" then
		sec_type = "rule"
	else
		sec_type = "setting"
	end
	while true do
		_, index_cycle = string.find(tostring(web_para.cycle), "1", index_cycle)
		if index_cycle == nil then
			break
		else
			if cycle_str == "" then
				cycle_str = tostring(index_cycle)
			else
				cycle_str = cycle_str..","..index_cycle
			end
			index_cycle = index_cycle + 1
		end
	end
	local hour,minute
	hour = math.floor(tonumber(web_para.start_time)/3600)
	minute = (web_para.start_time - hour*3600) / 60
	local start_time = hour .. ":" .. minute
	hour = math.floor(tonumber(web_para.end_time)/3600)
	minute = (web_para.end_time - hour*3600) / 60
	local stop_time = hour .. ":" .. minute
	if tonumber(web_para.id) then
		cursor:foreach("parentctl", sec_type,
			function(s)
				if s.ruleindex == web_para.id then
					section = s[".name"]
					return
				end
		end)
	else
		section = cursor:add("parentctl", sec_type)
	end

	local map = {
		mac = "src_mac",
	}
	local k, v
	for k, v in pairs(web_para) do
		if nil ~= map[k] then
			cursor:set("parentctl", section, map[k], v)
		end
	end

	local macStr = string.gsub(web_para.mac, ":", "_")
	if cursor:get("common_host", macStr, "hostname") == nil then
		if web_para.name ~= nil and web_para.name ~= "Unknown" then
			cursor:section("common_host", "host", macStr, {hostname = web_para.name})
			cursor:commit("common_host")
		end
	end
	cursor:set("parentctl", section, "start_time", start_time)
	cursor:set("parentctl", section, "stop_time", stop_time)
	cursor:set("parentctl", section, "weekdays", cycle_str)
end

function delete_rules(web_para)
	local section = ""
	local src_mac
	local version = web_para["version"]
	local sec_type

	if version == "V1" then
		sec_type = "rule"
	else
		sec_type = "setting"
	end

	for id in string.gmatch(web_para.id, "(%d+)|*") do
		cursor:foreach("parentctl", sec_type, function(s)
			if s.ruleindex == id then
				section = s[".name"]
				return
			end
		end)

		src_mac = cursor:get("parentctl", section, "src_mac")
		cursor:delete("parentctl", section)
		if #src_mac_t == 0 then
			src_mac_t[#src_mac_t + 1] = src_mac
		end
		for i=1,#src_mac_t do
			if src_mac_t[i] == src_mac then
				break
			elseif i == #src_mac_t then
				src_mac_t[#src_mac_t + 1] = src_mac
			end
		end
	end
end

function apply_parent_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local version
	rule_list = web_para.rule_list
	if next(rule_list) ~= nil then
		local version_t = rule_list[1]
			version = version_t["version"]
		else
			version = nil
	end

	if method ~= "del" then
		for i=1, #rule_list do
			rule_list[i]["version"] = version
			add_rules(rule_list[i])
		end
	else
		if #rule_list > 0 then
			for i=1, #rule_list do
				rule_list[i]["version"] = version
				delete_rules(rule_list[i])
			end
		end
	end

		cursor:save("parentctl")
		cursor:commit("parentctl")
	if method ~= "del" and #rule_list > 0 then
		local src_mac = rule_list[1].mac
		if version == "V1" then
				local cmd = "parentctl_config_update -w " .. src_mac
				luci.sys.call(cmd)
		else
				local cmd = "parentctl_config_update -n " .. src_mac
				luci.sys.call(cmd)
		end
	else
		for i=1,#src_mac_t do
			src_mac = src_mac_t[i]
			if version == "V1" then
				if src_mac ~= nil then
					local cmd = "parentctl_config_update -w " .. src_mac
					luci.sys.call(cmd)
				end
			else
				if src_mac ~= nil then
					local cmd = "parentctl_config_update -n " .. src_mac
					luci.sys.call(cmd)
				end
			end
		end
	end
		freshruleindex("V1")
		freshruleindex("V2")

	cursor:apply("parentctl", false, true)

	return err.E_NONE
end
