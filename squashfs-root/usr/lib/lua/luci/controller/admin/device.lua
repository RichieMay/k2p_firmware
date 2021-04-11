local err = require("luci.phicomm.error")

module("luci.controller.admin.device", package.seeall)

function index()
	entry({"pc", "routerInfo.htm"}, template("pc/routerInfo")).leaf = true

	register_keyword_data("welcome", "config", "get_welcome_config")
	register_keyword_data("device", "info", "get_device_info")
	register_keyword_data("security", "status", "get_security_status")

	local page = node("system")
	page.target = firstchild()
	page.sysauth = "admin"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	entry({"system", "reboot"}, call("system_reboot")).leaf = true
	entry({"system", "reset"}, call("system_reset")).leaf = true

	local page = node("welcome")
	page.target = firstchild()
	page.sysauth = false
	page.index = true
	entry({"welcome", "config"}, call("set_welcome_config")).leaf = true
	entry({"welcome", "getconfig"}, call("get_welcome_getconfig")).leaf = true
end

function set_lang(para)
	local errcode, data
	local plt = require("luci.controller.admin.device_plt")
	local gd = require("luci.data.guide")
	errcode, data = gd.check_lang(para)
	if err.E_NONE == errcode then
		return plt.set_lang_plt(para)
	end
	return err.E_INVARG
end

function set_agreement(para)
	local errcode, data
	local plt = require("luci.controller.admin.device_plt")
	local gd = require("luci.data.guide")
	local validator = require("luci.phicomm.validator")
	errcode, data = validator.check_bool(para)
	if nil == plt.set_agreement_plt then
		return E_NONE
	end
	if err.E_NONE == errcode then
		return plt.set_agreement_plt(para)
	end
	return err.INVBOOL
end
function set_welcome_config()
	local http = require("luci.http")
	local LANG = "lang"
	local AGREEMENT = "agreement"
	local err_code = err.E_INVARG
	local func
	local result = {}
	local para
	local jsondata = http.jsondata()
	http.prepare_content("application/json")

	if "table" ~= type(jsondata) then
		result[err.ERR_CODE] = err.E_INVARG
		http.write_json(result)
		http.close()
		return
	end

	local welcome_config_map = {
		[LANG] = set_lang,
		[AGREEMENT] = set_agreement
	}

	for k,v in pairs(welcome_config_map) do
		if jsondata[k] then
			func = v
			para = jsondata[k]
		end
	end

	if not func then
		result[err.ERR_CODE] = err.E_INVARG
		http.write_json(result)
		http.close()
		return
	end

	err_code = func(para)
	result[err.ERR_CODE] = err_code
	http.write_json(result)
	http.close()
	return
end

function get_welcome_getconfig(args,uciname,secname)
	local errcode,result
	local ret = {}
	errcode,result = get_welcome_config(args,uciname,secname)
	local http = require("luci.http")
	http.prepare_content("application/json")
	result[err.ERR_CODE] = errcode
	ret["module"] = result
	http.write_json(ret)
	http.close()
	return
end

function get_welcome_config(args, uciname, secname)
--[[
	返回值范例
	local result = {
		guide = cursor:get("luci", "main", "guide"),
		language = cursor:get("luci", "main", "lang"),
		agreement = cursor:get("luci", "main", "agreement")
	}
]]--
	local plt = require("luci.controller.admin.device_plt")
	local errcode, result
	local uname = uciname or "welcome"
	local sname = secname or "config"
	local guide = require("luci.data.guide")
	local account = guide.get_account()
	local mtime = account.mtime
	local para = args or {}
	errcode, result = plt.get_welcome_config_plt(para, uname, sname)
	if nil == mtime or "" == mtime then
		result.factory = 1
	else
		result.factory = 0
	end
	return errcode, result
end

function get_device_info(args, uciname, secname)
	local plt = require("luci.controller.admin.device_plt")
	local errcode, result
	errcode, result = plt.get_device_info_plt(args, uciname, secname)
	return errcode, result
end

function get_security_status()
	local result = {}
	local safety = 0

	local guide = require "luci.data.guide"
	local pwd = guide.get_account().pwd
	--local base64 = require "luci.base64"
	--pwd = base64.decode(pwd)

	-- 有小写字母
	if string.find(pwd, "%l") then
		safety = safety + 1
	end

	-- 有大写字母
	if string.find(pwd, "%u") then
		safety = safety + 1
	end

	-- 有数字
	if string.find(pwd, "%d") then
		safety = safety + 1
	end

	-- 有除了小写，大写和数字
	if string.find(pwd, "%W") then
		safety = 3
	end

	result.safety = tostring(safety)

	return err.E_NONE, result
end

function system_reboot()
	local plt = require("luci.controller.admin.device_plt")
	local errcode, result
	local http = require("luci.http")
	local data = {}

	data[err.ERR_CODE] = err.E_NONE
	http.write_json(data)
	http.close()
	errcode, result = plt.system_reboot_plt()
	return errcode, result
end

function system_reset()
	local plt = require("luci.controller.admin.device_plt")
	local errcode, result
	local http = require("luci.http")
	local data = {}

	data[err.ERR_CODE] = err.E_NONE
	http.write_json(data)
	http.close()
	errcode= plt.system_reset_plt()
	return errcode
end
