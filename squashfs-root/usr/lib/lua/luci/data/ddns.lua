local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.ddns", package.seeall)

function index()
	register_secname_cb("ddns", "config", "check_ddns", "apply_ddns_config")
end

function check_ddns(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			provider = {
				[KEY_VALIDATOR] = "luci.data.ddns.check_ddns_provider"
			},
			user = {
				[KEY_VALIDATOR] = "luci.data.ddns.check_ddns_user"
			},
			password = {
				[KEY_VALIDATOR] = "luci.data.ddns.check_ddns_pwd"
			},
			domain = {
				[KEY_VALIDATOR] = "luci.data.ddns.check_ddns_domain"
			}
		}
	)

	return err.E_NONE
end

function check_ddns_provider(value, web_para, diff_para, souce_data)
	local provider
	local ddns_provider = {"dynupdate.no-ip.com", "dyndns.org", "oray.com", "pubyun.com"}
	if "0" == web_para.enable then
		return err.E_NONE
	end

	for _, provider in ipairs(ddns_provider) do
		if provider == value then
			return err.E_NONE
		end
	end

	return err.E_DDNS_PROVIDER
end

function check_ddns_user(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	if type(value) ~= "string" or "" ==  value then
		return err.E_DDNS_USERNAME_BLANK
	end

	-- DDNS合法用户名：0-64位任意字符
	if #value < 0 or #value > 64 then
		return err.E_DDNS_USERNAME_LEN
	else
		return err.E_NONE
	end
end

function check_ddns_pwd(value, web_para, diff_para, souce_data)
	if "0" == web_para.enable then
		return err.E_NONE
	end

	if "" ==  value then
		return err.E_DDNS_PWD_BLANK
	end

	if type(value) ~= "string" then
		return err.E_DDNS_PWD_ILLEGAL
	end

	if #value < 0 or #value > 64 then
		return err.E_DDNS_PWD_ILLEGAL
	end

	-- DDNS密码：不允许输入中文
	for i = 1, #value do
		local chr_num = string.byte(value, i, i)
		if chr_num > 127 then
			return err.E_DDNS_PWD_ILLEGAL
		end
	end

	return err.E_NONE
end

function check_ddns_domain(value, web_para, diff_para, souce_data)
	local validator = require("luci.phicomm.validator")

	if "0" == web_para.enable then
		return err.E_NONE
	end

	if "" ==  value then
		return err.E_DDNS_HOST_BLANK
	end

	if not validator.check_domain(value) then
		return err.E_DDNS_HOST_ILLEGAL
	end

	return err.E_NONE
end

function apply_ddns_config(method, uciname, secname, web_para, diff_para, souce_data)
	local ddns_plt = require("luci.data.ddns_plt")
	local error, data
	error, data = ddns_plt.apply_ddns_config_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return error, data
end