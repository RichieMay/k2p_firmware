--[[
**********************************************************************************
* Copyright (c) 2016 Shanghai Feixun Communication Co.,Ltd.
*
* FILE NAME  :   port_forward.lua
* VERSION    :   1.0
* DESCRIPTION:   端口转发的回调函数
*
* AUTHOR     :   LiuLinlin <linlin.liu@phicomm.com>
* CREATE DATE:   01/17/2017
*
* HISTORY    :
* 01   01/17/2017  LiuLinlin    Create.
* 02   01/20/2017  LiuLinlin	添加数据校验
**********************************************************************************
--]]
local err = require("luci.phicomm.error")
local validator = require("luci.phicomm.validator")
local ds = require("luci.controller.ds")
local KEY_VALIDATOR = ds.filter_key.validator
local KEY_ARGS = ds.filter_key.args

module("luci.data.port_forward", package.seeall)

function index()
	register_secname_cb("port_forward", "config", "check_forward_config", "apply_forward_config")
	register_secname_cb("port_forward", "forward_list", "check_forward_list", "apply_forward_list")
end

function check_forward_config(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			enable = {
				[KEY_VALIDATOR] = "luci.phicomm.validator.check_bool"
			}
		}
	)
	return err.E_NONE
end

function check_forward_list(method, uciname, secname, web_para, diff_para, souce_data)
	ds.register_secname_filter(uciname, secname,
		{
			id = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_id"
			},
			name = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_name"
			},
			ip = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_ip"
			},
			extern_port_start = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_extern_start",
				[KEY_ARGS] = {1, 65535}
			},
			extern_port_end = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_extern_end",
				[KEY_ARGS] = {1, 65535}
			},
			inner_port_start = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_inner_start",
				[KEY_ARGS] = {1, 65535}
			},
			inner_port_end = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_inner_end"
			},
			protocol = {
				[KEY_VALIDATOR] = "luci.data.port_forward.check_protocol"
			}
		}
	)
	return err.E_NONE
end

function apply_forward_config(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.port_forward_plt")
	errcode, result = plt.apply_forward_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function apply_forward_list(method, uciname, secname, web_para, diff_para, souce_data)
	local errcode, result
	local plt = require("luci.data.port_forward_plt")
	errcode, result = plt.apply_forward_list_plt(method, uciname, secname, web_para, diff_para, souce_data)
	return errcode, result
end

function check_id(value, web_para, diff_para, souce_data)
	return err.E_NONE
end

function check_name(value, web_para, diff_para, souce_data)
	if #value <= 0 then
		return err.E_PORTFORWARD_NAME_BLANK
	end

	if #value < 1 or #value > 32 then
		return err.E_PORTFORWARD_NAME_LEN
	end

	return err.E_NONE
end

function check_ip(value, web_para, diff_para, souce_data)
	local result = validator.check_ip(value)
	if result ~= err.E_NONE then
		return err.E_PORTFORWARD_IP_ILLEGAL
	end

	local lan = require("luci.controller.admin.lan")
	local _, data = lan.get_lan_config()
	local lan_ip = data.ip
	local lan_netmask = data.netmask

	result = validator.check_ip_mask(value, lan_netmask)
	if result ~= err.E_NONE then
		return err.E_PORTFORWARD_IP_ILLEGAL
	end

	if lan_ip == value then
		return err.E_PORTFORWARD_IP_LANIP_SAME
	end

	local same_lan = validator.check_same_network(lan_ip, value, lan_netmask)
	if not same_lan then
		return err.E_PORTFORWARD_IP_LANIP_SUBNET
	end

	return err.E_NONE
end

function check_extern_port(souce_data, web_para)
	local ex_start = tonumber(web_para.extern_port_start)
	local ex_end = tonumber(web_para.extern_port_end)
	local protocol = web_para.protocol
	local index, value

	if ex_start == ex_end then
		for index, value in ipairs (souce_data) do
			if value.id ~= web_para.id and
				(protocol == "3" or value.protocol == "3" or value.protocol == protocol) then
				local source_start = tonumber(value.extern_port_start)
				local source_end = tonumber(value.extern_port_end)

				if source_start <= ex_start and source_end >= ex_end then
					return false
				end
			end
		end
	else
		for index, value in ipairs (souce_data) do
			if value.id ~= web_para.id and
				(protocol == "3" or value.protocol == "3" or value.protocol == protocol) then
				local source_start = tonumber(value.extern_port_start)
				local source_end = tonumber(value.extern_port_end)

				if (source_start >= ex_start and source_end <= ex_end)
					or (source_start <= ex_start and source_end >= ex_start)
					or (source_start <= ex_end and source_end >= ex_end)
					or (source_start <= ex_start and source_end >= ex_end) then
						return false
				end
			end
		end
	end

	return true
end

function check_extern_start(value, web_para, diff_para, souce_data, min, max)
	if not validator.check_num_range(value, min, max) then
		return err.E_PORTFORWARD_EX_START_RANGE
	end

	local ex_end = web_para.extern_port_end
	local ex_start_num = tonumber(value)
	local ex_end_num = tonumber(ex_end)

	local remote_mng = require("luci.controller.admin.remote_mng")
	local _, remote_info = remote_mng.get_remote_manager_info()
	local remote_port = remote_info.port
	local remote_port_num = tonumber(remote_port)
	local remote_enable = tonumber(remote_info.enable)

	if 1 == remote_enable and remote_port_num >= ex_start_num and remote_port_num <= ex_end_num then
		return err.E_PORTFORWARD_EX_REMOTE_CONFLICT
	end

	if validator.check_num_range(ex_end, min, max) then
		if ex_start_num > ex_end_num then
			return err.E_PORTFORWARD_EX_START_END_LESS
		end
	end

	if(not check_extern_port(souce_data, web_para)) then
		return err.E_PORTFORWARD_EX_OLD_CONFLICT
	end

	return err.E_NONE
end

function check_extern_end(value, web_para, diff_para, souce_data, min, max)
	if not validator.check_num_range(value, min, max) then
		return err.E_PORTFORWARD_EX_END_RANGE
	end

	return err.E_NONE
end

function check_inner_start(value, web_para, diff_para, souce_data, min, max)
	local ex_start = web_para.extern_port_start
	local ex_end = web_para.extern_port_end
	local in_end = web_para.inner_port_end
	local in_start_num = tonumber(value)
	local in_end_num = tonumber(in_end)
	local protocol = web_para.protocol
	local index, val

	--外部端口为范围，内部端口需为单一端口号或相同范围
	if ex_start ~= ex_end then
		if value ~= in_end then
			if ex_start ~= value or ex_end ~= in_end then
				return err.E_PORTFORWARD_IN_EX_SAME
			end
		end
	--外部端口为单一端口号，内部端口也需为单一端口号
	else
		if value ~= in_end then
			return err.E_PORTFORWARD_IN_EX_SINGLE
		end
	end

	if value == in_end then
		if not validator.check_num_range(value, min, max) then
			return err.E_PORTFORWARD_IN_START_RANGE
		end
	--[[
		for index, val in ipairs(souce_data) do
			if val.id ~= web_para.id and
				(protocol == "3" or val.protocol == "3" or val.protocol == protocol) then
				local source_start = tonumber(val.inner_port_start)
				local source_end = tonumber(val.inner_port_end)

				if source_start <= in_start_num and source_end >= in_end_num then
					return err.E_PORTFORWARD_IN_OLD_CONFLICT
				end
			end
		end
		]]--
	end

	return err.E_NONE
end

function check_inner_end(value, web_para, diff_para, souce_data, min, max)
	return err.E_NONE
end

function check_protocol(value, web_para, diff_para, souce_data)
	if #value == 1 then
		if value < '1' or value > '3' then
			return err.E_PORTFORWARD_PROTOCO
		end
	end
	return err.E_NONE
end