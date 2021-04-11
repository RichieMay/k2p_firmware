local err = require("luci.phicomm.error")
local ds = require("luci.controller.ds")

module("luci.controller.admin.onekey_diagnosis", package.seeall)

function index()
	entry({"pc", "diagnose.htm"}, template("pc/diagnose")).leaf = true
	entry({"h5", "diagnose.htm"}, template("h5/diagnose")).leaf = true
	entry({"data", "diagnosis"}, call("ds_diagnosis"), "diagnosis").leaf = true
end

function ex_diagnosis(para, method, retdata)
	local DEV_FEATURE, STATISTIC, DIAGNOSIS = "dev_feature", "statistic", "diagnosis"
	local ret = retdata or {}
	local cursor = require ("luci.model.uci").cursor()
	local diag_cap = cursor:get(DEV_FEATURE, STATISTIC, DIAGNOSIS)

	if "1" == diag_cap and err.E_NONE == ret.error_code and "get" == method and ret.module["network"] and ret.module.network["wan_status"] then
		local stt = require("luci.phicomm.statistic")
		stt.diagnosis(ret.module.network["wan_status"])
	end
	return ret
end

function ds_diagnosis()
	ds.ds(ex_diagnosis)
end