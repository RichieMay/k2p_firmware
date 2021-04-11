--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   ds.lua
* VERSION    :   1.0
* DESCRIPTION:   数据服务类统一接口
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
**********************************************************************************
--]]
local http = require("luci.http")
local err = require("luci.phicomm.error")
local util = require("luci.phicomm.util")

module("luci.controller.ds", package.seeall)

--[[
********************************************************************
	数据服务接口方法关键字定义
********************************************************************
--]]--
KEY_METHOD      = "method"    -- 请求方法类型
KEY_MODULE      = "module"    -- 请求参数
METHOD_ADD      = "add"       -- 请求增加section
METHOD_DELETE 	= "del"       -- 请求删除section
METHOD_MODIFY 	= "set"       -- 请求修改section
METHOD_GET      = "get"       -- 请求获取数据

--[[
********************************************************************
    关键字参数名称
********************************************************************
--]]--
KEYWORD_FUNCPATH = "funcpath"

--[[
********************************************************************
    关键字获取数据表，表示哪些关键字获取哪些数据
********************************************************************
--]]--
keyword_data_table = {}

--[[
********************************************************************
    关键字修改数据表，表示哪些关键字设置那些数据
********************************************************************
--]]--
keyword_set_data_table = {}

--[[
********************************************************************
    注册功能模块列表
********************************************************************
]]--

module_speclist = {}

-- 注册模块信息
function register_module(modulelist)
	if type(modulelist) ~= "table" then
		return false
	end

	for modname, depends in pairs(modulelist) do
		if type(modname) ~= "string" or type(depends) ~= "table" then
			return false
		else
			module_speclist[modname] = {}
			module_speclist[modname]["depends"] = depends
		end
	end

	return true
end

--[[
********************************************************************
    过滤器相关信息
********************************************************************
]]--
--[[
uci_secname_filters为字典形式，key与uci与section name或者
uci与section type的组合，过滤参数时只选择在value中的字典中的存在的
如下：
{
    -- uci与section type的组合或者uci与section name的组合
    ["network:interface"] = {
        -- 对应每一个option或者list
        proto = {
            need = true
        },
        ip = {
            need = false
            validator = "luci.phicomm.validator.check_network",
            args = {"192.168.1.2", "255.255.255.0"}
        }
    }
}
]]--
FILTER_UCI_SEC_SEP = ":"
uci_secname_filters = {}
-- UCI名称与section name或者section type分隔符
filter_key = {
    -- 是否必要，默认为false，如果必要，则不能删除，如果非必要，则可以删除
    need = "need",
    -- 验证回调函数
    validator = "validator",
    -- 验证回调函数参数, 为table list类型
    args = "args"
}

-- 注册section name过滤器
function register_secname_filter(config, secname, filter_info)
    if type(filter_info) ~= "table" or type(config) ~= "string" or type(secname) ~= "string" then
        return false
    end

    uci_secname_filters[config .. FILTER_UCI_SEC_SEP .. secname] = filter_info
    return true
end

-- 注册关键字数据表
function register_keyword_data(uciname, keyword, funcname)
	return register_keyword_datastruct(uciname, keyword_data_table, keyword, funcname)
end

-- 注册设置关键字数据表
function register_keyword_set_data(uciname, keyword, funcname)
	return register_keyword_datastruct(uciname, keyword_set_data_table, keyword, funcname)
end

-- 注册关键字数据结构
function register_keyword_datastruct(uciname, keyword_table, keyword, funcname)
	if type(uciname) ~= "string" or type(keyword) ~= "string" or type(funcname) ~= "string" then
		return false
	end

	keyword_table = keyword_table or {}
	local module = getfenv(3)._NAME

	local uci_kw_table = keyword_table[uciname] or {}
	keyword_table[uciname] = uci_kw_table
	local keyword_para = keyword_table[uciname][keyword] or {}
	keyword_table[uciname][keyword] = keyword_para

	table.insert(keyword_para, {[KEYWORD_FUNCPATH] = module .. "." .. funcname})

	return true
end

-- 注册节点树
function index()
	-- 注册ds节点
	local page   = node("data")
	page.target  = firstchild()
	page.sysauth = "admin"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	entry({"data", "ds"}, call("ds"), "DataService", 20).index = true
end

-- 数据服务类接口
-- @author LiGuanghua <guanghua.li@phicomm.com>
function ds(callback)
	local result = {}
	local jsondata = http.jsondata()

	if not jsondata then
		-- 返回格式错误错误码
		result[err.ERR_CODE] = err.E_INVFMT
		write_json(result)
		return
	end

	local method = jsondata[KEY_METHOD]
	local method_map = {
		[METHOD_ADD] = set_data,
		[METHOD_DELETE] = set_data,
		[METHOD_MODIFY] = set_data,
		[METHOD_GET] = get_data
	}

	-- 去除method数据，传入处理函数时只包含数据
	local para = jsondata[KEY_MODULE]
	local func = method_map[method]
	if func then
		result = func(para, method)
	else
		-- 返回指令不存在错误码
		result[err.ERR_CODE] = err.E_INVFMT
		write_json(result)
		return
	end

	if callback then
		--执行模块相关的函数，用于生效等
		result = callback(para, method, result)
	end

	write_json(result)

end

-- 设置数据接口
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param method 设置数据类型，set/add/del
-- @param webdata Web请求数据
function set_data(webdata, method)
	local errcode = err.E_NONE
	local retdata = {}

	if type(webdata) ~= "table" and type(method) ~= "string" then
		retdata[err.ERR_CODE] = err.E_INVFMT
		return retdata
	end

	-- 获取差异数据
	local errcode, alldata, diffdata, changed = get_diff_data(webdata, method)
	if errcode ~= err.E_NONE then
		retdata[err.ERR_CODE] = errcode
		return retdata
	end

	-- 检查参数合法性
	errcode = do_chkcb(webdata, diffdata, alldata, method)
	if errcode ~= err.E_NONE then
		retdata[err.ERR_CODE] = errcode
		return retdata
	end

	-- 检查并过滤参数
	errcode = filter_args(webdata, diffdata, alldata)
	if errcode ~= err.E_NONE then
		retdata[err.ERR_CODE] = errcode
		return retdata
	end

	-- 执行服务
	errcode, extra = do_srvcb(webdata, diffdata, alldata, method)
	if errcode ~= err.E_NONE then
		retdata[err.ERR_CODE] = errcode
		return retdata
	end

	retdata[KEY_MODULE] = extra
	retdata[err.ERR_CODE] = err.E_NONE
	return retdata
end

-- 获取数据接口
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param webdata Web请求数据
function get_data(webdata)
	local result = {}
	local retdata = {}
	local datainfo = nil
	local ret = false

	if type(webdata) ~= "table" then
		result[err.ERR_CODE] = err.E_INVFMT
		return result
	end

	for uciname, names in pairs(webdata) do
		local ucidata = {}
		local has_getdata = false

		if "string" == type(names) then
			names = {names}
		elseif "table" ~= type(names) then
			result = {}
			result[err.ERR_CODE] = err.E_INVFMT
			return result
		end

		-- 判断请求参数是否正确
		if "table" ~= type(names) then
			result = {}
			result[err.ERR_CODE] = err.E_INVFMT
			return result
		end

		for name, args in pairs(names) do
			ret, datainfo = get_name_data(uciname, name, args)
			if err.E_NONE == ret then
				ucidata[name] = datainfo
				has_getdata = true
			else
				-- 返回参数错误错误码
				result = {}
				result[err.ERR_CODE] = ret
				return result
			end
		end

		-- 判断每个模块是否成功获取数据
		if not has_getdata then
			result = {}
			result[err.ERR_CODE] = err.E_INVFMT
			return result
		end

		-- 设置数据
		retdata[uciname] = ucidata
	end

	result[KEY_MODULE] = retdata
	result[err.ERR_CODE] = err.E_NONE
	return result
end

-- 返回json数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
function write_json(json)
	http.prepare_content("application/json")

	if http.getenv("PHIAPP_REQUEST") then
		--APP接口需要的结果必须是经过转义的，否则对特殊字符有问题（孟庆如）
		http.write_json(json, http.json_escape)
	else
		http.write_json(json, http.urlencode)
	end
end

-- 执行动态函数
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param keyword 函数关键字
-- @return 是否包含存在关键字的函数
-- @return 错误码
-- @return 动态数据
function do_keyword_func(uciname, keyword, keyword_table, paras)
	if type(keyword) ~= "string" or type(keyword_table) ~= "table" then
		return false
	end

	paras = paras or {}

	local uci_kw_table = keyword_table[uciname] or {}
	local cbs = uci_kw_table[keyword]
	local extra = {}

	if not cbs or "table" ~= type(cbs) then
		return false
	end

	for _, entry in pairs(cbs) do
		local funcpath = entry[KEYWORD_FUNCPATH]
		if not funcpath then
			return false
		end

		local modulename, funcname = util.split_module_func(funcpath)
		local module = nil

		if modulename ~= nil then
			module = require(modulename)
		end

		local func = module and funcname and module[funcname] or nil
		assert(func ~= nil,
				   'Cannot resolve function "' .. funcpath .. '". Is it misspelled or local?')

		local errcode, data = func(paras, uciname, keyword)
		if err.E_NONE ~= errcode then
			return true, errcode
		elseif nil ~= data then
			if type(data) == "table" then
				extra = util.merge_table(extra, data)
			elseif type(data) == "string" then
				table.insert(extra, data)
			end
		end
	end

	return true, err.E_NONE, extra
end

-- 返回指定功能模块的数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param module_name
-- @param function_name
-- @return error_code, module_function_data
function get_name_data(uciname, secname, args)
	if type(uciname) ~= "string" or type(secname) ~= "string" then
		return err.E_INVARG
	end

	local data = nil
	local exists = false
	local errcode = err.E_NONE

	-- 获取动态数据
	local exists, errcode, data = do_keyword_func(uciname, secname, keyword_data_table, args)
	if exists then
		if type(errcode) ~= "number" then
			return err.E_INVFMT
		end

		return errcode, data
	else
		return err.E_INVARG
	end
end

-- 获取flash中块数据与差异数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param webdata Web请求数据
-- @param method 设置数据类型，set/add/del
function get_diff_data(webdata, method)
	local code, all, diff, changed = err.E_INVFMT, nil, nil, false

	if type(webdata) ~= "table" or type(method) ~= "string" then
		return code, all, diff, changed
	end

	if method == METHOD_ADD then
		code, all, diff, changed = diff_add_data(webdata)
	elseif method == METHOD_DELETE then
		code, all, diff, changed = diff_del_data(webdata)
	elseif method == METHOD_MODIFY then
		code, all, diff, changed = diff_modify_data(webdata)
	else
		return err.E_INVFMT, nil, nil, false
	end

	return code, all, diff, changed
end

-- 获取add接口所对应的flash中块数据与差异数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param webdata Web请求数据
function diff_add_data(webdata)
	local code, alldata, diffdata, changed = err.E_INVFMT, {}, {}, false
	local uciname, sections, secname, para
	local ret, secdata

	for uciname, sections in pairs(webdata) do
		if "string" ~= type(uciname) or "table" ~= type(sections) then
			return err.E_INVFMT, nil, nil, false
		end

		alldata[uciname] = {}
		diffdata[uciname] = {}

		for secname, para in pairs(sections) do
			if "string" ~= type(secname) or "table" ~= type(para) then
				return err.E_INVFMT, nil, nil, false
			end

			ret, secdata = get_name_data(uciname, secname)
			if err.E_NONE == ret then
				alldata[uciname][secname] = secdata
				diffdata[uciname][secname] = {}

				for k, v in pairs(para) do
					if secdata[k] ~= v then
						diffdata[uciname][secname][k] = v
						changed = true
					end
				end
			else
				alldata[uciname][secname] = {}
				diffdata[uciname][secname] = para
				changed = true
			end
		end
	end

	return err.E_NONE, alldata, webdata, true
end

-- 获取delete接口所对应的flash中块数据与差异数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param webdata Web请求数据
function diff_del_data(webdata)
	return err.E_NONE, {}, webdata, true
end

-- 获取modify接口所对应的flash中块数据与差异数据
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param webdata Web请求数据
function diff_modify_data(webdata)
	local code, alldata, diffdata, changed = err.E_INVFMT, {}, {}, false
	local uciname, sections, secname, para
	local ret, secdata

	for uciname, sections in pairs(webdata) do
		if "string" ~= type(uciname) or "table" ~= type(sections) then
			return err.E_INVFMT, nil, nil, false
		end

		alldata[uciname] = {}
		diffdata[uciname] = {}

		for secname, para in pairs(sections) do
			if "string" ~= type(secname) or "table" ~= type(para) then
				return err.E_INVFMT, nil, nil, false
			end

			ret, secdata = get_name_data(uciname, secname)
			if err.E_NONE == ret then
				alldata[uciname][secname] = secdata
				diffdata[uciname][secname] = {}

				for k, v in pairs(para) do
					if secdata[k] ~= v then
						diffdata[uciname][secname][k] = v
						changed = true
					end
				end
			else
				alldata[uciname][secname] = {}
				diffdata[uciname][secname] = para
				changed = true
			end
		end
	end

	return err.E_NONE, alldata, diffdata, changed
end

-- 执行回调函数
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param cbtype 回调函数方法类型
-- @param diffdata 差异数据
-- @param alldata 所有数据
function do_callback(cbtype, webdata, diffdata, alldata, method)
	local disp = require("luci.dispatcher")

	alldata = alldata or {}

	local errcode = err.E_NONE
	local message = {}
	local datacbs = disp.context.datacbs or {}

	-- 执行回调函数
	function call(method, cbtype, uciname, secname, webpara, diffpara, allpara, msg)
		local ext_data = nil
		local uci_datacbs = datacbs[uciname] or {}
		local key_datacbs = uci_datacbs[secname] or {}
		local cbs = key_datacbs[cbtype]

		if not cbs then
			return err.E_NONE
		end

		local errcode = err.E_NONE
		for index, entry in pairs(cbs) do
			local module = require(entry.module)
			local func   = module[entry.func]
			assert(func ~= nil,
			   'Cannot resolve function "' .. entry.func .. '". Is it misspelled or local?')

			assert(type(func) == "function",
				   'The symbol "' .. entry.func .. '" does not refer to a function but data ' ..
				   'of type "' .. type(func) .. '".')

			errcode, ext_data = func(method, uciname, secname, webpara, diffpara, allpara, msg)
			if errcode ~= err.E_NONE then
				return errcode
			end
		end

		return errcode, ext_data
	end

	-- 遍历diffdata，执行回调函数
	local uciname, sections = nil
	for uciname, sections in pairs(diffdata) do
		local secname, diffpara = nil

		message[uciname] = message[uciname] or {}

		for secname, diffpara in pairs(sections) do
			local message_data = nil
			local webpara = webdata[uciname][secname]

			local allpara = {}
			if alldata[uciname] and alldata[uciname][secname] then
				allpara = alldata[uciname][secname]
			end

			errcode, message_data = call( method, cbtype, uciname, secname, webpara, diffpara, allpara, message)
			if errcode ~= err.E_NONE then
				return errcode
			end

			message[uciname][secname] = message_data or {wait_time = 2}
		end
	end

	return errcode, message
end

-- 执行检查回调函数
function do_chkcb(webdata, diffdata, alldata, method)
	return do_callback("chkfunc", webdata, diffdata, alldata, method)
end

-- 执行服务回调函数
function do_srvcb(webdata, diffdata, alldata, method)
	return do_callback("srvfunc", webdata, diffdata, alldata, method)
end

-- 过滤参数
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param diffdata 差异数据
-- @param alldata 所有数据
-- @return 错误码
function filter_args(webdata, diffdata, alldata)
	alldata = alldata or {}

	if type(webdata) ~= "table" then
		return err.E_NONE
	end

	local function filter_section(uciname, secname, web_para, diff_para, souce_data)
		-- 检查并过滤参数
		local filter_name_key = uciname .. FILTER_UCI_SEC_SEP .. secname

		local errcode = err.E_NONE
		if uci_secname_filters[filter_name_key] then
			errcode = filter(uci_secname_filters[filter_name_key], web_para, diff_para, souce_data)
			if errcode ~= err.E_NONE then
				return errcode
			end
		end

		return errcode
	end

	local errcode = err.E_NONE
	local web_para, diff_para, souce_data

	for uciname, uci_webdata in pairs(webdata) do
		for secname, web_para in pairs(uci_webdata) do
			diff_para = diffdata[uciname][secname]
			souce_data = alldata[uciname] and alldata[uciname][secname] or nil

			errcode = filter_section(uciname, secname, web_para, diff_para, souce_data)
			if err.E_NONE ~= errcode then
				return errcode
			end
		end
	end

	return errcode
end

-- 用于过滤和检查参数
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param filter_info: 过滤字段信息
-- @param sec_info: 传入的section信息
-- @return 错误码
function filter(filter_info, web_para, diff_para, souce_data)
	souce_data = souce_data or {}
	for k, v in pairs(web_para) do
		local opt_info = filter_info[k]

		-- 如果不在过滤器中，则认为是无效参数，过滤之
		if opt_info == nil then
			diff_para[k] = nil
		end

		-- 如果注册了验证函数，则进行验证
		if opt_info and opt_info[filter_key.validator] then
			local validator = opt_info[filter_key.validator]
			local args = opt_info[filter_key.args] or {}
			local modulename, funcname = util.split_module_func(validator)
			local module = nil

			if modulename ~= nil then
				module = require(modulename)
			end

			local func = module and funcname and module[funcname] or nil
			local errcode = func and func(v, web_para, diff_para, souce_data, unpack(args))

			errcode = type(errcode) == "number" and errcode or type(errcode) == "boolean"
						and errcode and err.E_NONE or err.E_INVFMT
			if errcode ~= err.E_NONE then
				return errcode
			end
		end
	end

	return err.E_NONE
end
