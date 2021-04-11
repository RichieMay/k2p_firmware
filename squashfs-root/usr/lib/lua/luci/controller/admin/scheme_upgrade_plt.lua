local err = require("luci.phicomm.error")

module("luci.controller.admin.scheme_upgrade_plt", package.seeall)

function index()
end

function get_scheme_upgrade_info_plt()
	local cursor = require("luci.model.uci").cursor()
	local UPDATE, CONF = "schemeupgrade", "config"
	local errcode = err.E_NONE
	local data = {}
	local _up_pubtime = ""
	data.fw_version = cursor:get("system", "system", "fw_ver") or "unknown"
	data.up_sw_ver = cursor:get(UPDATE, CONF, "sw_ver") or "unknown"
	data.up_desc = cursor:get(UPDATE, CONF, "sw_desc") or "unknown"
	_up_pubtime = cursor:get(UPDATE, CONF, "pubtime") or "unknown"
	if _up_pubtime ~= "unknown" then
		data.up_pubtime = os.date("%c", _up_pubtime)
	end
	return errcode, data
end

function set_repeat_time_plt(wait_time)
	local cmd = ""
	local wan_mac = ""
	local cursor = require("luci.model.uci").cursor()
	local UPDATE, CONF = "schemeupgrade", "config"
	cursor:set(UPDATE, CONF, "repeattime", wait_time)
	cursor:set(UPDATE, CONF, "up_scheme", "10")--stop js update
	cursor:commit(UPDATE)
	os.execute("schemeupgrade")

	if wait_time ~= "0" then --there is a need to start js update again
		cursor:set(UPDATE, CONF, "up_scheme", "3") --start js update
		cursor:commit(UPDATE)
		local nixio = require("nixio")
		local pid = nixio.fork()
		if pid == 0 then
			nixio.nanosleep(tonumber(wait_time), 0)
			os.execute("schemeupgrade")
		end
	end
	return err.E_NONE
end
