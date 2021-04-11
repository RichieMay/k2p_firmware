--[[
LuCI - Dispatcher

Description:
The request dispatcher and module dispatcher generators

FileId:
$Id$

License:
Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

--- LuCI web dispatcher.
local fs = require "nixio.fs"
local sys = require "luci.sys"
local init = require "luci.init"
local util = require "luci.util"
local http = require "luci.http"
local nixio = require "nixio", require "nixio.util"
local json = require("luci.json")
local ds = require("luci.controller.ds")
local err = require("luci.phicomm.error")
local lutil = require("luci.phicomm.util")
local validator = require("luci.phicomm.validator")
local sauth = require "luci.sauth"
local lucifs = require("luci.fs")

module("luci.dispatcher", package.seeall)
context = util.threadlocal()
_M.fs = fs

authenticator = {}

-- Index table
local index = nil

-- Fastindex
local fi

K_MODULE = ds.KEY_MODULE

-- 页面模板中获取json数据
function tpl_get_data(para, encode)
    local ret = ds.get_data(para)

    if encode then
        ret = json.encode(ret)
    end

    return ret
end

--[[
******************************************************************************
* AUTHOR            : LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	    : store data callback info
* TYPE              : dictionary
* CONSTRUCT         :
        key: dataer path, for example, luci.data.index
        value: index func
        for example:
        {
            ["luci.data.index1"] = index,
            ["luci.data.index2"] = index,
        }
******************************************************************************
--]]--
local dataindex = nil

--[[
******************************************************************************
* AUTHOR            : LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	    : store data callback info
* TYPE              : dictionary
* CONSTRUCT         :
        {
            uciname = {
                secname = {
					["chkfunc"] = {
						["luci.data.index1"] = "func1",
						["luci.data.index2"] = "func2"
					},
					["srvfunc"] = {
						["luci.data.index1"] = "func1",
						["luci.data.index2"] = "func2"
					}
				},
				...
            }

        }
******************************************************************************
context.datacbs = nil
--]]--
CFG_SEC_SEP = ":"

--[[
******************************************************************************
* FUNCTION        : create_dataindex()
* AUTHOR        : LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	: 创建dataindex，如果缓存中有，则直接从缓存中获取，如果缓存中没有，则创建。
* INPUT        	:
* OUTPUT        :
* RETURN        :
******************************************************************************
--]]
function create_dataindex()

    if dataindexcache then
        local cachedate = fs.stat(dataindexcache, "mtime")
        if cachedate then
            local func = loadfile(dataindexcache)
            if type(func) == "function" then
                dataindex = func()
                if dataindex ~= nil then
                    return dataindex
                end
            end
        end
    end

    local path = luci.util.libpath() .. "/data/"
    local suffixes = { ".lua", ".lua.gz" }

    local dataers = {}
    for _, suffix in ipairs(suffixes) do
        nixio.util.consume((fs.glob(path .. "*" .. suffix)), dataers)
        nixio.util.consume((fs.glob(path .. "*/*" .. suffix)), dataers)
    end
    dataindex = {}

    for i,c in ipairs(dataers) do
        local modname = "luci.data." .. c:sub(#path+1, #c):gsub("/", ".")
        for _, suffix in ipairs(suffixes) do
            modname = modname:gsub(suffix.."$", "")
        end

        local mod = require(modname)
        assert(mod ~= true,
               "Invalid dataer file found\n" ..
               "The file '" .. c .. "' contains an invalid module line.\n" ..
               "Please verify whether the module name is set to '" .. modname ..
               "' - It must correspond to the file path!")

        local idx = mod.index
        assert(type(idx) == "function",
               "Invalid dataer file found\n" ..
               "The file '" .. c .. "' contains no index() function.\n" ..
               "Please make sure that the controller contains a valid " ..
               "index function and verify the spelling!")

        dataindex[modname] = idx
    end

    if dataindexcache then
        local f = nixio.open(dataindexcache, "w", 600)
        f:writeall(util.get_bytecode(dataindex))
        f:close()
    end
end

--[[
******************************************************************************
* FUNCTION        : create_dataindex()
* AUTHOR        : LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	: 遍历dataindex中的函数，并执行
* INPUT        	:
* OUTPUT        :
* RETURN        :
******************************************************************************
--]]
function create_datacbs()
    if not dataindex then
        create_dataindex()
    end

    local ctx  = context
    ctx.datacbs = {}

    local scope = setmetatable({}, {__index = luci.dispatcher})

    for k, v in pairs(dataindex) do
        scope._NAME = k
        setfenv(v, scope)
        v()
    end

    return datacbs
end

--[[
******************************************************************************
* FUNCTION        : dataentry()
* AUTHOR        : LiGuanghua <guanghua.li@phicomm.com>
* DESCRIPTION	: 向context.datacbs中注册检查与服务回调函数
* INPUT        	:
        @param cfgname
        @param secname
        @param chkfuncname
        @param srvfuncname
* OUTPUT        :
* RETURN        :
******************************************************************************
--]]
function dataentry(cfgname, secname, chkfuncname, srvfuncname)
    local key = cfgname .. CFG_SEC_SEP .. secname
    local module = getfenv(2)._NAME
    local entry  = context.datacbs[key] or {["chkfunc"]={}, ["srvfunc"] = {}}

    if chkfuncname ~= nil then
        entry.chkfunc[module] = chkfuncname
    end

    if srvfuncname ~= nil then
        entry.srvfunc[module] = srvfuncname
    end

    context.datacbs[key] = entry

    return entry
end

-- 注册回调函数
function cbentry(uciname, keyname, chkfuncname, srvfuncname, order)
    if type(uciname) ~= "string" or type(keyname) ~= "string" then
        return nil
    end

    context.datacbs = context.datacbs or {}

    local ucicbs = context.datacbs[uciname] or {}
    local entry  = ucicbs[keyname] or {["chkfunc"]={}, ["srvfunc"] = {}}

    ucicbs[keyname] = entry
    context.datacbs[uciname] = ucicbs

    local module = getfenv(3)._NAME

    if chkfuncname ~= nil then
        if order ~= nil then
            entry.chkfunc[order] = {module=module, func=chkfuncname}
        else
            table.insert(entry.chkfunc, {module=module, func=chkfuncname})
        end
    end

    if srvfuncname ~= nil then
        if order ~= nil then
            entry.srvfunc[order] = {module=module, func=srvfuncname}
        else
            table.insert(entry.srvfunc, {module=module, func=srvfuncname})
        end
    end

    return entry
end

-- 注册secion name回调函数
function register_secname_cb(uciname, secname, chkfuncname, srvfuncname, order)
    return cbentry(uciname, secname, chkfuncname, srvfuncname, order)
end

-- 注册section name过滤器
register_secname_filter = ds.register_secname_filter

-- 注册关键字数据表
register_keyword_data = ds.register_keyword_data

-- 注册关键字修改数据表
register_keyword_set_data = ds.register_keyword_set_data

-- 注册功能模块列表
register_module = ds.register_module

--- Build the URL relative to the server webroot from given virtual path.
-- @param ...	Virtual path
-- @return         Relative URL
function build_url(...)
	local path = {...}
	local url = { http.getenv("SCRIPT_NAME") or "" }

	local k, v
	for k, v in pairs(context.urltoken) do
        url[#url+1] = "/"
        url[#url+1] = http.urlencode(k)
        url[#url+1] = "="
        url[#url+1] = http.urlencode(v)
	end

	local p
	for _, p in ipairs(path) do
        if p:match("^[a-zA-Z0-9_%-%.%%/,;]+$") then
        	url[#url+1] = "/"
        	url[#url+1] = p
        end
	end

	return table.concat(url, "")
end

--- Check whether a dispatch node shall be visible
-- @param node	Dispatch node
-- @return        Boolean indicating whether the node should be visible
function node_visible(node)
   if node then
	  return not (
         (not node.title or #node.title == 0) or
         (not node.target or node.hidden == true) or
         (type(node.target) == "table" and node.target.type == "firstchild" and
          (type(node.nodes) ~= "table" or not next(node.nodes)))
	  )
   end
   return false
end

--- Return a sorted table of visible childs within a given node
-- @param node	Dispatch node
-- @return        Ordered table of child node names
function node_childs(node)
	local rv = { }
	if node then
        local k, v
        for k, v in util.spairs(node.nodes,
        	function(a, b)
                return (node.nodes[a].order or 100)
                     < (node.nodes[b].order or 100)
        	end)
        do
        	if node_visible(v) then
                rv[#rv+1] = k
        	end
        end
	end
	return rv
end


--- Send a 404 error code and render the "error404" template if available.
-- @param message	Custom error message (optional)
-- @return        	false
function error404(message)
	luci.http.status(404, "Not Found")
	message = message or "Not Found"

	require("luci.template")
	if not luci.util.copcall(luci.template.render, "error404") then
        luci.http.prepare_content("text/plain")
        luci.http.write(message)
	end
	return false
end

--- Send a 500 error code and render the "error500" template if available.
-- @param message	Custom error message (optional)#
-- @return        	false
function error500(message)
	luci.util.perror(message)
	if not context.template_header_sent then
        luci.http.status(500, "Internal Server Error")
        luci.http.prepare_content("text/plain")
        luci.http.write(message)
	else
        require("luci.template")
        if not luci.util.copcall(luci.template.render, "error500", {message=message}) then
        	luci.http.prepare_content("text/plain")
        	luci.http.write(message)
        end
	end
	return false
end


function write_json(json)
	http.prepare_content("application/json")
	http.write_json(json, urlencode)
end

function write_unauth(code)
    local ret = {}
    ret[err.ERR_CODE] = code
    write_json(ret)
    return false
end

function authenticator.htmlauth(validator, user, users)
	local pathinfo = (http.getenv("PATH_INFO") or ""):gsub("^[/]*", "")
	local http_method = http.getenv("REQUEST_METHOD"):upper()

	if "" == pathinfo and "GET" == http_method then
        luci.template.render("index")
        return false
    end

    if "" ~= pathinfo then
        local guide = require("luci.data.guide")
        local account = guide.get_account()
        local mtime = account.mtime
        if nil == mtime or "" == mtime then
            return write_unauth(err.E_SYSRESET)
        else
            return write_unauth(err.E_UNAUTH)
        end
    else
        local protocol = require("luci.http.protocol")
        local para = http.jsondata()
        para = para or json.decode(http.get_raw_data() or "", protocol.urldecode) or {}

        -- 登录或者设置管理员密码的处理
        if "set" == para.method then
            if "table" == type(para.module) and "table" == type(para.module.security) then
                local security = para.module.security

                if "table" == type(security.login) then
                    local guide = require("luci.data.guide")
                    local account = guide.get_account()
                    local mtime = account.mtime
                    if nil == mtime or "" == mtime then
                        return write_unauth(err.E_SYSRESET)
                    end
                    local user = action_login(security.login)
                    if not user then
                        return write_unauth(err.E_LOGIN_PWD_ILLEGAL)
                    end

                    return user
                end

                if "table" == type(security.logout) then
                    action_logout(security.logout)
                    return false
                end

                if "table" == type(security.register) then
                    action_registe(security.register)
                    return false
                end

                if "table" == type(security.modify) then
                    action_modify(security.modify)
                    return false
                end

                return write_unauth(err.E_UNAUTH)
            else
                return write_unauth(err.E_UNAUTH)
            end
        else
            return write_unauth(err.E_UNAUTH)
        end
    end

    return false
end

-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param para: {"password" : "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
-- @return false/user
function action_login(para)
    local user = "admin"
    local pwd = para.password

    if "string" == type(pwd) then
        local guide = require("luci.data.guide")

        local account = guide.get_account()
        local base64 = require "luci.base64"
        local decode_pwd = base64.decode(pwd)

        if decode_pwd == account.pwd then
            --统计登录信息
            local cursor = require ("luci.model.uci").cursor()
            local login_cap = cursor:get("dev_feature", "statistic", "login")
            if "1" == login_cap then
                local stt = require("luci.phicomm.statistic")
                stt.login()
            end

            return account.user
        end
    end

    return false
end

-- 注销登录
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param para: {"stok" : "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
-- @return false/user
function action_logout(para)
    local sauth = require("luci.sauth")
    local stok = para.stok or ""
    local ip = (http.getenv("REMOTE_ADDR") or "x.x.x.x"):gsub("%.", "_")

    local sdat = sauth.read(ip)
    if sdat and sdat.token == stok then
        sauth.kill(ip)
        return write_unauth(err.E_NONE)
    end

    return write_unauth(err.E_UNAUTH)
end

-- 设置初始密码
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param para: {"password" : "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
-- @return false/user
function action_registe(para)
    local pwd = para.password
    if "string" == type(pwd) then
        local guide = require("luci.data.guide")
        local account = guide.get_account()
        local user = account.user
        local password = account.pwd
        local mtime = account.mtime

        local device = require("luci.controller.admin.device")
        local err_code, welcome = device.get_welcome_config()

        -- 密码已经被设置过
        if nil ~= mtime and "" ~= mtime then
            return write_unauth(err.E_PWD_EXIST)
        end

        --为校验密码长度，将密码decode
        local base64 = require "luci.base64"
        local decode_pwd = base64.decode(pwd)

        -- 检查密码合法性
        local check_code = validator.check_passwd(decode_pwd)
        if err.E_NONE ~= check_code then
            return write_unauth(check_code)
        end

        -- 保存登录密码
        guide.set_account(user, decode_pwd)

        -- 生成stok
        local token = luci.sys.uniqueid(16)
        local remote_ip = luci.http.getenv("REMOTE_ADDR") or "x.x.x.x"
        local ip = remote_ip:gsub("%.", "_")
        sauth.write(ip, {user=user, token=token})

        local ret = {
            [K_MODULE] = {
                security = {
                    register = {
                        stok = token,
                        ip = remote_ip,
                        guide = welcome.guide
                    }
                }
            },
            [err.ERR_CODE] = err.E_NONE
        }

        write_json(ret)

        return user
    end

    return write_unauth(err.E_UNAUTH)
end

-- 修改密码
-- @author LiGuanghua <guanghua.li@phicomm.com>
-- @param para: {"old_password" : "xxxxxx", "new_password" : "XXXXXX"}
-- @return false/user
function action_modify(para)
    local old_pwd = para.old_password
    local new_pwd = para.new_password

    if "string" == type(old_pwd) and "string" == type(new_pwd) then
        local guide = require("luci.data.guide")
        local account = guide.get_account()
        local user = account.user
        local password = account.pwd

        --为校验密码长度，将密码decode
        local base64 = require "luci.base64"
        local old_pwd_d  = base64.decode(old_pwd)
        local new_pwd_d  = base64.decode(new_pwd)

        -- 检查密码合法性
        local check_code = validator.check_passwd(new_pwd_d)
        if err.E_NONE ~= check_code then
            return write_unauth(check_code)
        end

        -- 密码不正确
        if password ~= old_pwd_d then
            return write_unauth(err.E_PWD_OLD_ILLEGAL)
        end

        -- 新登录密码和旧登录密码一样
        if old_pwd == new_pwd then
            return write_unauth(err.E_PWD_NEW_OLD_SAME)
        end

        -- 保存登录密码
        guide.modify_account(user, new_pwd_d)

        -- 清除所有session
        sauth.kill_all()

        write_unauth(err.E_NONE)

        return user
    end

    return write_unauth(err.E_UNAUTH)
end

--- Dispatch an HTTP request.
-- @param request	LuCI HTTP Request object
function httpdispatch(request, prefix)
	luci.http.context.request = request

	local r = {}
	context.request = r
	context.urltoken = {}

	local pathinfo = http.urldecode(request:getenv("PATH_INFO") or "", true)

	if prefix then
        for _, node in ipairs(prefix) do
        	r[#r+1] = node
        end
	end

	local tokensok = true
	for node in pathinfo:gmatch("[^/]+") do
        local tkey, tval
        if tokensok then
        	tkey, tval = node:match("^(%w+)=([a-fA-F0-9]*)")
        end
        if tkey then
        	context.urltoken[tkey] = tval
        else
        	tokensok = false
        	r[#r+1] = node
        end
	end

	local stat, err = util.coxpcall(function()
        dispatch(context.request)
	end, error500)

	luci.http.close()

	--context._disable_memtrace()
end

--- Dispatches a LuCI virtual path.
-- @param request	Virtual path
function dispatch(request)
	--context._disable_memtrace = require "luci.debug".trap_memtrace("l")
	local ctx = context
	ctx.path = request

	local conf = require "luci.config"
	assert(conf.main,
        "/etc/config/luci seems to be corrupt, unable to find section 'main'")

	-- crate dataer index
	if not ctx.datacbs then
        create_datacbs()
	end

	local c = ctx.tree
	local stat
	if not c then
        c = createtree()
	end

	local track = {}
	local args = {}
	ctx.args = args
	ctx.requestargs = ctx.requestargs or args
	local n
	local token = ctx.urltoken
	local preq = {}
	local freq = {}

	for i, s in ipairs(request) do
        preq[#preq+1] = s
        freq[#freq+1] = s
        c = c.nodes[s]
        n = i
        if not c then
        	break
        end

        util.update(track, c)

        if c.leaf then
        	break
        end
	end

	if c and c.leaf then
        for j=n+1, #request do
        	args[#args+1] = request[j]
        	freq[#freq+1] = request[j]
        end
	end

	ctx.requestpath = ctx.requestpath or freq
	ctx.path = preq

	-- Init template engine
	if (c and c.index) or not track.notemplate then
        local tpl = require("luci.template")
        local media = track.mediaurlbase or luci.config.main.mediaurlbase

        local function _ifattr(cond, key, val)
        	if cond then
                local env = getfenv(3)
                local scope = (type(env.self) == "table") and env.self
                return string.format(
                	' %s="%s"', tostring(key),
                	luci.util.pcdata(tostring( val
                	 or (type(env[key]) ~= "function" and env[key])
                	 or (scope and type(scope[key]) ~= "function" and scope[key])
                	 or "" ))
                )
        	else
                return ''
        	end
        end

        tpl.context.viewns = setmetatable({
           write       = luci.http.write;
           include     = function(name) tpl.Template(name):render(getfenv(2)) end;
           export      = function(k, v) if tpl.context.viewns[k] == nil then tpl.context.viewns[k] = v end end;
           striptags   = util.striptags;
           pcdata      = util.pcdata;
           media       = media;
           theme       = fs.basename(media);
           resource    = luci.config.main.resourcebase;
           ifattr      = function(...) return _ifattr(...) end;
           attr        = function(...) return _ifattr(true, ...) end;
        }, {__index=function(table, key)
        	if key == "controller" then
                return build_url()
        	elseif key == "REQUEST_URI" then
                return build_url(unpack(ctx.requestpath))
        	else
                return rawget(table, key) or _G[key]
        	end
        end})
	end

	track.dependent = (track.dependent ~= false)
	assert(not track.dependent or not track.auto,
        "Access Violation\nThe page at '" .. table.concat(request, "/") .. "/' " ..
        "has no parent node so the access to this location has been denied.\n" ..
        "This is a software bug, please report this message at " ..
        "http://luci.subsignal.org/trac/newticket"
	)

	if track.sysauth then
        local sauth = require "luci.sauth"

        local authen = type(track.sysauth_authenticator) == "function" and track.sysauth_authenticator
         or authenticator[track.sysauth_authenticator]

        local def  = (type(track.sysauth) == "string") and track.sysauth
        local accs = def and {track.sysauth} or track.sysauth
        local sess = ctx.authsession
        local verifytoken = false

        if not sess then
        	sess = ctx.urltoken.stok
        	verifytoken = true
        end

        local remote_ip = luci.http.getenv("REMOTE_ADDR") or "x.x.x.x"
        local ip = remote_ip:gsub("%.", "_")
        local sdat = sauth.read(ip)
        local user

        if sdat then
        	if not verifytoken or ctx.urltoken.stok == sdat.token then
                user = sdat.user
            end
        else
        	local eu = http.getenv("HTTP_AUTH_USER")
        	local ep = http.getenv("HTTP_AUTH_PASS")
            -- TO-DO: warning: here enable login by linux system account & password
        	if eu and ep and luci.sys.user.checkpasswd(eu, ep) then
                authen = function() return eu end
        	end
        end

        if not util.contains(accs, user) then
        	if authen then
                ctx.urltoken.stok = nil
                local user, sess = authen(luci.sys.user.checkpasswd, accs, def)
                if not user or not util.contains(accs, user) then
                	return
                else
                	local token = sdat and sdat.token or luci.sys.uniqueid(16)
                	if not sess then
                        --local token = luci.sys.uniqueid(16)
                        sauth.reap()
                        sauth.write(ip, {
                        	user=user,
                        	token=token
                        })
                        ctx.urltoken.stok = token
                	end
                	--luci.http.header("Set-Cookie", "sysauth=" .. sid.."; path="..build_url())
                	ctx.authsession = token
                	ctx.authuser = user

                	local device = require("luci.controller.admin.device")
                	local err_code, welcome = device.get_welcome_config()

                    local guide = welcome.guide
                    local ret_data = {
                        [K_MODULE] = {
                            security = {
                                login = {
                                    stok = token,
                                    ip = remote_ip,
                                    guide = guide
                                }
                            }
                        },
                        [err.ERR_CODE] = err.E_NONE
                    }

                    write_json(ret_data)
        	        return
                end
        	else
                luci.http.status(403, "Forbidden")
                return
        	end
        else
        	ctx.authsession = sess
        	ctx.authuser = user
        end
	end

	if track.setgroup then
        luci.sys.process.setgroup(track.setgroup)
	end

	if track.setuser then
        luci.sys.process.setuser(track.setuser)
	end

	local target = nil
	if c then
        if type(c.target) == "function" then
        	target = c.target
        elseif type(c.target) == "table" then
        	target = c.target.target
        end
	end

	if c and (c.index or type(target) == "function") then
        ctx.dispatched = c
        ctx.requested = ctx.requested or ctx.dispatched
	end

	if c and c.index then
        local tpl = require "luci.template"

        if util.copcall(tpl.render, "indexer", {}) then
        	return true
        end
	end

	if type(target) == "function" then
        util.copcall(function()
        	local oldenv = getfenv(target)
        	local module = require(c.module)
        	local env = setmetatable({}, {__index=

        	function(tbl, key)
                return rawget(tbl, key) or module[key] or oldenv[key]
        	end})

        	setfenv(target, env)
        end)

        local ok, err
        if type(c.target) == "table" then
        	ok, err = util.copcall(target, c.target, unpack(args))
        else
        	ok, err = util.copcall(target, unpack(args))
        end
        assert(ok,
               "Failed to execute " .. (type(c.target) == "function" and "function" or c.target.type or "unknown") ..
               " dispatcher target for entry '/" .. table.concat(request, "/") .. "'.\n" ..
               "The called action terminated with an exception:\n" .. tostring(err or "(unknown)"))
	else
        local root = node()
        if not root or not root.target then
        	error404("No root node was registered, this usually happens if no module was installed.\n" ..
        	         "Install luci-mod-base and retry. " ..
        	         "If the module is already installed, try removing the /tmp/luci-indexcache file.")
        else
        	-- Modified by guanghua.li, Redirect to home page if not found
        	-- error404("URL /" .. table.concat(request, "/") .. " Not Found")
        	luci.http.redirect(luci.http.getenv("SCRIPT_NAME"))
        end
	end
end

--- Generate the dispatching index using the best possible strategy.
function createindex()
	local path = luci.util.libpath() .. "/controller/"
	local suff = { ".lua", ".lua.gz" }

	if luci.util.copcall(require, "luci.fastindex") then
        createindex_fastindex(path, suff)
	else
        createindex_plain(path, suff)
	end
end

--- Generate the dispatching index using the fastindex C-indexer.
-- @param path        Controller base directory
-- @param suffixes	Controller file suffixes
function createindex_fastindex(path, suffixes)
	index = {}

	if not fi then
        fi = luci.fastindex.new("index")
        for _, suffix in ipairs(suffixes) do
        	fi.add(path .. "*" .. suffix)
        	fi.add(path .. "*/*" .. suffix)
        end
	end
	fi.scan()

	for k, v in pairs(fi.indexes) do
        index[v[2]] = v[1]
	end
end

--- Generate the dispatching index using the native file-cache based strategy.
-- @param path        Controller base directory
-- @param suffixes	Controller file suffixes
function createindex_plain(path, suffixes)
	if indexcache then
        local cachedate = fs.stat(indexcache, "mtime")
        if cachedate then
        	local func = loadfile(indexcache)
        	if type(func) == "function" then
                index = func()
                if index ~= nil then
                	return index
                end
        	end
        end
	end

    local controllers = { }
	for _, suffix in ipairs(suffixes) do
        nixio.util.consume((fs.glob(path .. "*" .. suffix)), controllers)
        nixio.util.consume((fs.glob(path .. "*/*" .. suffix)), controllers)
	end
	index = {}

	for i,c in ipairs(controllers) do
        local modname = "luci.controller." .. c:sub(#path+1, #c):gsub("/", ".")
        for _, suffix in ipairs(suffixes) do
        	modname = modname:gsub(suffix.."$", "")
        end

        local mod = require(modname)
        assert(mod ~= true,
               "Invalid controller file found\n" ..
               "The file '" .. c .. "' contains an invalid module line.\n" ..
               "Please verify whether the module name is set to '" .. modname ..
               "' - It must correspond to the file path!")

        local idx = mod.index
        assert(type(idx) == "function",
               "Invalid controller file found\n" ..
               "The file '" .. c .. "' contains no index() function.\n" ..
               "Please make sure that the controller contains a valid " ..
               "index function and verify the spelling!")

        index[modname] = idx
	end

	if indexcache then
        local f = nixio.open(indexcache, "w", 600)
        f:writeall(util.get_bytecode(index))
        f:close()
	end
end

--- Create the dispatching tree from the index.
-- Build the index before if it does not exist yet.
function createtree()
	if not index then
        createindex()
	end

	local ctx  = context
	local tree = {nodes={}, inreq=true}
	local modi = {}

	ctx.treecache = setmetatable({}, {__mode="v"})
	ctx.tree = tree
	ctx.modifiers = modi

	local scope = setmetatable({}, {__index = luci.dispatcher})

	for k, v in pairs(index) do
        scope._NAME = k
        setfenv(v, scope)
        v()
	end

	local function modisort(a,b)
        return modi[a].order < modi[b].order
	end

	for _, v in util.spairs(modi, modisort) do
        scope._NAME = v.module
        setfenv(v.func, scope)
        v.func()
	end

	return tree
end

--- Register a tree modifier.
-- @param	func	Modifier function
-- @param	order	Modifier order value (optional)
function modifier(func, order)
	context.modifiers[#context.modifiers+1] = {
        func = func,
        order = order or 0,
        module
        	= getfenv(2)._NAME
	}
end

--- Clone a node of the dispatching tree to another position.
-- @param	path	Virtual path destination
-- @param	clone	Virtual path source
-- @param	title	Destination node title (optional)
-- @param	order	Destination node order value (optional)
-- @return        	Dispatching tree node
function assign(path, clone, title, order)
	local obj  = node(unpack(path))
	obj.nodes  = nil
	obj.module = nil

	obj.title = title
	obj.order = order

	setmetatable(obj, {__index = _create_node(clone)})

	return obj
end

--- Create a new dispatching node and define common parameters.
-- @param	path	Virtual path
-- @param	target	Target function to call when dispatched.
-- @param	title	Destination node title
-- @param	order	Destination node order value (optional)
-- @return        	Dispatching tree node
function entry(path, target, title, order)
	local c = node(unpack(path))

	c.target = target
	c.title  = title
	c.order  = order
	c.module = getfenv(2)._NAME

	return c
end

--- Fetch or create a dispatching node without setting the target module or
-- enabling the node.
-- @param	...        Virtual path
-- @return        	Dispatching tree node
function get(...)
	return _create_node({...})
end

--- Fetch or create a new dispatching node.
-- @param	...        Virtual path
-- @return        	Dispatching tree node
function node(...)
	local c = _create_node({...})

	c.module = getfenv(2)._NAME
	c.auto = nil

	return c
end

function _create_node(path)
	if #path == 0 then
        return context.tree
	end

	local name = table.concat(path, ".")
	local c = context.treecache[name]

	if not c then
        local last = table.remove(path)
        local parent = _create_node(path)

        c = {nodes={}, auto=true}
        -- the node is "in request" if the request path matches
        -- at least up to the length of the node path
        if parent.inreq and context.path[#path+1] == last then
          c.inreq = true
        end
        parent.nodes[last] = c
        context.treecache[name] = c
	end
	return c
end

-- Subdispatchers --

function _firstchild()
   local path = { unpack(context.path) }
   local name = table.concat(path, ".")
   local node = context.treecache[name]

   local lowest
   if node and node.nodes and next(node.nodes) then
	  local k, v
	  for k, v in pairs(node.nodes) do
         if not lowest or
        	(v.order or 100) < (node.nodes[lowest].order or 100)
         then
        	lowest = k
         end
	  end
   end

   assert(lowest ~= nil,
          "The requested node contains no childs, unable to redispatch")

   path[#path+1] = lowest
   dispatch(path)
end

--- Alias the first (lowest order) page automatically
function firstchild()
   return { type = "firstchild", target = _firstchild }
end

--- Create a redirect to another dispatching node.
-- @param	...        Virtual path destination
function alias(...)
	local req = {...}
	return function(...)
        for _, r in ipairs({...}) do
        	req[#req+1] = r
        end

        dispatch(req)
	end
end

--- Rewrite the first x path values of the request.
-- @param	n        Number of path values to replace
-- @param	...        Virtual path to replace removed path values with
function rewrite(n, ...)
	local req = {...}
	return function(...)
        local dispatched = util.clone(context.dispatched)

        for i=1,n do
        	table.remove(dispatched, 1)
        end

        for i, r in ipairs(req) do
        	table.insert(dispatched, i, r)
        end

        for _, r in ipairs({...}) do
        	dispatched[#dispatched+1] = r
        end

        dispatch(dispatched)
	end
end


local function _call(self, ...)
	local func = getfenv()[self.name]
	assert(func ~= nil,
	       'Cannot resolve function "' .. self.name .. '". Is it misspelled or local?')

	assert(type(func) == "function",
	       'The symbol "' .. self.name .. '" does not refer to a function but data ' ..
	       'of type "' .. type(func) .. '".')

	if #self.argv > 0 then
        return func(unpack(self.argv), ...)
	else
        return func(...)
	end
end

--- Create a function-call dispatching target.
-- @param	name	Target function of local controller
-- @param	...        Additional parameters passed to the function
function call(name, ...)
	return {type = "call", argv = {...}, name = name, target = _call}
end


local _template = function(self, ...)
	require "luci.template".render(self.view)
end

--- Create a template render dispatching target.
-- @param	name	Template to be rendered
function template(name)
	return {type = "template", view = name, target = _template}
end


local function _cbi(self, ...)
	local cbi = require "luci.cbi"
	local tpl = require "luci.template"
	local http = require "luci.http"

	local config = self.config or {}
	local maps = cbi.load(self.model, ...)

	local state = nil

	for i, res in ipairs(maps) do
        res.flow = config
        local cstate = res:parse()
        if cstate and (not state or cstate < state) then
        	state = cstate
        end
	end

	local function _resolve_path(path)
        return type(path) == "table" and build_url(unpack(path)) or path
	end

	if config.on_valid_to and state and state > 0 and state < 2 then
        http.redirect(_resolve_path(config.on_valid_to))
        return
	end

	if config.on_changed_to and state and state > 1 then
        http.redirect(_resolve_path(config.on_changed_to))
        return
	end

	if config.on_success_to and state and state > 0 then
        http.redirect(_resolve_path(config.on_success_to))
        return
	end

	if config.state_handler then
        if not config.state_handler(state, maps) then
        	return
        end
	end

	http.header("X-CBI-State", state or 0)

	if not config.noheader then
        tpl.render("cbi/header", {state = state})
	end

	local redirect
	local messages
	local applymap   = false
	local pageaction = true
	local parsechain = { }

	for i, res in ipairs(maps) do
        if res.apply_needed and res.parsechain then
        	local c
        	for _, c in ipairs(res.parsechain) do
                parsechain[#parsechain+1] = c
        	end
        	applymap = true
        end

        if res.redirect then
        	redirect = redirect or res.redirect
        end

        if res.pageaction == false then
        	pageaction = false
        end

        if res.message then
        	messages = messages or { }
        	messages[#messages+1] = res.message
        end
	end

	for i, res in ipairs(maps) do
        res:render({
        	firstmap   = (i == 1),
        	applymap   = applymap,
        	redirect   = redirect,
        	messages   = messages,
        	pageaction = pageaction,
        	parsechain = parsechain
        })
	end

	if not config.nofooter then
        tpl.render("cbi/footer", {
        	flow       = config,
        	pageaction = pageaction,
        	redirect   = redirect,
        	state      = state,
        	autoapply  = config.autoapply
        })
	end
end

--- Create a CBI model dispatching target.
-- @param	model	CBI model to be rendered
function cbi(model, config)
	return {type = "cbi", config = config, model = model, target = _cbi}
end


local function _arcombine(self, ...)
	local argv = {...}
	local target = #argv > 0 and self.targets[2] or self.targets[1]
	setfenv(target.target, self.env)
	target:target(unpack(argv))
end

--- Create a combined dispatching target for non argv and argv requests.
-- @param trg1	Overview Target
-- @param trg2	Detail Target
function arcombine(trg1, trg2)
	return {type = "arcombine", env = getfenv(), target = _arcombine, targets = {trg1, trg2}}
end


local function _form(self, ...)
	local cbi = require "luci.cbi"
	local tpl = require "luci.template"
	local http = require "luci.http"

	local maps = luci.cbi.load(self.model, ...)
	local state = nil

	for i, res in ipairs(maps) do
        local cstate = res:parse()
        if cstate and (not state or cstate < state) then
        	state = cstate
        end
	end

	http.header("X-CBI-State", state or 0)
	tpl.render("header")
	for i, res in ipairs(maps) do
        res:render()
	end
	tpl.render("footer")
end

--- Create a CBI form model dispatching target.
-- @param	model	CBI form model tpo be rendered
function form(model)
	return {type = "cbi", model = model, target = _form}
end

--- No-op function used to mark translation entries for menu labels.
-- This function does not actually translate the given argument but
-- is used by build/i18n-scan.pl to find translatable entries.
function _(text)
	return text
end
