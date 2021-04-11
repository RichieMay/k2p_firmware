local err = require("luci.phicomm.error")

module("luci.controller.admin.backup_reset_plt", package.seeall)

function index()
end

function write_response(code)
	local http = require("luci.http")

	local data = {}
	data[err.ERR_CODE] = code

	http.prepare_content("text/html")
	http.write_json(data)
	http.close()
end

function check_product_name()
	local uci_t = require "luci.model.uci".cursor()
	local cur_product_name = uci_t:get("system", "system", "hostname")
	local cfg_product_name = luci.util.exec([[head /tmp/backupFile -n 10 | grep -m 1 "product" | awk -F= '{print$2}']])
	cfg_product_name = (string.sub(cfg_product_name, 1, -2))

	if (cur_product_name == cfg_product_name) then
		return true
	else
		return false
	end
end

function check_fwversion()
	local uci_t = require "luci.model.uci".cursor()
	local cur_fwversion = uci_t:get("system", "system", "fw_ver") or "0.0.0.0"
	local cfg_fwversion = luci.util.exec([[head /tmp/backupFile -n 10 | grep -m 1 "fw_ver" | awk -F= '{print$2}']])
	local ver_cmp_Str = "verrevcmp" .. " " .. cur_fwversion .. " " .. cfg_fwversion
	local is_new_ver = luci.util.exec(ver_cmp_Str)

	if tonumber(is_new_ver) > 0 then
		return false
	else
		return true
	end
end

--备份
function generate_backup_conf()
	local util = require "luci.util"
	util.exec("sh /sbin/backup_restore --create-backup /tmp/backup_pack 2>/dev/null")
end


--备份恢复
function reset_backup_conf()
	local util = require "luci.util"
	local nixio = require "nixio"
	luci.util.exec("encryconfig decrypt /tmp/backupFile_tmp /tmp/backupFile")
	local fd = io.open( "/tmp/backupFile", r)
	--errorCode
	local restore_error_message = err.E_NONE

	if fd ~= nil then
		local line = fd:read()
		fd:close()
		if line ~= nil then
			--校验软件版本号
			if not check_fwversion() then
				restore_error_message = err.E_INCONFILE
			elseif not check_product_name() then
				restore_error_message = err.E_INCONFILE
			else
				luci.util.exec("sed 1,10d /tmp/backupFile >/tmp/restore_rm_header")
				luci.util.exec("tar -xzC/ -f /tmp/restore_rm_header")
				nixio.fs.unlink("/tmp/restore_rm_header")

				local cur_wan_mac = ""
				local network = require "luci.controller.admin.network"
				local _, wan_config = network.get_wan_config()
				if wan_config["clone_mode"] == 0 then
					cur_wan_mac = wan_config["source_mac"]
				else
					--clone mode
					cur_wan_mac = wan_config["mac"]
				end

				local cur_lan_mac = ""
				local lan = require "luci.controller.admin.lan"
				local _, lan_config = lan.get_lan_config()
				cur_lan_mac = lan_config["mac"]


				local flash_lan_mac = luci.util.exec("eth_mac r lan")
				local flash_wan_mac = luci.util.exec("eth_mac r wan")

				if cur_lan_mac ~= flash_lan_mac then
					luci.util.exec("uci set network.lan.macaddr=%s" % flash_lan_mac)
				end

				if cur_wan_mac ~= flash_wan_mac then
					luci.util.exec("uci set network.wan.macaddr=%s" % flash_wan_mac)
				end

				luci.util.exec("uci commit")
			end
		else
			restore_error_message = err.E_INCONFILE
		end
	else
		restore_error_message = err.E_INCONFILE
	end

	return restore_error_message
end

--备份配置
function download_conf_plt()
	local fs = require("luci.fs")
	local http = require("luci.http")
	local tmp_file = "/tmp/backupFile"
	local downtype=http.formvalue("downtype")
	-- 读取文件的块大小
	local bufsize = 1024

	-- 生成配置文件
	if downtype == "0" then
	 generate_backup_conf()
	 http.header('Content-Disposition', 'attachment; filename="config-%s-%s.dat"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})

	-- 返回文件

	 http.prepare_content("application/octet-stream")

	 local reader = assert(io.open(tmp_file, "rb"))
	 while true do
		local bytes = reader:read(bufsize)

		if bytes == nil then
			break
		end

		http.write(bytes)
	 end
	 reader:close()

	 -- 删除临时文件
	 fs.unlink(tmp_file)
	elseif downtype == "1" then
	 local reader = ltn12_popen("dd if=/dev/mtd0")
	 http.header('Content-Disposition', 'attachment; filename="all-%s-%s.bin"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})	
	 http.prepare_content("application/octet-stream")
	 luci.ltn12.pump.all(reader, http.write)
	elseif downtype == "2" then
	 local reader = ltn12_popen("dd if=/dev/mtd3")
	 http.header('Content-Disposition', 'attachment; filename="eeprom-%s-%s.bin"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})
	 http.prepare_content("application/octet-stream")
	 luci.ltn12.pump.all(reader, http.write)
	else
	 local reader = ltn12_popen("dd if=/dev/mtd5")
	 http.header('Content-Disposition', 'attachment; filename="firm-%s-%s.bin"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})
	 http.prepare_content("application/octet-stream")
	 luci.ltn12.pump.all(reader, http.write)
	end
end

--上传配置
function upload_conf_plt()
	local fs = require("luci.fs")
	local http = require("luci.http")

	local upload_file = "/tmp/backupFile_tmp"
	local max_size = 512 * 1024



	local fp
	http.setfilehandler(
		-- write upload file into /tmp/backupFile
		function(meta, chunk, eof)
			if not fp then
				fp = io.open(upload_file, "w")
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

	--检查长度
	local uptype=http.formvalue("uptype")
	local content_len = tonumber(length_of_file(upload_file))

	if uptype == "0" then
	 if content_len > max_size then
		http.setfilehandler(
			-- do nothing
			function(meta, chunk, eof)	end
		)

		-- execute formvalue to enable filehandler to work
		http.formvalue("filename")

		-- rm uploaded image file to release memory
		fs.unlink(upload_file)

		write_response(err.E_INCONFILE)
		return err.E_INCONFILE
	 end
	 -- upack image, check image, write to flash and reboot
	 local result = reset_backup_conf()

	 write_response(result)

	 -- rm uploaded image file to release memory
	 fs.unlink(upload_file)

	 if err.E_NONE == result then
		os.execute("(sleep 1; reboot) &")
	 end

	 return err.E_NONE
	elseif uptype == "1" then
	 if content_len ~= 16777216 then
		write_response("1111")
		return "1111"
	 end
	  fork_exec("mtd -r write /tmp/backupFile_tmp ALL") 
	elseif uptype == "2" then
	 if content_len ~= 65536 then
		write_response("1111")
		return "1111"
	 end
	 fork_exec("mtd -r write /tmp/backupFile_tmp Factory") 
	else
	 if content_len ~= 16121856 then
		write_response("1111")
		return "1111"
	 end
	 fork_exec("mtd -r write /tmp/backupFile_tmp firmware") 
	end

	 write_response("0")
	 return err.E_NONE

end

function length_of_file(filename)
  local fh = assert(io.open(filename, "rb"))
  local len = assert(fh:seek("end"))
  fh:close()
  return len
end

function fork_exec(command)
    local pid = nixio.fork()
    if pid > 0 then
        return 
    elseif pid == 0 then
        -- change to root dir
        nixio.chdir("/")

        --patch stdin, out, err to /dev/null
        local null = nixio.open("/dev/null", "w+")
        if null then
            nixio.dup(null, nixio.stderr)
            nixio.dup(null, nixio.stdout)
            nixio.dup(null, nixio.stdin)
            if null:fileno() > 2 then
                null:close()
            end
        end

        -- replace with target command
        nixio.exec("/bin/sh", "-c", command)
    end
end

function ltn12_popen(command)

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid >0 then
        fdo:close()
        local close
        return function()
            local buffer = fdi:read(2048)
            local wpid, stat = nixio.waitpid(pid, "nohang")
            if not close and wpid and stat == "extend" then
                close = true
            end

            if buffer and #buffer > 0 then
                return buffer
            elseif close then
                fdi:close()
                return nil
            end
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exec("/bin/sh", "-c", command)
    end
end

