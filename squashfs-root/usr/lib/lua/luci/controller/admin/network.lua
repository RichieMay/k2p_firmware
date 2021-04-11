local err = require("luci.phicomm.error")
local http = require("luci.http")
local ds = require("luci.controller.ds")
module("luci.controller.admin.network", package.seeall)

function index()
	entry({"pc", "networkSet.htm"}, template("pc/networkSet")).leaf = true
	entry({"pc", "guideNetworkSet.htm"}, template("pc/guideNetworkSet")).leaf = true
	entry({"h5", "networkSet.htm"}, template("h5/networkSet")).leaf = true
	entry({"h5", "guideNetworkSet.htm"}, template("h5/guideNetworkSet")).leaf = true
	entry({"data", "network"}, call("ds_network"), "network set").leaf = true
	register_keyword_data("network", "wan", "get_wan_config")
	register_keyword_data("network", "static", "get_static_config")
	register_keyword_data("network", "dhcp", "get_dhcp_config")
	register_keyword_data("network", "pppoe", "get_pppoe_config")
	register_keyword_data("network", "pptp", "get_pptp_config")
	register_keyword_data("network", "l2tp", "get_l2tp_config")

	register_keyword_data("network", "wan_status", "get_wan_status")
	register_keyword_data("network", "wan_detection", "get_wan_detection")
	register_keyword_data("network", "wan_status_ap", "get_wan_status_ap")
end

function ex_network(para, method, retdata)
	local ret = retdata or {}
	local need_apply = 0
	if "set" == method and err.E_NONE == retdata.error_code then
		local module_data = retdata.module["network"];
		for _, value in pairs(module_data) do
			if "table" == type(value) and value["need_apply"] == 1 then
				need_apply = 1
			end
		end
		if module_data["need_apply"] == 1 or need_apply == 1 then
			local ap_network = require("luci.data.network")
			ret = ap_network.apply_network_config(para, method, retdata)
		end
	end
	return ret
end

function ds_network()
	ds.ds(ex_network)
end

function get_wan_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_wan_config_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_static_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_static_config_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_dhcp_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_dhcp_config_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_pppoe_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_pppoe_config_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_pptp_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_pptp_config_plt(args, uciname, secname)
	return err.E_NONE, data
end
function get_l2tp_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_l2tp_config_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_wan_status(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_wan_status_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_wan_detection(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_wan_detection_plt(args, uciname, secname)
	return err.E_NONE, data
end

function get_wan_status_ap(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.network_plt")
	errcode, data = plt.get_wan_status_ap_plt(args, uciname, secname)
	return err.E_NONE, data
end
