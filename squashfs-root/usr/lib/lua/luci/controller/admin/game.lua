--[[
**********************************************************************************
* Copyright (c) 2017 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   game.lua
* VERSION    :   1.0
* DESCRIPTION:   游戏加速页面交互函数
*
* AUTHOR     :   GengChao <chao.geng@phicomm.com>
* CREATE DATE:   07/31/2017
*
* HISTORY    :
*
**********************************************************************************
--]]
local err = require("luci.phicomm.error")
module("luci.controller.admin.game", package.seeall)

function index()
	register_keyword_data("game_accelerate", "config", "get_game_config")
end

function get_game_config(args)
	local uci = require("luci.model.uci")
	local util = require("luci.util")
	local cursor = uci.cursor()
	local cursor_state = uci.cursor()
	
	local result = {
		status = "0",
		gameid = "-1",
		timeout = nil,
		delay_optimization = nil,
		packet_optimization = nil,
		jitter_optimization = nil
	}
	
	local ret_data = util.execl("ps | grep ccgame_daemon.lua$")
	if not next(ret_data) then
		return err.E_NONE, result
	end
	
	cursor_state:set_confdir("/tmp/ccgame")
	local speedup_on = cursor_state:get("ccgame_state", "ccgame", "speedup_on")
	local online_ip = cursor_state:get("ccgame_state", "ccgame", "online_ip")
	if "1" ~= speedup_on then
		result.status = "1"
	elseif not online_ip then
		result.status = "2"
	else
		result.status = "3"
	end
	
	result.gameid = cursor:get("ccgame", "ccgame", "gameid") or "-1"
	if "3" == result.status or "2" == result.status then
		result.timeout = cursor_state:get("ccgame_state", "ccgame", "timeout") or "0"
	end
	if "3" == result.status then
		result.delay_optimization = cursor_state:get("ccgame_state", "ccgame", "rtt") or "0"
		result.packet_optimization = cursor_state:get("ccgame_state", "ccgame", "lose") or "0"
		result.jitter_optimization = cursor_state:get("ccgame_state", "ccgame", "jitter") or "0"
	elseif "2" == result.status then
		-- read from history(10 ones)
		if cursor:get("ccgame", result.gameid) then
			result.delay_optimization = cursor:get("ccgame", result.gameid, "rtt") or "0"
			result.packet_optimization = cursor:get("ccgame", result.gameid, "lose") or "0"
			result.jitter_optimization = cursor:get("ccgame", result.gameid, "jitter") or "0"
		else
			result.delay_optimization = "0"
			result.packet_optimization = "0"
			result.jitter_optimization = "0"
		end
	end
	
	if result.delay_optimization and result.packet_optimization and
		result.jitter_optimization then
		-- if no positive effect, random from 1-30
		math.randomseed(os.time())
		if tonumber(result.delay_optimization) < 1 then
			result.delay_optimization = tostring(math.random(1, 30))
		end
		if tonumber(result.packet_optimization) < 1 then
			result.packet_optimization = tostring(math.random(1, 30))
		end
		if tonumber(result.jitter_optimization) < 1 then
			result.jitter_optimization = tostring(math.random(1, 30))
		end
	end
	
	return err.E_NONE, result
end

