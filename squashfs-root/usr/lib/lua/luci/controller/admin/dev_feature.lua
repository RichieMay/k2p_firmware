local err = require("luci.phicomm.error")

module("luci.controller.admin.dev_feature", package.seeall)

function index()
	register_keyword_data("dev_feature", "time", "get_feature")
	register_keyword_data("dev_feature", "smart_connect", "get_feature")
	register_keyword_data("dev_feature", "wifi_2g", "get_feature")
	register_keyword_data("dev_feature", "wifi_5g", "get_feature")
	register_keyword_data("dev_feature", "wifi", "get_feature")
	register_keyword_data("dev_feature", "data_collect", "get_feature")
	register_keyword_data("dev_feature", "system_info", "get_feature")
	register_keyword_data("dev_feature", "time_zone", "get_feature")
	register_keyword_data("dev_feature", "ddns", "get_feature")
	register_keyword_data("dev_feature", "usb", "get_usb_feature")
	register_keyword_data("dev_feature", "guide", "get_feature")
	register_keyword_data("dev_feature", "app_pc", "get_feature")
	register_keyword_data("dev_feature", "app_h5", "get_feature")
	register_keyword_data("dev_feature", "auto_upgrade", "get_feature")
	register_keyword_data("dev_feature", "network_set", "get_feature")
	register_keyword_data("dev_feature", "guest_wifi", "get_guest_wifi_feature")
	register_keyword_data("dev_feature", "quick_button", "get_feature")
	register_keyword_data("dev_feature", "wifi_timing", "get_feature")
	register_keyword_data("dev_feature", "lan_set", "get_feature")
	register_keyword_data("dev_feature", "route_info", "get_feature")
	register_keyword_data("dev_feature", "signal_condition", "get_feature")
	register_keyword_data("dev_feature", "summer_time", "get_feature")
	register_keyword_data("dev_feature", "wifi_extend", "get_feature")
	register_keyword_data("dev_feature", "app_ap", "get_feature")
	register_keyword_data("dev_feature", "mode_switch", "get_mode_switch_feature")
	register_keyword_data("dev_feature", "dual_band", "get_dual_band_feature")
	register_keyword_data("dev_feature", "url_block", "get_url_block_feature")
end

function get_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = cursor:get_all(uciname, secname)

	return err.E_NONE, result
end

function get_dual_band_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {
		support = cursor:get("dev_feature","dual_band","support") or "1"
	}

	return err.E_NONE, result
end

function get_guest_wifi_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {
		disable_wispon = cursor:get("dev_feature","guest_wifi","disable_wispon") or "0"
	}
	result.support_timing = cursor:get("dev_feature","guest_wifi","support_timing") or "0"
	result.guest_5g = cursor:get("dev_feature","guest_wifi","guest_5g") or "0"
	result.support_speed_limit = cursor:get("dev_feature","guest_wifi","support_speed_limit") or "0"

	return err.E_NONE, result
end

function get_mode_switch_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {
		support = cursor:get("dev_feature","mode_switch","support") or "0"
	}

	return err.E_NONE, result
end

function get_usb_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local result = {
		qr_code = cursor:get("dev_feature","usb","qr_code") or "0"
	}
	result.example = cursor:get("dev_feature","usb","example") or "0"

	return err.E_NONE, result
end

function get_url_block_feature(args, uciname, secname)
	local cursor = require("luci.model.uci").cursor()
	local default_shopping_url = {
		"taobao",
		"tmall",
		"yhd",
		"vip",
		"jd",
		"dangdang",
		"amazon",
		"suning",
		"gome",
		"jumei"
	}

	local default_media_url = {
		"youku",
		"tudou",
		"iqiyi",
		"v.qq",
		"acfun",
		"bilibili",
		"tv.sohu",
		"v.baidu",
		"le",
		"wasu",
		"pptv",
		"fun"
	}

	local default_game_url = {
		"17173",
		"ali213",
		"3dmgame",
		"gamersky",
		"pcgames",
		"duowan",
		"yxdown",
		"4399",
		"tgbus",
		"uuu9"
	}

	local result = {
		shopping_url = cursor:get("dev_feature","url_block","shopping_url") or default_shopping_url,
		media_url = cursor:get("dev_feature","url_block","media_url") or default_media_url,
		game_url = cursor:get("dev_feature","url_block","game_url") or default_game_url
	}

	return err.E_NONE, result
end