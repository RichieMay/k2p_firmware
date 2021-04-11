local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.safe_set", package.seeall)

function index()
	register_secname_cb("safe_set", "config", "check_safe_set", "apply_safe_set")
	register_secname_cb("safe_set", "arp_config", "check_arp_config", "apply_arp_config")
	register_secname_cb("safe_set", "arp_bind_list", "check_arp_bind_list", "apply_arp_bind_list")
	register_secname_cb("safe_set", "arp_block_list_config", "check_bind_list_config", "apply_bind_list_config")
end

function check_safe_set(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			dos = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			icmp_flood = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			icmp_threshold = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_icmp_threshold",
				[KEY_ARGS] = {5, 3600, err.E_SAFE_ICMP_RANGE}
			},
			udp_flood = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			udp_threshold = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_udp_threshold",
				[KEY_ARGS] = {5, 3600, err.E_SAFE_UDP_RANGE}
			},
			tcp_flood = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			tcp_threshold = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_tcp_threshold",
				[KEY_ARGS] = {5, 3600, err.E_SAFE_TCPSYN_RANGE}
			},
			ping_disable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	local validator = require("luci.phicomm.validator")

	if not validator.check_num_range(value, min, max) then
		return error_code
	end

	return err.E_NONE
end

function check_icmp_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	if "0" == web_para.enable or "0" == web_para.dos or "0" == web_para.icmp_flood then
		return err.E_NONE
	end
	local error_code = check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	return error_code
end

function check_udp_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	if "0" == web_para.enable or "0" == web_para.dos or "0" == web_para.udp_flood then
		return err.E_NONE
	end
	local error_code = check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	return error_code
end

function check_tcp_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	if "0" == web_para.enable or "0" == web_para.dos or "0" == web_para.tcp_flood then
		return err.E_NONE
	end
	local error_code = check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	return error_code
end

function apply_safe_set(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.safe_set_plt")
	errcode, result = plt.apply_safe_set_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_arp_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			arp_defence = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			arp_flood = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			arp_threshold = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_arp_threshold",
				[KEY_ARGS] = {1, 1000, err.E_SAFE_ARPTHRESHOLD_RANGE}
			},
			arp_cheating = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			arp_interval = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_arp_interval",
				[KEY_ARGS] = {1, 10, err.E_SAFE_ARPINTERVAL_RANGE}
			},
			block_list = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_block_list"
			}
		}
	)

	return err.E_NONE
end

function check_arp_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	if "0" == web_para.arp_defence or "0" == web_para.arp_flood then
		return err.E_NONE
	end
	local error_code = check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	return error_code
end

function check_arp_interval(value, web_para, diff_para, souce_data, min, max, error_code)
	if "0" == web_para.arp_defence or "0" == web_para.arp_cheating then
		return err.E_NONE
	end
	local error_code = check_threshold(value, web_para, diff_para, souce_data, min, max, error_code)
	return error_code
end

function check_block_list(value, web_para, diff_para, souce_data, min, max, error_code)
	--To do
	return err.E_NONE
end

function apply_arp_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.safe_set_plt")
	errcode, result = plt.apply_arp_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_arp_bind_list(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			ip = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_ip"
			},
			mac = {
				[KEY_VALIDATOR] = "luci.data.safe_set.check_mac"
			}
		}
	)

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	--To do
	return err.E_NONE
end

function check_mac(value, web_para, diff_para, souce_data)
	--To do
	return err.E_NONE
end

function apply_arp_bind_list(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.safe_set_plt")
	errcode, result = plt.apply_arp_bind_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_bind_list_config(value, web_para, diff_para, souce_data, min, max, error_code)
	return err.E_NONE
end

function apply_bind_list_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.safe_set_plt")
	errcode, result = plt.apply_bind_list_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end