local err = require("luci.phicomm.error")
local io = require "io"

module("luci.controller.admin.find_pppoe_pwd_plt", package.seeall)

function index()

end

function get_link_status_plt(args, uciname, secname)
	require ("ubus")
	local conn = ubus.connect()
	local port_link = conn:call("rth.inet", "get_port_link", {})
	local port = port_link["port_link"]
	local lan_status = "0"

	if port["port0"] == "up" or port["port1"] == "up" or port["port2"] == "up" or port["port3"] == "up" then
		lan_status = "1"
	end

	local result = {
		status = lan_status
	}

	return err.E_NONE, result
end

function get_find_pwd_conf_plt(args, uciname, secname)
	local f
	local num = 0
	local status
	local f_success, f_protocol, f_user, f_passwd
	local uci_t = require "luci.model.uci".cursor()

	luci.sys.call("/usr/sbin/pppoe-server-guide start")
	nixio.fs.remove("/etc/pppoe-passwd")

	repeat
		os.execute("sleep 2")
		num = num + 1
		status = nixio.fs.access("/etc/pppoe-passwd")
	until status or num==4

	if status then
		f = io.open("/etc/pppoe-passwd", "r")
		f_success = "1"
		f_protocol = f:read() or ""
		f_user = f:read() or ""
		f_passwd = f:read() or ""
		f:close()

		if f_user and f_passwd then
			f_user = string.sub(f_user, 6, -1)
			f_passwd = string.sub(f_passwd, 8, -1)
			uci_t:set("network", "wan", "username", f_user)
			uci_t:set("network", "wan", "password", f_passwd)
			uci_t:save("network")
			uci_t:commit("network")
		end
	else
		f_success = "0"
		f_protocol = ""
		f_user = ""
		f_passwd = ""
	end

	local result = {
		--protocol = f_protocol,
		find_success = f_success,
		user = f_user,
		password = f_passwd
	}
	luci.sys.call("/usr/sbin/pppoe-server-guide stop")

	return err.E_NONE, result
end

