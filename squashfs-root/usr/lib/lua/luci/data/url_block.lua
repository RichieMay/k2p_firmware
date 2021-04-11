local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.url_block", package.seeall)

function index()
	register_secname_cb("url_block", "config", "check_url_block_config", "apply_url_block_config")
	register_secname_cb("url_block", "url_list", "check_url_list", "apply_url_list")
end

function check_url_block_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function check_url_list(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			id = {
				[KEY_VALIDATOR] = "luci.data.url_block.check_id"
			},
			name = {
				[KEY_VALIDATOR] = "luci.data.url_block.check_name"
			},
			mac = {
				[KEY_VALIDATOR] = "luci.data.url_block.check_mac"
			},
			block_url = {
				[KEY_VALIDATOR] = "luci.data.url_block.check_block_url"
			}
		}
	)
	return err.E_NONE
end

function apply_url_block_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.url_block_plt")
	errcode, result = plt.apply_url_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_url_list(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.url_block_plt")
	errcode, result = plt.apply_url_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_id(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_name(value, web_para, diff_para, souce_data)
	if "string" ~= type(value) then
		return err.E_URLBOLCK_NAME_ILLEGAL
	end

	if 0 == #value or #value > 32 then
		return err.E_URLBOLCK_NAME_LEN
	end

	return err.E_NONE
end

function check_mac(value, web_para, diff_para, souce_data)
	local result = validator.check_mac(value)
	if err.E_NONE ~= result then
		return err.E_URLBOLCK_MAC_ILLEGAL
	end

	--for i,v in ipairs(souce_data) do
	--	if v.id ~= web_para.id then
	--		if string.lower(v.mac) == string.lower(value) then
	--			return err.E_URLBOLCK_MAC_OLD_CONFLICT
	--		end
	--	end
	--end

	return err.E_NONE
end

function check_block_url(value, web_para, diff_para, souce_data)
	local val
	for _, val in pairs(value) do
		if not validator.check_domain(val) then
			return err.E_URLBOLCK_URL_FORMAT
		end
	end

	return err.E_NONE
end