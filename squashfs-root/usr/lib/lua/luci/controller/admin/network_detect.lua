local err = require("luci.phicomm.error")

module("luci.controller.admin.network_detect", package.seeall)

function index()
	register_keyword_data("url_analysis", "config", "get_url_analysis_config")
	register_keyword_data("speed_detect", "config", "get_speed_detect_config")
	register_keyword_data("wireless_channel", "channel_2g_status", "get_channel_2g_status")
	register_keyword_data("wireless_channel", "channel_5g_status", "get_channel_5g_status")
end

function get_url_analysis_config(args, uciname, secname)
	local url_plt = require("luci.controller.admin.network_detect_plt")
	local error, data
	error, data = url_plt.get_url_analysis_plt(args, uciname, secname)

	return error, data
end

function get_speed_detect_config(args, uciname, secname)
	local speed_plt = require("luci.controller.admin.network_detect_plt")
	local error, data
	error, data = speed_plt.get_speed_detect_plt(args, uciname, secname)

	return error, data
end

function get_channel_2g_status(args, uciname, secname)
	local channel_plt = require("luci.controller.admin.network_detect_plt")
	local error, data
	error, data = channel_plt.get_channel_2g_plt(args, uciname, secname)

	return error, data
end

function get_channel_5g_status(args, uciname, secname)
	local channel_plt = require("luci.controller.admin.network_detect_plt")
	local error, data
	error, data = channel_plt.get_channel_5g_plt(args, uciname, secname)

	return error, data
end
