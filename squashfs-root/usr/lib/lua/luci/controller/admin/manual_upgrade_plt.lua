local err = require("luci.phicomm.error")

module("luci.controller.admin.manual_upgrade_plt", package.seeall)

function index()
end

function WIFEXITED(status)
	if status <= 0 then
		return status
	end

	local bit = require "nixio".bit

	return bit.rshift(status, 8)
end

--错误码适配APP
function err_app(code)
	--[[
		err.E_NONE					0,

		2/3/4: E_INVUPFILE/E_INVUPHWID/E_INVUPPRODUCTID
		E_UPGRADE_FILE_ILLEGAL
		E_UPGRADE_FILE_FORMAT
		E_UPGRADE_HARDWARE
		E_UPGRADE_PRODUCT			1(“非法的固件！”),

		5: E_INVUPREQVER
		E_UPGRADE_VERSION			2(“固件版本过旧，请优先升级到x.x.x.x版本的固件”),

		6: E_INVUPDGVER
		E_UPGRADE_DOWNGRADE			3(“错误的固件版本，请下载最新固件”),

		1: E_SYSTEM
		E_UPGRADE_DOWNLOAD_FAIL
		E_UPGRADE_UNDERWAY			4(“非法操作,固件上传失败”),

		E_UPGRADE_FILE_EMPTY		5(“固件不存在，无法进行升级操作！”),
	]]--
	if err.E_NONE == code then
		return 0
	elseif err.E_UPGRADE_FILE_ILLEGAL == code or err.E_UPGRADE_HARDWARE == code or err.E_UPGRADE_PRODUCT == code
			 or err.E_UPGRADE_FILE_FORMAT == code or 2 == code or 3 == code or 4 == code then
		return 1
	elseif err.E_UPGRADE_VERSION == code or 5 == code then
		return 2
	elseif err.E_UPGRADE_DOWNGRADE == code or 6 == code then
		return 3
	elseif err.E_UPGRADE_DOWNLOAD_FAIL == code or err.E_UPGRADE_UNDERWAY == code or 1 == code then
		return 4
	elseif err.E_UPGRADE_FILE_EMPTY == code then
		return 5
	end

	return 4
end

--@app: just for app response, true/false
function write_response(code, app)
	local http = require("luci.http")
	if app then
		co = code
		code = err_app(co)
	end

	local data = {}
	data[err.ERR_CODE] = code
	data["module"] = {}

	http.prepare_content("text/html")

	http.write_json(data)
	http.close()
end

function system_upgrade_plt()
	local fs  = require("luci.fs")
	local http = require("luci.http")

	local img_file = "/tmp/sysupgrade.bin"
	local max_size = 16 * 1024 * 1024

	local phiapp = false
	local phiapp_upload = false
	local phiapp_upgrade = false

	if http.getenv("PHIAPP_REQUEST") then
		phiapp = true
		if http.getenv("CONTENT_TYPE") == "application/json" then
			phiapp_upgrade = true
		else
			phiapp_upload = true
		end
	end

	local content_len = tonumber(http.getenv("CONTENT_LENGTH")) or 0
	if content_len > max_size then
		http.setfilehandler(
			-- do nothing
			function(meta, chunk, eof) end
		)

		-- execute formvalue to enable filehandler to work
		http.formvalue("filename")

		-- rm uploaded image file to release memory
		fs.unlink(img_file)
		write_response(err.E_UPGRADE_FILE_ILLEGAL, phiapp)

		return err.E_UPGRADE_FILE_ILLEGAL
	end

	if not phiapp_upgrade then
		local fp
		http.setfilehandler(
			-- write upload file into /tmp/sysupgrade.bin
			function(meta, chunk, eof)
				if not fp then
					fp = io.open(img_file, "w")
				end
				if chunk then
					fp:write(chunk)
				end
				if eof then
					fp:close()
				end
			end
		)

		-- execute formvalue to enable filehandler to work
		http.formvalue("filename")
	end

	local status_file = "/tmp/up_code"
	local file = io.open(status_file, "r")
	local content

	if file then
		content = file:read()
		file:close()

		local data = {}
		if content then
			local status
			for status in string.gmatch(content, "%d+") do
				table.insert(data, status)
			end
		end

		if data[1] ~= '0' then
			write_response(err.E_UPGRADE_UNDERWAY, phiapp)
			return err.E_UPGRADE_UNDERWAY
		end
	end

	-- upack image, check image, write to flash and reboot
	local cmd = "manual_upgrade "
	if phiapp then
		if phiapp_upload then
			if content_len > 0 then
				cmd = cmd .. "-c " .. img_file
			else
				os.remove(img_file)
				write_response(err.E_UPGRADE_DOWNLOAD_FAIL, phiapp)
				return err.E_UPGRADE_DOWNLOAD_FAIL
			end
		elseif phiapp_upgrade then
			local fp1 = io.open(img_file, "rb")
			if fp1 then
				fp1:close()
				cmd = cmd .. "-u " .. img_file
			else
				write_response(err.E_UPGRADE_FILE_EMPTY, phiapp)
				return err.E_UPGRADE_FILE_EMPTY
			end
		end
		local ret = WIFEXITED(os.execute(cmd))
		write_response(ret, phiapp)
	else
		local uptype=http.formvalue("uptype")
		local savetype=http.formvalue("savetype")
		local boottype=http.formvalue("boottype")
		if uptype == "0" then
		 os.execute("/root/myup.sh " .. savetype .. " " .. boottype .. " &")
		else
		 cmd = cmd .. "-u " .. img_file .. " &"
		 os.execute(cmd)
       	        end


		write_response(err.E_NONE, phiapp)
	end

	return err.E_NONE
end

function get_upgrade_status_plt()
	local status_file = "/tmp/up_code"
	local file = io.open(status_file, "r")
	local content

	if file then
		content = file:read()
		file:close()
	end

	local data = {}
	if content then
		local status
		for status in string.gmatch(content, "%d+") do
			table.insert(data, status)
		end
	end

	local result = {
		running_status = 0,
		status_code = 0,
		process_num = 0
	}

	result.running_status = data[1]
	result.status_code = data[2]
	result.process_num = data[3]

	return err.E_NONE, result
end
