local err = require("luci.phicomm.error")

module("luci.controller.admin.network_detect_plt", package.seeall)

function index()
end

function pingalive(addr)
	local num = 1
	local size = 64

	local re = {
		wan_loss = 0,
		wan_bad = 0,
		rate = 0
		}

	if not addr or "" == addr then
		return re
	end

	local cmd = string.format("ping -c %s -s %s -W 1 -w 2 %q 2>&1", num, size, addr)
	local util = io.popen(cmd)
	if util then
		while true do
			local ln = util:read("*l")
			if not ln then break end
			local _,x = string.find(tostring(ln),"100%% packet loss")
			local _,y = string.find(tostring(ln),"bad address")
			local _,z = string.find(tostring(ln), "time=")

			if x then
				re.wan_loss = 1
				break
			end
			if y then
				re.wan_bad = 1
				break
			end

			if z then
				re.rate = tonumber(string.sub(ln, z+1, z+6))
			end
		end
	end
	util:close()

	return re
end

function get_speed_test_result()
	local INFINIT = 999
	url = {"www.baidu.com", "www.qq.com","www.taobao.com"}
	local surf_rate = INFINIT
	local tmp = 0

	for i=1,3 do
		tmp = pingalive(url[i]).rate or INFINIT
		surf_rate = (surf_rate < tmp) and surf_rate or tmp
	end

	return surf_rate
end

function get_url_analysis_plt(args, uciname, secname)
	local result = {
		state = "1"
	}

	url = "www.baidu.com"
	local x = pingalive(url).rate
	if x == nil then
		result.state = "0"
	end

	return err.E_NONE, result
end

function get_speed_detect_plt(args, uciname, secname)
	local result = {
		surf_rate = "1"
	}
	local x = get_speed_test_result()

	if x < 40 then
		result.surf_rate = "1"
	elseif x < 150 then
		result.surf_rate = "2"
	else
		result.surf_rate = "3"
	end

	return err.E_NONE, result
end

function get_current_channel( band_type )
	local phic = require "phic"
	local ifname = ""
	if band_type == "24G" then
		ifname = phic.default_2g_wireless_ifname()[1]
	elseif band_type == "5G" then
		ifname = phic.default_5g_wireless_ifname()[1]
	else
		return
	end

	local cmd = string.format("iwconfig %s", ifname)
	local util = io.popen(cmd)
	local cur_channel = 0
	if util then
		while true do
			local ln = util:read("*l")
			if not ln then break end

			local _,x = string.find(tostring(ln),"Channel=")
			if x ~=nil then
				cur_channel = tonumber(string.sub(ln, x+1, x+3))
				break
			end
		end
	end

	return cur_channel
end

function get_best_channel( band_type )

	local phic = require "phic"
	local ifname = ""
	if band_type == "24G" then
		ifname = phic.default_2g_wireless_ifname()[1]
	elseif band_type == "5G" then
		ifname = phic.default_5g_wireless_ifname()[1]
	else
		return
	end

	local cmd = string.format("iwpriv %s best_channel", ifname)
	local util = io.popen(cmd)
	local best_channel = 0
	if util then
		while true do
			local ln = util:read("*l")
			if not ln then break end

			local _,x = string.find(tostring(ln),"best_channel:")
			if x ~=nil then
				best_channel = tonumber(string.sub(ln, x+1, x+3))
				break
			end
		end
	end

	return best_channel
end

function get_channel_2g_plt(args, uciname, secname)
	local result = {}
	if get_best_channel("24G") == get_current_channel("24G") then
		result.crowd = "0"
	else
		result.crowd = "1"
	end

	return err.E_NONE, result
end

function get_channel_5g_plt(args, uciname, secname)
	local result = {}
	if get_best_channel("5G") == get_current_channel("5G") then
		result.crowd = "0"
	else
		result.crowd = "1"
	end

	return err.E_NONE, result
end
