local err = require("luci.phicomm.error")

module("luci.data.ddns_plt", package.seeall)

function index()
end

function apply_ddns_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	require ("luci.sys")
	local cursor = require("luci.model.uci").cursor()

	if nil ~= web_para.enable and "" ~= web_para.enable then
		cursor:set("ddns","myddns","enabled",web_para.enable)
	else
		cursor:set("ddns","myddns","enabled","0")
	end

	if nil ~= web_para.provider and "" ~= web_para.provider then
		cursor:set("ddns","myddns","service_name",web_para.provider)
	end

	if nil ~= web_para.user and "" ~= web_para.user then
		cursor:set("ddns","myddns","username",web_para.user)
	else
		cursor:set("ddns","myddns","username","")
	end

	if nil ~= web_para.password and "" ~= web_para.password then
		cursor:set("ddns","myddns","password",web_para.password)
	else
		cursor:set("ddns","myddns","password","")
	end

	if nil ~= web_para.domain and "" ~= web_para.domain then
		cursor:set("ddns","myddns","domain",web_para.domain)
	else
		cursor:set("ddns","myddns","domain","")
	end

	cursor:save("ddns")
	cursor:commit("ddns")

	luci.sys.exec("/etc/init.d/ddns enable")

	if cursor:get("ddns","myddns","enabled") == "1" then
		luci.sys.exec("/etc/init.d/ddns restart")
	else
		luci.sys.exec("/etc/init.d/ddns stop")
	end

	return err.E_NONE
end
