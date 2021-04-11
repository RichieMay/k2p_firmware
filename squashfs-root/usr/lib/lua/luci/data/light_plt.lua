local err = require("luci.phicomm.error")

module("luci.data.light_plt", package.seeall)

function index()
end

function apply_light_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()

	cursor:set("light_manage","pagelight","ignore",web_para.enable)
	cursor:set("light_manage","pagelight","control",web_para.control)
	cursor:save("light_manage")
	cursor:commit("light_manage")
	luci.sys.call("/etc/init.d/light_manage start");
	return err.E_NONE, {wait_time = 2}
end
