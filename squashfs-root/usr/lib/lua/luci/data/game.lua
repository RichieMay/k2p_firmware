--[[
**********************************************************************************
* Copyright (c) 2017 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   game.lua
* VERSION    :   1.0
* DESCRIPTION:   游戏加速设置的回调函数
*
* AUTHOR     :   GengChao <chao.geng@phicomm.com>
* CREATE DATE:   07/31/2017
*
* HISTORY    :
*
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")

local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.game", package.seeall)

function index()
	register_secname_cb("game_accelerate", "config", "check_game_config", "apply_game_config")
end

function check_game_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			},
			gameid = {
				[KEY_VALIDATOR] = "luci.data.game.check_game_id"
			}
		}
	)
	return err.E_NONE
end

function apply_game_config(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	
	if web_para.valid ~= "1" then
		return err.E_GAME_STATUS_ILLEGAL
	end
	
	if web_para.enable == "0" then
		cursor:set("ccgame", "ccgame", "enable", web_para.enable)
	else
		if not web_para.enable then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if not web_para.uid then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if not web_para.password then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if not web_para.gameid then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if not web_para.regionid then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if not web_para.freetime and not web_para.deadtime then
			return err.E_GAME_STATUS_ILLEGAL
		end
		if web_para.freetime then
			-- range from 0 to (24 * 3600)(1 sday)
			if tonumber(web_para.freetime) <= 0 or 
				tonumber(web_para.freetime) > (24 * 3600) then
				return err.E_GAME_STATUS_ILLEGAL
			end
		end
		
		cursor:set("ccgame", "ccgame", "enable", web_para.enable)
		cursor:set("ccgame", "ccgame", "uid", web_para.uid)
		cursor:set("ccgame", "ccgame", "password", web_para.password)
		cursor:set("ccgame", "ccgame", "gameid", web_para.gameid)
		cursor:set("ccgame", "ccgame", "regionid", web_para.regionid)
		if web_para.deadtime then
			cursor:set("ccgame", "ccgame", "deadtime", web_para.deadtime)
			cursor:delete("ccgame", "ccgame", "freetime")
		else
			cursor:set("ccgame", "ccgame", "freetime", web_para.freetime)
			cursor:delete("ccgame", "ccgame", "deadtime")
		end
	end
	cursor:commit("ccgame")
	os.execute("/etc/init.d/ccgame restart")
	return err.E_NONE, {wait_time = 20}
end


function check_game_id(value, web_para, diff_para, souce_data)--TODO

	return err.E_NONE
end


