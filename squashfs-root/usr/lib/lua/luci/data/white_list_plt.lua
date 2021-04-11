local err = require("luci.phicomm.error")

module("luci.data.white_list_plt", package.seeall)

function index()
end

function apply_white_list_config_plt(method, uciname, secname, web_para, diff_para, souce_data)
	local cursor = require("luci.model.uci").cursor()

	local white_list = {}
	local block_list = {}
	local enable = diff_para.enable or ""
	local clear_all = web_para.clear_all or ""
	local pid = -1
	dbg = require("luci.phicomm.debug")

	white_list = web_para.white_list
	block_list = web_para.block_list

	if diff_para.enable ~= NULL then
		pid = nixio.fork()
		dbg.print("forked in white_list")
	end

	if pid == 0 or pid == -1 then

		if pid == 0 then
			nixio.nanosleep(1, 0)
		end

		if white_list ~= nil then
			for k,v in pairs(white_list) do
				if v.action == "add" then
					os.execute("/usr/bin/white_list_set add_wl "..v.mac)
				elseif v.action == "del" then
					os.execute("/usr/bin/white_list_set del_wl "..v.mac)
				end
			end
		end

		if enable == "1" then
			os.execute("/usr/bin/white_list_set enable")
		elseif enable =="0" then
			os.execute("/usr/bin/white_list_set disable")
		end

		if clear_all == "1" then
			os.execute("/usr/bin/white_list_set clear_bl")
			if block_list ~= nil then
				for k,v in pairs(block_list) do
					os.execute("/usr/bin/white_list -m "..v.mac)
				end
			end
		end

		if pid == 0 then
			os.exit(0)
		end
	end

	return err.E_NONE
end
