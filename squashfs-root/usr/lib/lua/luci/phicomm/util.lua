local _G, os = _G, os
local require, type, math = require, type, math
local string, ipairs, pairs, io = string, ipairs, pairs, io
local table, tonumber, tostring = table, tonumber, tostring
local nixio = require("nixio")
local util = require("luci.util")
local bit = require("luci.phicomm.lib.bit").bit

module "luci.phicomm.util"

-- 将十进制转换成16进制
function oct2hex(i)
	if type(i) ~= "number" then
		return nil
	end

	if i == 0 then
		return 0
	end

	local s = ""
	local tmp = i
	local cset = {
		"0", "1", "2", "3", "4", "5",
		"6", "7", "8", "9", "a", "b",
		"c", "d", "e", "f"
	}

	while tmp > 0 do
		s = cset[tmp % 16 + 1] .. s
		tmp = math.floor(tmp / 16)
	end

	return s
end

-- 比较两个参数内容是否相等，如果相等，返回true，不等返回false
function equal(arg1, arg2)
    if arg1 == nil and arg2 == nil then
        return true
    end

    if type(arg1) ~= type(arg2) then
        return false
    end

    if type(arg1) ~= "table" then
       return arg1 == arg2
    end

    local keys1 = util.keys(arg1)
    local keys2 = util.keys(arg2)

    if #keys1 ~= #keys2 then
        return false
    end

    for i, k in ipairs(keys1) do
        if not equal(arg1[k], arg2[k]) then
            return false
        end
    end

    return true
end

function handle_special_char(s)
	local c = ""
	local sepcial_char_map = { [" "] = "%s" }
	local sepcial_chars = "^$()%.[]*+-?"
	for i = 1, #sepcial_chars do
		c = string.sub(sepcial_chars, i, i)
		sepcial_char_map[c] = "%" .. c
	end

	local tmp = ""
	for i = 1, #s do
		c = string.sub(s, i, i)
		tmp = tmp .. (sepcial_char_map[c] or c)
	end

	return tmp
end

-- 分割字符串
-- @param s: 字符串
-- @param sep: 单字符
-- @return: 字符串数组列表
function split_string(s, sep)
	if type(s) ~= "string" or type(sep) ~= "string" then
		return nil
	end

	if #sep ~= 1 then
		return nil
	end

    local t = {}
	local real_char = handle_special_char(sep)
	local ptrn = string.format("%s", real_char)
	local tmp = s

	local start, zend = string.find(tmp, ptrn)
	local token = ""
	while start do
		if start == 1 then
			token = ""
		else
			token = string.sub(tmp, 1, start - 1)
		end

		t[#t + 1] = string.gsub(token, "%s*(.+)%s*", "%1")
		if zend == #tmp then
			tmp = ""
			break
		end

		tmp = string.sub(tmp, zend + 1, #tmp)
		start, zend = string.find(tmp, ptrn)
	end

	t[#t + 1] = string.gsub(tmp, "%s*(.+)%s*", "%1")

	return t
end

-- 获取字符串中的模块与函数
-- 例如："luci.phicomm.validator.checkip" 返回 "luci.phicomm.validator", "checkip"
function split_module_func(s)
    if type(s) ~= "string"  then
        return nil, nil
    end

    local t = {}

    for k in string.gmatch(s, "([%w-_]+)") do
        t[#t + 1] = k
    end

    local funcname   = table.remove(t, #t)
    local modulename = #t > 0 and table.concat(t, ".") or nil
    return modulename, funcname
end

-- 根据IP和掩码获取网络地址
-- AUTHOR: LiGuanghua <guanghua.li@phicomm.com>
-- RETURN：网络地址或nil
function get_network(ip, mask)
    if type(ip) ~= "string" or type(mask) ~= "string" then
        return nil
    end

    local ip_bytes = split_string(ip, ".")
    local mask_bytes = split_string(mask, ".")

    if #ip_bytes ~= 4 and #mask_bytes ~= 4 then
        return nil
    end

    local net_bytes = {}
    for i, v in ipairs(ip_bytes) do
        local tmp = bit:bit_and(tonumber(ip_bytes[i]), tonumber(mask_bytes[i]))
        net_bytes[#net_bytes + 1] = tmp
    end

    return table.concat(net_bytes, ".")
end

-- 截断UTF-8编码的字符串
-- @param str: 需要进行截断的字符串
-- @param max: 截断后允许的最大字节数
-- @author: LiGuanghua<guanghua.li@phicomm.com>
-- @return: 截取后的字符串和字节数
function utf8_truncate(str, max)
    if type(str) ~= "string" or type(max) ~= "number" then
        return nil, nil
    end

    -- 最大截取数小于0时，无需截断
    if max <= 0 then
        return str, #str
    end

    -- 字符串没超过目标buffer最大存储的字节数的，无需截断
    if #str <= max then
        return str, #str
    end

    local not_first_char = tonumber("0x80", 16)  -- 多字节符的非首字节，应为10xxxxxx
    local first_comp_char = tonumber("0xC0", 16) -- 非首字节比较掩码
    local illegal_char = tonumber("0xFD", 16)    -- 非法的字节特征，大于0xFD

    -- UTF-8使用1-6个字节编码，从末尾开始，最多往前搜寻6个字节
    for i = 0, 5 do
        local chr_index = max - i + 1
        if chr_index <= 0 then
            break
        end

        local chr_num = string.byte(str, chr_index, chr_index)

        -- 多字节符的首字节，不为10xxxxxx
        if not_first_char ~= bit:bit_and(chr_num, first_comp_char) then
            -- 必须符合首字节特征
            if chr_num > illegal_char then
                break
            end

            -- 不够存放当前编码的，在该字符首字节处截断
            local ret = string.sub(str, 1, chr_index - 1)
            return ret, #ret
        end
    end

    -- 找不到UTF-8的特征，就直接在末尾截断
    local ret = string.sub(str, 1, max)
    return ret, #ret
end

-- 元素在table中的索引
-- AUTHOR: LiGuanghua <guanghua.li@phicomm.com>
-- RETURN：索引值，未找到返回nil
function index(t, v)
    if type(t) ~= "table" or v == nil then
        return nil
    end

    for k, entry in pairs(t) do
        if entry == v then
            return k
        end
    end

    return nil
end

function fork_exec(command)
    local pid = nixio.fork()
    if pid > 0 then
        return
    elseif pid == 0 then
        -- change to root dir
        nixio.chdir("/")

        -- patch stdin, out, err to /dev/null
        local null = nixio.open("/dev/null", "w+")
        if null then
            nixio.dup(null, nixio.stderr)
            nixio.dup(null, nixio.stdout)
            nixio.dup(null, nixio.stdin)
            if null:fileno() > 2 then
                null:close()
            end
        end

        -- replace with target command
        nixio.exec("/bin/sh", "-c", command)
    end
end

-- 合并两个table
-- RETURN：合并后的table
function merge_table(dst, src)
    if "table" ~= type(dst) or
    "table" ~= type(src) then
        do return dst end
    end

    for k, v in pairs(src) do
        dst[k] = v
    end

    return dst
end
