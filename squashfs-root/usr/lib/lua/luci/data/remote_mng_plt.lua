local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.remote_mng_plt", package.seeall)

function index()

end

function apply_remote_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	if web_para.enable == "0" then
		cursor:set("remote", "remote", "remote_enable", "0")
	else
		cursor:set("remote", "remote", "remote_enable", web_para.enable)
		cursor:set("remote", "remote", "remote_ip", web_para.ip)
		cursor:set("remote", "remote", "remote_port", web_para.port)
	end

if web_para.appenable=="0"then
cursor:set("remote","remote","app_enable","0")
luci.sys.call("/etc/init.d/lc disable ; /etc/init.d/http disable ; /etc/init.d/collect disable")
luci.sys.call("/etc/init.d/lc stop ; /etc/init.d/http stop ; /etc/init.d/collect stop ")
else
cursor:set("remote","remote","app_enable","1")
luci.sys.call("/etc/init.d/lc enable ; /etc/init.d/http enable ")
end

	cursor:commit("remote")
	luci.sys.call("/etc/init.d/remote enable > /dev/null; /etc/init.d/remote restart > /dev/null")

	return err.E_NONE, {wait_time = 3}
end
