local i=require("luci.phicomm.error")
local e=require("luci.controller.ds")
local a=e.filter_key.validator

module("luci.data.freesocks_set",package.seeall)

function index()
	register_secname_cb("freesocks_set","config","check_freesocks_set_config","apply_freesocks_set_config")
end

function check_freesocks_set_config(t,c,l,t,t,t)
	return i.E_NONE
end

function apply_freesocks_set_config(e,e,e,l,e,e)
	if l.gfwlist then
		nixio.fs.writefile("/etc/freesocks.d/gfwlist.conf", l.gfwlist:gsub("\r\n", "\n"))
	end
	
	return i.E_NONE, {wait_time = 2}
end