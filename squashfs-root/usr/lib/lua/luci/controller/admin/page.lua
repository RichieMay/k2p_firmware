--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   page.lua
* VERSION    :   1.0
* DESCRIPTION:   page index.
*
* AUTHOR     :   LiGuanghua <guanghua.li@phicomm.com>
* CREATE DATE:   22/11/2016
*
* HISTORY    :
* 01   16/12/2016  LiGuanghua     Update page entry auth config.
* 01   22/11/2016  LiGuanghua     Create.
**********************************************************************************
]]--

module("luci.controller.admin.page", package.seeall)

function index()
	local root = node()
	if not root.target then
		root.target = alias("pc")
		root.index = true
	end

	-- 页面框架
	local page = entry({"pc"}, call("pageStyle"))
	page.sysauth = "admin"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	page = entry({"pc", "login.htm"}, template("pc/login"))
	page.sysauth = false
	page.leaf = true

	page = entry({"pc", "userAgreement.htm"}, template("pc/userAgreement"))
	page.sysauth = false
	page.leaf = true

	page = entry({"pc", "guide.htm"}, template("pc/guide"))
	page.sysauth = false
	page.leaf = true

	page = entry({"pc", "setLgPwd.htm"}, template("pc/setLgPwd"))
	page.sysauth = false
	page.leaf = true

	entry({"pc", "guideWifiSet.htm"}, template("pc/guideWifiSet")).leaf = true

	entry({"pc", "menu.htm"}, template("pc/menu")).leaf = true
	entry({"pc", "netState.htm"}, template("pc/netState")).leaf = true
	entry({"pc", "wifiConfig.htm"}, template("pc/wifiConfig")).leaf = true
	entry({"pc", "App.htm"}, template("pc/App")).leaf = true
	entry({"pc", "modifyPwd.htm"}, template("pc/modifyPwd")).leaf = true
	entry({"pc", "upgradeWgt.htm"}, template("pc/upgradeWgt")).leaf = true

	page = entry({"h5"}, call("pageStyle"))
	page.sysauth = "admin"
	page.sysauth_authenticator = "htmlauth"
	page.index = true

	page = entry({"h5", "login.htm"}, template("h5/login"))
	page.sysauth = false
	page.leaf = true

	page = entry({"h5", "userAgreement.htm"}, template("h5/userAgreement"))
	page.sysauth = false
	page.leaf = true

	page = entry({"h5", "guide.htm"}, template("h5/guide"))
	page.sysauth = false
	page.leaf = true

	page = entry({"h5", "setLgPwd.htm"}, template("h5/setLgPwd"))
	page.sysauth = false
	page.leaf = true

	entry({"h5", "guideWifiSet.htm"}, template("h5/guideWifiSet")).leaf = true

	entry({"h5", "menu.htm"}, template("h5/menu")).leaf = true
	entry({"h5", "netState.htm"}, template("h5/netState")).leaf = true
	entry({"h5", "devList.htm"}, template("h5/devList")).leaf = true
	entry({"h5", "wifiList.htm"}, template("h5/wifiList")).leaf = true
	entry({"h5", "wifiConfig.htm"}, template("h5/wifiConfig")).leaf = true
	entry({"h5", "App.htm"}, template("h5/App")).leaf = true
	entry({"h5", "modifyPwd.htm"}, template("h5/modifyPwd")).leaf = true

	local css = entry({"css"}, call("response_css"))
	css.sysauth = false
	css.leaf = true
end

function response_css(...)
	local function round(num)
		local f = num % 1
		local i = num - f;
		if f >= 0.5 then
			return i + 1
		else
			return i
		end
	end
	--采用round计算可能出现子元素宽度相加>容器宽度的情况，故采用floor的方式计算
	local function floor(num)
		if num > 1.0 then
			f = num - (num % 1)
		elseif num > 0 then
			f = 1
		else
			f = 0
		end
		return f
	end

	local http = require("luci.http")
	local w, h = 1440, 900
	local tw = tonumber(http.formvalue("width") or w)
	local th = tonumber(http.formvalue("height") or h)
	local scale = th / h
	local home = "/www/"
	local file = table.concat({...}, "/")

	local fd = io.open(home .. file)
	if not fd then
		http.status(404, "Not Found:" .. file)
		return
	end

	http.prepare_content("text/css")

	local line
	for line in fd:lines() do
		local css = string.gsub(line, "(%d+)%s*px", function(num)
			-- 按屏幕高度等比例缩放
			local trans = floor(tonumber(num) * scale)
			return tostring(trans) .. "px"
		end)

		http.write(css)
	end

	http.close()
end

function pageStyle(...) return true end
