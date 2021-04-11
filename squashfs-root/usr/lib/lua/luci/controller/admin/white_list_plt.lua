local err = require("luci.phicomm.error")

module("luci.controller.admin.white_list_plt", package.seeall)

function index()
end

function get_white_list_config_plt(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {}

	result.enable = cursor:get("white_list", "comm_info", "enable") or ""

	os.execute("/usr/bin/white_list_set update_wl > /dev/null")
	local white_list = {}
	local block_list = {}
	cursor:foreach("white_list", "white_list", function(w)
		local white_list_entry = {}
		local section
		white_list_entry.ip = w.ip
		white_list_entry.mac = w.mac
		white_list_entry.name = w.hostname
		white_list_entry.brand = w.brand
		white_list_entry.onlineTime = w.online_time
		section = w['.name']
		txRate = cursor:get("device_manage", section, "tx_rate")
		if(txRate ~= nil) then
			white_list_entry.txRate = txRate
		else
			white_list_entry.txRate = 0
		end

		rxRate = cursor:get("device_manage", section, "rx_rate")
		if(txRate ~= nil) then
			white_list_entry.rxRate = rxRate
		else
			white_list_entry.rxRate = 0
		end

		iftype = cursor:get("device_manage", section, "if_type")
		if(txRate ~= nil) then
			white_list_entry.iftype = iftype
		else
			white_list_entry.iftype = 3
		end

		table.insert(white_list, white_list_entry)
	end)
	result.white_list = white_list

	cursor:foreach("white_list", "block_list", function(b)
		local white_list_entry = {}
		white_list_entry.mac = b.mac
		white_list_entry.blockTime = b.block_time
		white_list_entry.brand = b.brand
		table.insert(block_list, white_list_entry)
	end)
	result.block_list = block_list

	return err.E_NONE, result
end
