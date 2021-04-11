local err = require("luci.phicomm.error")

module("luci.controller.admin.auto_upgrade_plt", package.seeall)

function index()
end

function get_upgrade_conf_plt(uciname, secname, args)
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()
	local result = {}
	local start_hour = cursor:get("system","upgrade","start_hour")
	local start_minute = cursor:get("system","upgrade","start_minute")
	local start_second = cursor:get("system","upgrade","start_second")

	start_hour = tonumber(start_hour)
	start_minute = tonumber(start_minute)
	if nil == start_second then
		start_second = 0
	else
		start_second = tonumber(start_second)
	end

	result.mode = cursor:get("system","upgrade","mode")
	result.upgrade_time = start_hour * 3600 + start_minute * 60 + start_second;

	return err.E_NONE, result
end

function get_upgrade_info()
	local result = {}
	require ("ubus")
	local conn = ubus.connect()
	result.running_status = "1"
	local check_result = ""
	check_result = conn:call("http", "check_upgrade", {})
	result.running_status = "2"
	local uci = require ("luci.model.uci")
	local cursor = uci.cursor()

	result.sw_ver = cursor:get("system","system","fw_ver")
	local retState = cursor:get("onekeyupgrade","config","retState")
	if retState == "0" then
		result.status_code = "8802"
		return err.E_NONE, result
	end

	local ErrorCode = cursor:get("onekeyupgrade","config","ErrorCode") -- 有新版本的情况下，没有此项
	if ErrorCode ~= "0" then
		result.status_code = ErrorCode
		return err.E_NONE, result
	end

	local VerNum = cursor:get("onekeyupgrade","config","VerNum") -- 0没有新版本,1有新版本
	if VerNum == "0" then
		result.status_code = "0"
		return err.E_NONE, result
	elseif VerNum == "1" then
		result.status_code = "1"
	end

	result.new_ver = cursor:get("onekeyupgrade","config","newversion")
	result.release_time = cursor:get("onekeyupgrade","config","reledate")
	local file = io.open("/tmp/verdesc","r")
	local data = file:read("*a")
	file:close()
	result.release_log = data

	return err.E_NONE, result
end

function WIFEXITED(status)
	if status <= 0 then
		return status
	end

	local bit = require "nixio".bit

	return bit.rshift(status, 8)
end

function auto_system_upgrade()
	local cmd = "do_upgrade &"
	local ret = WIFEXITED(os.execute(cmd))

	return err.E_NONE
end

function get_upgrade_status()
	local status_file = "/tmp/up_code"
	local file = io.open(status_file, "r")
	local content

	if file then
		content = file:read()
		file:close()
	end

	local data = {}
	if content then
		local status
		for status in string.gmatch(content, "%d+") do
			table.insert(data, status)
		end
	end

	local result = {
		running_status = 0,
		status_code = 0,
		process_num = 0
	}

	result.running_status = data[1]
	result.status_code = data[2]
	result.process_num = data[3]

	return err.E_NONE, result
end

function get_online_upgrade_plt(para)
	local action = para.action

	if "start" == action or "get" == action then
		return get_upgrade_info()
	elseif "upgrade_status" == action then
		return get_upgrade_status()
	elseif "upgrade" == action then
		return auto_system_upgrade()
	else
		return err.E_INVARG
	end
end
