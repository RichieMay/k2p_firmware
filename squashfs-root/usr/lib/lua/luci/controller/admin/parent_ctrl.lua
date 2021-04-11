local err = require("luci.phicomm.error")
local dbg = require("luci.phicomm.debug")
module("luci.controller.admin.parent_ctrl", package.seeall)

function index()
	entry({"pc", "parentCtrl.htm"}, template("pc/parentCtrl")).leaf = true
	entry({"pc", "timePick.htm"}, template("pc/timePick")).leaf = true
	entry({"h5", "parentCtrl.htm"}, template("h5/parentCtrl")).leaf = true
	entry({"h5", "devList.htm"}, template("h5/devList")).leaf = true
	entry({"h5", "parentCtrlAddRule.htm"}, template("h5/parentCtrlAddRule")).leaf = true
	entry({"h5", "parentCtrlRule.htm"}, template("h5/parentCtrlRule")).leaf = true

	register_keyword_data("parent_ctrl", "config", "get_parent_config")
	register_keyword_data("parent_ctrl", "parent_list", "get_parent_list")
end

function get_parent_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.parent_ctrl_plt")
	errcode, data = plt.get_parent_config_plt(args, uciname, secname)
	return errcode, data
end

function get_parent_list(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.parent_ctrl_plt")
	errcode, data = plt.get_parent_list_plt(args, uciname, secname)
	return errcode, data
end
