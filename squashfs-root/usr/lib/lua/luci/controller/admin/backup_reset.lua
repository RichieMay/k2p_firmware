local err = require("luci.phicomm.error")

module("luci.controller.admin.backup_reset", package.seeall)

function index()
	entry({"pc", "backupReset.htm"}, template("pc/backupReset")).leaf = true
	entry({"system", "backup_download"}, call("download_conf")).leaf = true
	entry({"system", "backup_upload"}, call("upload_conf")).leaf = true
end

--备份配置
function download_conf()
	local download_plt = require("luci.controller.admin.backup_reset_plt")
	download_plt.download_conf_plt();
end

--上传配置
function upload_conf()
	local upload_plt = require("luci.controller.admin.backup_reset_plt")
	local error, data
	error, data = upload_plt.upload_conf_plt();

	return error, data
end
