--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   device_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的设备信息回调函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/12/2017  MengQingru     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")
local LuCI, MAIN, GUIDE, LANG, AGREEMENT = "luci", "main", "guide", "lang", "agreement"
local fs     = require "nixio.fs"

module("luci.controller.admin.device_plt", package.seeall)

function index()

end

function get_welcome_config_plt(args, uciname, secname)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	local result = {
		guide = cursor:get(LuCI, MAIN, GUIDE),
		language = cursor:get(LuCI, MAIN, LANG),
		agreement = cursor:get(LuCI, MAIN, AGREEMENT)
	}
	return err.E_NONE, result
end

function get_wisp_connect(ifname)
	local stat, iwinfo = pcall(require, "iwinfo")
	local wisp_status = 0
	levle = iwinfo.get_wisp_connect(ifname)

	for k, v in ipairs(levle or { }) do
		if k or v then
			wisp_status = v
		end
	end
	return wisp_status
end

function get_device_info_plt(args, uciname, secname)
	require ("luci.sys")
	local phicomm_lua = require("phic")

	require ("ubus")
	local conn = ubus.connect()

	local result = {}
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	result.uptime = luci.sys.uptime()
	result.hw_ver = cursor:get("system","system","hw_ver") or "unknown"
	result.sw_ver = cursor:get("system","system","fw_ver") or "unknown"
	result.model = cursor:get("system","system","hostname") or "unknown"
	result.mac = string.upper(cursor:get("network","wan","macaddr") or "00:00:00:00:00:00")
	result.hw_id = cursor:get("dev_info","dev_info","hw_id") or "unknown"
	result.product_id = cursor:get("dev_info","dev_info","product_id") or "unknown"
	result.domain = cursor:get("system","system","domain") or "p.to"
	result.isp = cursor:get("system","system","isp") or ""
	result.region = cursor:get("system","system","region") or ""
	result.cpu_freq = cursor:get("system","system","cpu_speed") or ""

	local wan_link = conn:call("rth.inet","get_wan_link",{})
	local phy_status = wan_link["wan_link"]

	local wisp_2gname = phicomm_lua.default_2g_wisp_ifname()[1]
	local wisp_5gname = phicomm_lua.default_5g_wisp_ifname()[1]
	--wisp status
	local wisp_2g_status = get_wisp_connect(wisp_2gname)
	local wisp_5g_status = get_wisp_connect(wisp_5gname)

	wan_ifname = cursor:get("network","wan","ifname")
	local status = conn:call("network.interface.wan", "status", {})
	--ip
	local addrs = status["ipv4-address"]
	local ip = (addrs and #addrs > 0 and addrs[1].address) or "0.0.0.0"

	if ip and ((wan_ifname == wisp_2gname or wan_ifname == wisp_5gname) or phy_status == "up") then
		if wan_ifname == wisp_2gname or wan_ifname == wisp_5gname then
			if wan_ifname == wisp_2gname and wisp_2g_status == 0 then
				result.wan_ip = "0.0.0.0"
			end
			if wan_ifname == wisp_5gname and wisp_5g_status == 0 then
				result.wan_ip = "0.0.0.0"
			end
		end
		result.wan_ip = ip
	else
		result.wan_ip = "0.0.0.0"
	end

	--mem_use
	local info = conn:call("system", "info", {})
	local memory = info["memory"]
	local total = tonumber(memory and memory.total) or ""
	local free = tonumber(memory and memory.free) or ""
	local buffer = tonumber(memory and memory.buffered) or ""
	local cache = tonumber(memory and memory.cache) or ""
	result.total_ram = cursor:get("system","system","all_ram") or ""
	result.used_ram = tonumber(result.total_ram - free) or ""

	--cpu-rate
	local cpu = info["cpu"]
	local cpu_rate = tonumber(cpu and cpu.idle) or ""
	result.cpu_used = (100 - cpu_rate) or ""

	--current time
	require ("luci.util")
	local nixio = require "nixio"
	local fs    = require "nixio.fs"

	if fs.access("/tmp/ntpdgettimeok") then
		result.current_time = luci.util.exec("date +'%Y/%m/%d %H:%M'")
	else
		result.current_time = ""
	end

	return err.E_NONE, result
end

function system_reboot_plt()
	os.execute("reboot")
	return err.E_NONE
end

function system_reset_plt()
	local sleep = fs.readfile("/tmp/sleep_status")

	if sleep == nil then
		os.execute("jffs2reset -y & reboot")
	else
		status = string.find(sleep, "1")
		if status == nil then
			os.execute("jffs2reset -y & reboot")
		end
	end
	return err.E_NONE
end

function set_lang_plt(para)
	local cursor = require("luci.model.uci").cursor()
	local LANG = "lang"
	cursor:set(LuCI, MAIN, LANG, para)
	cursor:commit(LuCI)

	return err.E_NONE
end

function set_agreement_plt(para)
	local cursor = require("luci.model.uci").cursor()
	local AGREEMENT = "agreement"
	cursor:set(LuCI, MAIN, AGREEMENT, para)
	cursor:commit(LuCI)

	return err.E_NONE
end

