local err = require("luci.phicomm.error")

module("luci.controller.admin.device_mng", package.seeall)

function index()
	entry({"pc", "deviceManage.htm"}, template("pc/deviceManage")).leaf = true
	entry({"h5", "deviceManage.htm"}, template("h5/deviceManage")).leaf = true
	entry({"h5", "editClient.htm"}, template("h5/editClient")).leaf = true

	register_keyword_data("device_manage", "client_list", "get_client_list")
	register_keyword_data("device_manage", "device_num", "get_device_num")
end

function get_client_list(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.device_mng_plt")
	errcode, data = plt.get_client_list_plt(args, uciname, secname)
	return errcode, data
end

function get_device_num(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.device_mng_plt")
	errcode, data = plt.get_device_num_plt(args, uciname, secname)
	return errcode, data
end

