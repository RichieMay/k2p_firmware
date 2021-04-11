local err = require("luci.phicomm.error")

module("luci.controller.admin.url_block_plt", package.seeall)

function index()
end

function get_url_config_plt(args, uciname, secname)
	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	result.enable = cursor:get("url_filter", "url_switch", "enabled") or "0"

	return err.E_NONE, result
end

function get_url_list_plt(args, uciname, secname)
	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:foreach("url_filter", "devfilter", function(s)
		local dev_sec_name = string.gsub(s.mac, ":", "_")
		local name = cursor:get("device_manage", dev_sec_name, "hostname") or "UnKown"
		local brand = cursor:get("device_manage", dev_sec_name, "brand") or "UnKown"
		local c = {
			id = #result + 1,
			name = cursor:get("common_host", dev_sec_name, "hostname") or name,
			mac = s.mac,
			brand = brand,
			block_url = s.url
		}
		result[#result + 1] = c
	end)

	return err.E_NONE, result
end
