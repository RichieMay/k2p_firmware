local err = require("luci.phicomm.error")

module("luci.data.dmz_plt", package.seeall)

function index()
end

function apply_dmz_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("DMZ", "DMZ", "enable", web_para.enable)
	if "1" == web_para.enable then
		cursor:set("DMZ", "DMZ", "dmz_ip", web_para.ip)
	end

	cursor:save("DMZ")
	cursor:commit("DMZ")
	cursor:apply("DMZ", false, true)
	return err.E_NONE, {wait_time = 3}
end