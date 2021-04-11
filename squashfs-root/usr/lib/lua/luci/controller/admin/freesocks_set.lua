local e=require("luci.phicomm.error")
module("luci.controller.admin.freesocks_set",package.seeall)

function index()
	entry({"pc","freesocksSet.htm"},template("pc/freesocksSet")).leaf=true
end