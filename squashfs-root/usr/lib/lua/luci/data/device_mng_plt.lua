--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   device_mng_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的终端管理设置函数
*
* AUTHOR     :   LiGuanghua <liguanghua@phicomm.com>
* CREATE DATE:   12/12/2016
*
* HISTORY    :
* 01   12/12/2016  LiGuanghua     Create.
* 02   07/12/2017  MengQingru     Modified.剥离平台无关代码
**********************************************************************************
--]]

local err = require("luci.phicomm.error")

module("luci.data.device_mng_plt", package.seeall)

function index()

end

function apply_client_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	if not web_para.mac then
		return err.E_DEVMNG_EMAC
	end

	local mac = web_para.mac
	local cursor = require("luci.model.uci").cursor()
	local section_name = string.gsub(mac, ":", "_")

	local name = web_para.name
	local hostname = cursor:get("common_host", section_name, "hostname") or nil
	local tx_rate = web_para.upload_limit or cursor:get("device_manage", section_name, "tx_rate") or "0"
	local rx_rate = web_para.download_limit or cursor:get("device_manage", section_name, "rx_rate") or "0"
	local block_user = cursor:get("device_manage", section_name, "block_user") or "0"
	if nil ~= web_para.internet_enable then
		if web_para.internet_enable == "0" or web_para.internet_enable == 0 then
			block_user = "1"
		else
			block_user = "0"
		end
	end

	if "set" == method then
		if nil ~= name and hostname ~= name then
			if hostname then
				cursor:set("common_host", section_name, "hostname", name)
			else
				cursor:section("common_host", "host", section_name, {hostname = name})
			end
			cursor:commit("common_host")
		end
	elseif "del" == method then
		block_user = "0"
		tx_rate = "0"
		rx_rate = "0"
	end

	if "del" == method or nil ~= web_para.internet_enable or nil ~= web_para.upload_limit or nil ~= web_para.download_limit then
		os.execute("device_manage_set mac \""..mac.."\" block_user \""..block_user.."\" rx_rate \""..rx_rate.."\" tx_rate \""..tx_rate.."\" > /dev/console")
	end

	return err.E_NONE
end