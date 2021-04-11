local e=require("luci.phicomm.error")
module("luci.controller.admin.syslog",package.seeall)

function index()
entry({"pc","syslog.htm"},template("pc/syslog")).leaf=true
end




