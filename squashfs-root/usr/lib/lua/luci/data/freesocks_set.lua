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
	if l.domain_rules then
		nixio.fs.writefile("/etc/freesocks.d/domain_rules.conf", l.domain_rules:gsub("\r\n", "\n"))
	end
	
	if l.ip_rules then
		nixio.fs.writefile("/etc/freesocks.d/ip_rules.conf", l.ip_rules:gsub("\r\n", "\n"))
	end
	
	return i.E_NONE, {wait_time = 2}
end