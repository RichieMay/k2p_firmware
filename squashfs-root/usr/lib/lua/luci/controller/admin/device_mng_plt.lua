--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
* All rights reserved.
*
* FILE NAME  :   device_mng_plt.lua
* VERSION    :   1.0
* DESCRIPTION:   平台相关的终端管理回调函数
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

module("luci.controller.admin.device_mng_plt", package.seeall)

function index()

end

function get_client_list_plt(args, uciname, secname)
	local err, client_list
	local device_mng_lib = require("luci.adapter.device_mng")
	err, client_list = device_mng_lib.client_list()

	return err, client_list
end

function get_device_num_plt(args, uciname, secname)
	local result = {
		online_24G = 0,
		offline_24G = 0,
		online_5G = 0,
		offline_5G = 0,
		online_lan = 0,
		offline_lan = 0,
		online_guest = 0,
		offline_guest = 0
	}

	local client_list
	local device_mng_lib = require("luci.adapter.device_mng")
	_, client_list = device_mng_lib.client_list()

	--device_type     | 设备类型（0：有线，1：2.4G，2：5G，3：访客）
	--online_status   | 在线状态（1：在线，0：离线）
	for i=1,#client_list do
		client_list[i].device_type = tostring(client_list[i].device_type)
		client_list[i].online_status = tostring(client_list[i].online_status)

		if client_list[i].device_type == "1" and client_list[i].online_status == "1" then
			result.online_24G=result.online_24G+1
		elseif client_list[i].device_type == "1" and client_list[i].online_status == "0" then
			result.offline_24G=result.offline_24G+1
		elseif client_list[i].device_type == "2" and client_list[i].online_status == "1" then
			result.online_5G=result.online_5G+1
		elseif client_list[i].device_type == "2" and client_list[i].online_status == "0" then
			result.offline_5G=result.offline_5G+1
		elseif client_list[i].device_type == "0" and client_list[i].online_status == "1" then
			result.online_lan=result.online_lan+1
		elseif client_list[i].device_type == "0" and client_list[i].online_status == "0" then
			result.offline_lan=result.offline_lan+1
		elseif client_list[i].device_type == "3" and client_list[i].online_status == "1" then
			result.online_guest=result.online_guest+1
		elseif client_list[i].device_type == "3" and client_list[i].online_status == "0" then
			result.offline_guest=result.offline_guest+1
		end
	end

	return err.E_NONE, result
end