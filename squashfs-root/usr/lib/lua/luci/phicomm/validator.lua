--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   validator.lua
* VERSION    :   1.0
* DESCRIPTION:   common validate methods
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   1/26/2014
*
* HISTORY    :
* 01   1/26/2014  LiGuanghua     Create.
**********************************************************************************
]]--
local string, type = string, type
local err = require("luci.phicomm.error")
local util = require("luci.phicomm.util")
local bit = require("luci.phicomm.lib.bit").bit

local print = print

module("luci.phicomm.validator", package.seeall)

function check_bool(value)
	if "0" ~= value and "1" ~= value and 1 ~= value and 0 ~= value then
		return err.E_INVBOOL
	end

	return err.E_NONE
end

function check_passwd(passwd)
    if nil == passwd then
        return err.E_PWDBLANK
    end

    -- 检查密码长度是否合法
    if #passwd < 5 or #passwd > 63 then
        return err.E_PWDLEN
    end

    -- 检查密码是否含有非法字符
    local ptrn = "^[%a%d%p ]+$"
    if not string.match(passwd, ptrn) then
        return err.E_PWDILLEGAL
    end

    return err.E_NONE
end

-- check wlan password
-- add by LiGuanghua
function check_wlan_pwd(pwd)
	if type(pwd) ~= "string" then
		return err.E_WIFI_PWD_ILLEGAL
	end

	if pwd == "" then
		return err.E_NONE
	end

	local pwdlen = #pwd
	if pwdlen <= 63 and pwdlen >= 8 then
		-- 检查是否有中文
		local ASCII_RANGE_END = 127

		for i = 1, pwdlen do
			local chr_num = string.byte(pwd, i, i)
			if chr_num > ASCII_RANGE_END then
				return err.E_WIFI_PWD_ILLEGAL
			end
		end

		return err.E_NONE
	else
		return err.E_WIFI_PWD_LEN
	end
end

-- check wifi name
-- add by LiGuanghua
function check_ssid(ssid)
	if type(ssid) ~= "string" then
		return err.E_SSID_ILLEGAL
	end

	if ssid == "" then
		return err.E_SSID_BLANK
	end

	if #ssid < 1 or #ssid > 32 then
		return err.E_SSID_LEN
	end

	return err.E_NONE
end

--check ip format
function valid_ip_format(value)
	if type(value) ~= "string" then
		return err.E_INVIP
	end

	local result = string.match(value, "^%d+%.%d+%.%d+%.%d+$")
	if not result then
		return err.E_INVIPFMT
	else
		return err.E_NONE
	end
end

local NOT_CHECK_MUTI_IP = 1
local NOT_CHECK_LOOP_IP = 2
local NOT_CHECK_MUTI_LOOP_IP = 3

--check ip address value is valid or not
-- E class ip is invalid
function valid_ip_addr(value, code)
	local num = 0

	for numstr in string.gmatch(value, "%d+") do
		-- check ip like 192.168.01.1, is invalid
		if string.match(numstr, "^0%d+") then
			return err.E_INVIP
		end

		num = tonumber(numstr)
		if 255 < num then
			return err.E_INVIP
		end
	end

	local high_8_bit = tonumber(string.match(value, "%d+"))
	if 224 < high_8_bit then
		return err.E_INVNET
	end

	-- multicast ip is invalid default
	if nil == code or NOT_CHECK_MUTI_IP ~= code or NOT_CHECK_MUTI_LOOP_IP ~= code then
		if 224 == high_8_bit then
			return err.E_INVMACGROUP
		end
	end

	-- loopback ip is invalid default
	if nil == code or NOT_CHECK_LOOP_IP ~= code or NOT_CHECK_MUTI_LOOP_IP ~= code then
		if 127 == high_8_bit then
			return err.E_INVLOOPIP
		end
	end

	return err.E_NONE
end

--check ip
function check_ip(value, notCheckMutiIp)
	if type(value) ~= "string" or "" == value then
		return err.E_INVIP
	end

	local result = err.E_NONE
	result = valid_ip_format(value)
	if (err.E_NONE ~= result) then
		return result
	end

	result = valid_ip_addr(value, notCheckMutiIp)
	if (err.E_NONE ~= result) then
		return result
	end

	return result
end

--check mac address, group mac is invalid
function check_mac(value)
	if type(value) ~= "string" then
		return err.E_INVMACFMT
	end

	--check mac format
	local pattern = "^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$"
	local result = string.match(value, pattern)

	if not result then
		return err.E_INVMACFMT
	end

	--zero, broadcast, group mac is invalid
	local mac_addr = string.lower(value)
	if "00:00:00:00:00:00" == mac_addr then
		return err.E_INVMACZERO
	end

	if "ff:ff:ff:ff:ff:ff" == mac_addr then
		return err.E_INVMACBROAD
	end

	if "01" == string.sub(value, 1, 2) then
		return err.E_INVMACGROUP
	end

	return err.E_NONE
end

--transform ip from dotted quad ip to UINT32
function trans_ip(ip_str)
	local uint_ip = 0
	for numstr in string.gmatch(ip_str, "%d+") do
		uint_ip = uint_ip * 256 + tonumber(numstr)
	end

	return uint_ip
end

--check mask value
function check_mask(value)
	if type(value) ~= "string" or "" == value then
		return err.E_INVMASK
	end

	if err.E_NONE ~= valid_ip_format(value) then
		return err.E_INVMASK
	end

	-- format like '255.255.255.00' is invalid
	if string.match(value, "00") then
		return err.E_INVMASK
	end

	--MAX_UINT_32 = 0xffffffff
	local MAX_UINT_32 = 4294967295
	local uint32_ip = MAX_UINT_32 - trans_ip(value) + 1
	local i = 0

	for i = 1, 31 do
		if uint32_ip == math.pow(2, i) then
			return err.E_NONE
		end
	end

	return err.E_INVMASK
end

--check number
function check_num(value)
	if type(value) ~= "string" and type(value) ~= "number" or "" == value then
		return false
	end

	if nil ~= string.match(value, "%D") then
		return false
	end

	return true
end

--check the value is between min and max
function check_num_range(value, min, max)
	if not check_num(value) or not check_num(max) or not check_num(min) then
		return false
	end

	local val = tonumber(value)
	local max_val, min_val = tonumber(max), tonumber(min)
	if nil == val or val < min_val or val > max_val then
		return false
	end

	return true
end

--check MTU value
function check_mtu(value, max, min)
	if not check_num(value) then
		return err.EINVMTU
	end

	if nil == max then max = 1500 end
	if nil == min then min = 576 end

	if not check_num_range(value, max, min) then
		return err.EINVMTU
	end

	return err.E_NONE
end

function check_ip_nethost(ipVal, maskVal)
	local bit = require("luci.phicomm.lib.bit").bit

	--check network id whether is all 0/1 or not
	local nethost_id = bit:bit_and(ipVal, maskVal)
	if 0 == nethost_id or maskVal == nethost_id then
		return err.EINVNETID
	end

	--check host id whether is all 0/1 or not
	local not_maskVal = bit:bit_not(maskVal)
	local host = bit:bit_and(ipVal, not_maskVal)
	if 0 == host or not_maskVal == host then
		return err.EINVHOSTID
	end

	return err.E_NONE
end

function get_ip_class(value)
	local ip_byte = tonumber(string.match(value, "%d+"))

	if ip_byte <= 127 then return "A" end
	if ip_byte <= 192 then return "B" end
	if ip_byte <= 223 then return "C" end
	if ip_byte <= 239 then return "D" end

	return "E"
end

function check_ip_class(ipVal, maskVal)
	local bit = require("luci.phicomm.lib.bit").bit
	local net_id = get_ip_class(ipVal)
	local ip_value = trans_ip(ipVal)
	local mask_value = trans_ip(maskVal)

	if "A" == net_id then
		--4278190080 = 0xFF000000
		ip_value = bit:bit_and(4278190080, ip_value)
	elseif "B" == net_id then
		--4294901760 = 0xFFFF0000
		ip_value = bit:bit_and(4294901760, ip_value)
	elseif "C" == net_id then
		--4294967040 = FFFFFF00
		ip_value = bit:bit_and(4294967040, ip_value)
	end

	if mask_value < ip_value then
		return err.E_INVIPMASKPAIR
	end

	return err.E_NONE
end

--check ip with netmask
function check_ip_mask(ipVal, maskVal)
	if type(ipVal) ~= "string" or type(maskVal) ~= "string" then
		return err.E_INVIPMASKPAIR
	end

	local result = err.E_NONE
	local ip_value = trans_ip(ipVal)
	local mask_value = trans_ip(maskVal)

	result = check_ip_nethost(ip_value, mask_value)
	if err.E_NONE ~= result then
		return result
	end

	result = check_ip_class(ipVal, maskVal)
	if err.E_NONE ~= result then
		return result
	end

	return err.E_NONE
end

-- check whether ip1 & ip2 at the same network
-- return true/false
function check_same_network(ip1, ip2, mask)
    -- transform args from "192.168.x.x" to uint32
    ip1 = "number" == type(ip1) and ip1 or trans_ip(ip1)
    ip2 = "number" == type(ip2) and ip2 or trans_ip(ip2)
    mask = "number" == type(mask) and mask or trans_ip(mask)

    return bit:bit_and(ip1, mask) == bit:bit_and(ip2, mask)
end

-- 检查域名是否含有非法字符
-- RETURN：true/false
function check_domain(domain)
	if type(domain) ~= "string" or #domain > 255 then
		return false
	end

	-- 检查域名是否含有非法字符
	local reg = "^[%w%.%-]+$"
	if not string.match(domain, reg) then
		return false
	end

	local tokens = util.split_string(domain, ".")
	for _, v in pairs(tokens) do
		if #v == 0 or #v >= 64 then
			return false
		end
	end

	return true
end
