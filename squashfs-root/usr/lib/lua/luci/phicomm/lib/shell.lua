--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   shell.lua
* VERSION    :   1.0
* DESCRIPTION:   execute shell command
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   1/06/2014
*
* HISTORY    :
* 01   1/06/2014  LiGuanghua     Create.
**********************************************************************************
]]--
local print = print

local os, io = require "os", io
local string = require "string"
local table = require "table"

local setmetatable, rawget, rawset = setmetatable, rawget, rawset
local require, getmetatable = require, getmetatable
local error, pairs, ipairs = error, pairs, ipairs
local type, tostring, tonumber, unpack = type, tostring, tonumber, unpack

module "luci.phicomm.lib.shell"

-- difine execute code
CALL_SUCCESS_CODE = 0

-- define symbol
DEFAULT_KEY_VALUE_CONN_SYMBOL   = " "       -- default key value connnecting symbol
DEFAULT_KWARG_ENTRY_CONN_SYMBOL = " "       -- default kwarg entry connnecting symbol



--[[
******************************************************************************
* FUNCTION		: keys()
* AUTHOR		: LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	: return table keys
* INPUT			:
        @param kwargs
* OUTPUT		:
* RETURN		: table keys
******************************************************************************
--]]
function keys(kwargs)
    local keys = {}

    if nil == kwargs then
        return {}
    end

    for k, v in pairs(kwargs) do
        keys[#keys + 1] = k
    end

    return keys
end

--[[
******************************************************************************
* FUNCTION		: execute_cmd()
* AUTHOR		: LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	        : execute command
* INPUT			:
        @cmd: command string
* OUTPUT		:
* RETURN		: returns a boolean whether to execute succefully.
******************************************************************************
--]]
function execute_cmd(cmd)
    --cmd = cmd .. " > /dev/null 2>&1"
    local code = os.execute(cmd)
    return code == CALL_SUCCESS_CODE
end

-- “Ï≤Ω÷¥––√¸¡Ó
-- @author: LiGuanghua <guanghua.li@phicomm.com>
-- @return: true/false
function async_execute(cmd)
    --cmd = cmd .. " > /dev/null 2>&1"
    io.popen(cmd)
    return true
end

--[[
******************************************************************************
* FUNCTION		: construct_cmd()
* AUTHOR		: LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	        : construck shell commad
* INPUT			:
        @args: prefix arg list
        @kwargs: key-value args 
        @extends: postfix arg list
        @key_value_conn_symbol: key value connnecting symbol, default " "
        @kwarg_entry_conn_symbol: kwarg entry connnecting symbol, default " "
* OUTPUT		:
* RETURN		: returns a string.
* USAGE:
    for example, construct command:
        ping -c 5 -s 1024 -w 5 192.168.1.1
        
    method args like follows: 
        args = {"ping"}
        kwargs = {["-c"]=5, ["-s"]=1024, ["-w"]=5}
        extends = {"192.168.1.1"}
******************************************************************************
--]]
function construct_cmd(args, kwargs, extends, key_value_conn_symbol, kwarg_entry_conn_symbol)
    local cmd = ""

    if nil == args then
        return false
    end

    key_value_conn_symbol = key_value_conn_symbol or DEFAULT_KEY_VALUE_CONN_SYMBOL
    kwarg_entry_conn_symbol = kwarg_entry_conn_symbol or DEFAULT_KWARG_ENTRY_CONN_SYMBOL

    cmd = table.concat(args, " ")

    if nil ~= kwargs and #keys(kwargs) > 0 then
        local kwargs_cmd = " "
            for k, v in pairs(kwargs) do
                if v ~= nil then
                     kwargs_cmd = kwargs_cmd .. string.format("%s%s%s%s", k, key_value_conn_symbol, v, kwarg_entry_conn_symbol)
                end
            end
            kwargs_cmd = string.sub(kwargs_cmd, 1, #kwargs_cmd - #kwarg_entry_conn_symbol)

        cmd = cmd .. kwargs_cmd
    end

    if extends ~= nil then
        cmd = cmd .. " "
        cmd = cmd .. table.concat(extends, " ")
    end

    return cmd
end

--[[
******************************************************************************
* FUNCTION		: ping()
* AUTHOR		: LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	        : ping command
* INPUT			:
        @ip:
        @count:
        @size:
* OUTPUT		:
* RETURN		: returns a boolean whether to ping ip succefully.
******************************************************************************
--]]
function ping(ip, count, size)
    local args = {"ping"}

    if ip == nil then
        return false
    end

    local extends = {ip}

    local kwargs = {}
    kwargs["-c"] = count
    kwargs["-s"] = size

    local cmd = construct_cmd(args, kwargs, extends)
    
    return execute_cmd(cmd)
end
