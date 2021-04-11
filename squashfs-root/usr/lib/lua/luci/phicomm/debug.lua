--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   debug.lua
* VERSION    :   1.0
* DESCRIPTION:   debug tools.
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   17/01/2017
*
* HISTORY    :
* 01   17/01/2017  LiGuanghua     Create.
**********************************************************************************
]]--

module("luci.phicomm.debug", package.seeall)

-- print debug message
-- obj: Lua obj
-- level: debug level(current disabled)
function print(obj, level)
    local json = require("luci.json")
    local device = "/dev/console"
    local module = getfenv(2)._NAME
    local cmd = string.format('echo \"%s: %s \" > %s', module, json.encode(obj), device)

    os.execute(cmd)
end