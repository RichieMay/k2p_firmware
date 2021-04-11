--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   guide_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   登录相关
*
* AUTHOR     :   MengQingru <qingru.meng@phicomm.com>
* CREATE DATE:   07/12/2017
*
* HISTORY    :
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local LuCI, ADMIN, USER, PWD, MTIME = "luci", "admin", "username", "password", "mtime"
module("luci.data.guide_plt", package.seeall)

function index()

end

function get_account_plt()
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	local data = {
		user = cursor:get(LuCI, ADMIN, USER),
		pwd = cursor:get(LuCI, ADMIN, PWD),
		mtime = cursor:get(LuCI, ADMIN, MTIME)
	}
	local base64 = require "luci.base64"
	local decode_pwd = base64.decode(data.pwd)
	data.pwd = decode_pwd;

	return err.E_NONE, data
end

function modify_account_plt(user, pwd)
	local cursor = require("luci.model.uci").cursor()
	local mtime = os.time() * 1000
	local base64 = require "luci.base64"
	local encode_pwd = base64.encode(pwd)
	cursor:set(LuCI, ADMIN, PWD, encode_pwd)
	cursor:set(LuCI, ADMIN, USER, user)
	cursor:set(LuCI, ADMIN, MTIME, mtime)

	cursor:commit(LuCI)
	return err.E_NONE
end

function close_redirect_plt()
	local cursor = require("luci.model.uci").cursor()

	cursor:delete("dhcp", "welcome")
	cursor:save("dhcp")
	cursor:commit("dhcp")
	cursor:apply("dhcp")
	return err.E_NONE
end

function apply_welcome_conf_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local MAIN = "main"
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local k, v
	for k, v in pairs(diff_para) do
		cursor:set(LuCI, MAIN, k, v)
	end

	cursor:commit(LuCI)

	return err.E_NONE
end
