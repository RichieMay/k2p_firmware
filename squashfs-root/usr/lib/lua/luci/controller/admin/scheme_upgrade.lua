local err = require("luci.phicomm.error")

module("luci.controller.admin.scheme_upgrade", package.seeall)

function index()
	local upgrade = entry({"scheme_upgrade"}, call("response_scheme_upgrade"))
	upgrade.sysauth = false
	upgrade.leaf = true
end

function response_scheme_upgrade()
	local http = require("luci.http")
	local tp = http.formvalue("type")

	local function response_callback(data)
		local callback = http.formvalue("callback")
		if not callback or #callback < 0 then
			http.status(404, "Access Forbidden.")
			http.close()
		else
			local json = require("luci.json")
			local response = callback .. "(" .. json.encode(data) .. ")"
			http.prepare_content("text/javascript")
			http.write(response)
			http.close()
		end
	end

	if "get" == tp then
		local errcode,data
		errcode, data = get_scheme_upgrade_info()
		if errcode ~= err.E_NONE then
			data = {}
		end
		response_callback(data)
	elseif "set" == tp then
		local ret = {}
		local wait_time = http.formvalue("wait_time")
		local errcode, data
		if not wait_time or string.match(wait_time, "[^0-9]") then
			ret.error_code = -10209	--参数错误
		else
			errcode, data = set_repeat_time(wait_time)
			ret.error_code = errcode
		end

		response_callback(ret)
	else
		http.status(404, "Access Forbidden.")
		http.close()
	end
end

function get_scheme_upgrade_info()
	local errcode, data
	local plt = require("luci.controller.admin.scheme_upgrade_plt")
	errcode, data = plt.get_scheme_upgrade_info_plt()
	return errcode, data
end

function set_repeat_time(wait_time)
	local errcode, result
	local plt = require("luci.controller.admin.scheme_upgrade_plt")
	errcode, result = plt.set_repeat_time_plt(wait_time)
	return errcode
end
