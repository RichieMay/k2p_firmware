local err = require("luci.phicomm.error")

module("luci.controller.admin.protest", package.seeall)

function index()
	local node = node("protest")
	node.target = firstchild()
	node.sysauth = false
	node.index = true

	entry({"protest", "info"}, call("get_info")).leaf = true
end

function get_info()
	local http = require("luci.http")
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local result = {}
	result["module"] = {}
	result["module"]["protest"] = {}
	local data = {}
	local error_status = "0"

	data.sw_ver = cursor:get("system", "system", "fw_ver") or ""
	data.mac_wan = luci.util.exec("eth_mac r wan") or "00:00:00:00:00:00"
	data.mac_lan = luci.util.exec("eth_mac r lan") or "00:00:00:00:00:00"
	data.mac_2G = luci.util.exec("eth_mac r wlan_2") or "00:00:00:00:00:00"
	data.channel = luci.util.exec("iwconfig ra0 | grep Channel | cut -d \"=\" -f 2 | cut -d \" \" -f 1") or ""

	cursor:foreach("wireless","wifi-iface",
		function(h)
			if h.ifname == "ra0" then
				wifi_2g = h
				return
			end
		end)
	if wifi_2g ~= nil then
		data.ssid_2G = wifi_2g.ssid or ""
	else
		data.ssid_2G = ""
	end

	local telnetd = luci.util.exec("ps | grep telnetd | wc -l")
	if 3 < tonumber(telnetd) then
		data.telnet_status = "on"
	else
		data.telnet_status = "off"
	end

	local device = require("luci.controller.admin.device")
	local errcode, welcome = device.get_welcome_config()
	local guide = welcome.guide
	data.reset_flag = guide or ""

	if  data.sw_ver == "" or data.channel == "" or data.ssid_2G == "" or data.reset_flag == "" or data.mac_wan == "00:00:00:00:00:00" or data.mac_lan == "00:00:00:00:00:00" or data.mac_2G == "00:00:00:00:00:00" then
		error_status = "-1"
	end

	result["module"]["protest"]["info"] = data
	result["module"]["protest"]["error_code"] = error_status

	http.write_json(result)
	http.close()

	return err.E_NONE
end

