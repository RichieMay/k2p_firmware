local err = require("luci.phicomm.error")

module("luci.controller.admin.guest", package.seeall)

function index()
	entry({"pc", "guest.htm"}, template("pc/guest")).leaf = true
	entry({"h5", "guest.htm"}, template("h5/guest")).leaf = true

	register_keyword_data("wireless", "guest_wifi", "get_guest_wifi_conf")
	register_keyword_data("wireless", "guest_wifi_5g", "get_guest_wifi_5g_conf")
	register_keyword_data("wireless", "guest_time_switch", "get_guest_time_switch")
	register_keyword_data("wireless", "guest_speed_limit", "get_guest_speed_limit")
end

function get_guest_wifi_conf(args, uciname, secname)
	local guest_plt = require("luci.controller.admin.guest_plt")
	local error, data
	error, data = guest_plt.get_guest_wifi_conf_plt(args, uciname, secname)

	return error, data
end

function get_guest_wifi_5g_conf(args, uciname, secname)
	local guest_plt = require("luci.controller.admin.guest_plt")
	local error, data
	error, data = guest_plt.get_guest_wifi_5g_conf_plt(args, uciname, secname)

	return error, data
end

function get_guest_time_switch(args, uciname, secname)
	local guest_plt = require("luci.controller.admin.guest_plt")
	local error, data
	error, data = guest_plt.get_guest_time_switch_plt(args, uciname, secname)

	return error, data
end

function get_guest_speed_limit(args, uciname, secname)
	local guest_plt = require("luci.controller.admin.guest_plt")
	local error, data
	error, data = guest_plt.get_guest_speed_limit_plt(args, uciname, secname)

	return error, data
end