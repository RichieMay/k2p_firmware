local e=require("luci.phicomm.error")
module("luci.controller.admin.tools",package.seeall)

function index()
entry({"pc","tools.htm"},template("pc/tools")).leaf=true
entry({"h5","tools.htm"},template("h5/tools")).leaf=true
register_keyword_data("tools","config","get_tools_config")
end

function get_tools_config()
local l=require("luci.model.uci").cursor()
local l={ssh_enable=l:get("tools","config","ssh_enable"),telnet_enable=l:get("tools","config","telnet_enable")}
return e.E_NONE,l
end

