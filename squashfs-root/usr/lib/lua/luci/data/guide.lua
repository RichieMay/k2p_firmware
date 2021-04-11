--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   guide.lua
* VERSION    :   1.0
* DESCRIPTION:   APIs about guide, Here you must realize following function:
*                get_account & set_account & modify_account & close_dns_redirect
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   17/01/2017
*
* HISTORY    :
* 01   18/01/2017  LiGuanghua     Create.
**********************************************************************************
]]--

local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator

module("luci.data.guide", package.seeall)

local LuCI, ADMIN, USER, PWD, MTIME = "luci", "admin", "username", "password", "mtime"

function index()
	register_secname_cb("welcome", "config", "check_welcome_conf", "apply_welcome_conf")
end

function check_welcome_conf(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			agreement = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			language = {
				[KEY_VALIDATOR] = "luci.data.guide.check_lang"
			},
			guide = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)

	return err.E_NONE
end

function check_lang(value, web_para, diff_para, souce_data)
	-- 支持的语言列表
	local DEVFETURE, LANGLIST = "dev_feature", "system_info"
	local cursor = require("luci.model.uci").cursor()
	local lang = cursor:get_all(DEVFETURE, LANGLIST).language

	if "string" ~= type(value) then
		return err.E_INVARG
	end

	local v
	for _, v in ipairs(lang) do
		if v == value then
			return err.E_NONE
		end
	end

	return err.E_INVARG
end

function apply_welcome_conf(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.guide_plt")

	errcode, result = plt.apply_welcome_conf_plt(method, uciname, secname, web_para, diff_para, souce_data)

	return errcode
end

function get_account()
	local plt = require("luci.data.guide_plt")
	local errcode, data
	errcode, data = plt.get_account_plt()

	return data
end

function set_account(user, pwd)
	local errcode, data
	local plt = require("luci.data.guide_plt")

	-- save account
	modify_account(user, pwd)

	-- 统计首次配置
	local cursor = require ("luci.model.uci").cursor()
	local first_config_cap = cursor:get("dev_feature", "statistic", "first_config")
	if "1" == first_config_cap then
		local stt = require("luci.phicomm.statistic")
		stt.first_config()
	end

	-- close dns redirect
	errcode, data = plt.close_redirect_plt()
	return errcode
end

function modify_account(user, pwd)
	local plt = require("luci.data.guide_plt")
	local errcode, result

	errcode, result = plt.modify_account_plt(user, pwd)
	return errcode
end
