local err = require("luci.phicomm.error")

module("luci.data.url_block_plt", package.seeall)

function index()
end

function freshruleindex()
	local count = 0
	local uci_t = require("luci.model.uci")
	local cursor = uci_t.cursor()
	cursor:foreach("url_filter", "devfilter",
		function(s)
		count = count + 1
			cursor:set("url_filter", s[".name"], "ruleindex", count)
		end)
	cursor:save("url_filter")
	cursor:commit("url_filter")
end

function apply_url_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()
	cursor:set("url_filter", "url_switch", "enabled", web_para.enable)
	cursor:save("url_filter")
	cursor:commit("url_filter")
	cursor:apply("url_filter", false, true)

	return err.E_NONE
end

function apply_url_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local http = require("luci.http")
	local uci = require("luci.model.uci")
	local cursor = uci.cursor()

	if http.getenv("PHIAPP_REQUEST") then
		return _apply_url_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	end
	if method ~= "del" then
		if tonumber(web_para.id) then
			cursor:foreach("url_filter", "devfilter",
				function(s)
					if s.ruleindex == web_para.id then
						section = s[".name"]
						return
					end
			end)
		else
			section = cursor:add("url_filter", "devfilter")
		end

		local map = {
			mac = "mac",
			name = "devName"
		}
		local k, v
		for k, v in pairs(web_para) do
			if nil ~= map[k] then
				cursor:set("url_filter", section, map[k], v)
			end
		end
		cursor:set_list("url_filter", section, "url", web_para.block_url)

	else
		for id in string.gmatch(web_para.id, "(%d+)|*") do
			cursor:foreach("url_filter", "devfilter",
				function(s)
					if s.ruleindex == web_para.id then
						section = s[".name"]
						return
					end
			end)
			cursor:delete("url_filter", section)
		end
	end

	cursor:save("url_filter")
	cursor:commit("url_filter")
	freshruleindex()
	cursor:apply("url_filter", false, true)

	return err.E_NONE
end

function set_dev_urlblock_info(t_urlBlockDelUrlList, t_urlBlockAddUrlList, section)
	local cmd = " "

	if (t_urlBlockDelUrlList) and (type(t_urlBlockDelUrlList) == "table") and (#(t_urlBlockDelUrlList) >0) then
		for k,v in pairs(t_urlBlockDelUrlList) do
			cmd = "uci del_list url_filter." .. section .. ".url=" .. v
			os.execute(cmd)
		end
	end
	if (t_urlBlockAddUrlList) and (type(t_urlBlockAddUrlList) == "table") and (#(t_urlBlockAddUrlList) >0) then
		for k,v in pairs(t_urlBlockAddUrlList) do
			cmd = "uci add_list url_filter." .. section .. ".url=" .. v
			os.execute(cmd)
		end
	end
end

function _apply_url_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local json = require("luci.json")
	local uci_t = require("luci.model.uci")
	local cursor = uci_t.cursor()

	local tb = json.decode(web_para.setUrlBlockInfo)
	local flag = 0

	for k, v in pairs(tb) do
		if type(v) == "table" then --每个设备是一个table
			flag = 0
			cursor:foreach("url_filter", "devfilter",
				function(s)
					if s and s.mac ~=nil and s.mac == v.MAC then --对已存在设备的操作
						flag = 1
						local section = s[".name"]
						if v.urlBlockDelUrlList ~=nil or v.urlBlockAddUrlList ~=nil then
							--添加或者删除某个已存在设备的url信息
							set_dev_urlblock_info(v.urlBlockDelUrlList, v.urlBlockAddUrlList,section)
						else --删除已存在设备
							cursor:delete("url_filter", section)
						end
					end
			end)
			if flag == 0 and v.urlBlockAddUrlList ~=nil then --新加一个未存在设备
				local section = cursor:section("url_filter", "devfilter")
				cursor:save("url_filter")
				cursor:commit("url_filter")
				set_dev_urlblock_info(v.urlBlockDelUrlList, v.urlBlockAddUrlList,section)
				cursor:set("url_filter", section, "mac", v.MAC)
			end
		end
	end

	cursor:save("url_filter")
	cursor:commit("url_filter")
	freshruleindex()
	cursor:apply("url_filter", false, true)
	return err.E_NONE
end

