local _G, os = _G, os
local require, type, math = require, type, math
local string, ipairs, pairs, io = string, ipairs, pairs, io
local table, tonumber, tostring = table, tonumber, tostring
local nixio = require("nixio")
local util = require("luci.util")
local bit = require("luci.phicomm.lib.bit").bit

module "luci.phicomm.util"

-- ��ʮ����ת����16����
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

-- �Ƚ��������������Ƿ���ȣ������ȣ�����true�����ȷ���false
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

-- �ָ��ַ���
-- @param s: �ַ���
-- @param sep: ���ַ�
-- @return: �ַ��������б�
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

-- ��ȡ�ַ����е�ģ���뺯��
-- ���磺"luci.phicomm.validator.checkip" ���� "luci.phicomm.validator", "checkip"
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

-- ����IP�������ȡ�����ַ
-- AUTHOR: LiGuanghua <guanghua.li@phicomm.com>
-- RETURN�������ַ��nil
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

-- �ض�UTF-8������ַ���
-- @param str: ��Ҫ���нضϵ��ַ���
-- @param max: �ضϺ����������ֽ���
-- @author: LiGuanghua<guanghua.li@phicomm.com>
-- @return: ��ȡ����ַ������ֽ���
function utf8_truncate(str, max)
    if type(str) ~= "string" or type(max) ~= "number" then
        return nil, nil
    end

    -- ����ȡ��С��0ʱ������ض�
    if max <= 0 then
        return str, #str
    end

    -- �ַ���û����Ŀ��buffer���洢���ֽ����ģ�����ض�
    if #str <= max then
        return str, #str
    end

    local not_first_char = tonumber("0x80", 16)  -- ���ֽڷ��ķ����ֽڣ�ӦΪ10xxxxxx
    local first_comp_char = tonumber("0xC0", 16) -- �����ֽڱȽ�����
    local illegal_char = tonumber("0xFD", 16)    -- �Ƿ����ֽ�����������0xFD

    -- UTF-8ʹ��1-6���ֽڱ��룬��ĩβ��ʼ�������ǰ��Ѱ6���ֽ�
    for i = 0, 5 do
        local chr_index = max - i + 1
        if chr_index <= 0 then
            break
        end

        local chr_num = string.byte(str, chr_index, chr_index)

        -- ���ֽڷ������ֽڣ���Ϊ10xxxxxx
        if not_first_char ~= bit:bit_and(chr_num, first_comp_char) then
            -- ����������ֽ�����
            if chr_num > illegal_char then
                break
            end

            -- ������ŵ�ǰ����ģ��ڸ��ַ����ֽڴ��ض�
            local ret = string.sub(str, 1, chr_index - 1)
            return ret, #ret
        end
    end

    -- �Ҳ���UTF-8����������ֱ����ĩβ�ض�
    local ret = string.sub(str, 1, max)
    return ret, #ret
end

-- Ԫ����table�е�����
-- AUTHOR: LiGuanghua <guanghua.li@phicomm.com>
-- RETURN������ֵ��δ�ҵ�����nil
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

-- �ϲ�����table
-- RETURN���ϲ����table
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
