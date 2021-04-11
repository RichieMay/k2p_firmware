local err = require("luci.phicomm.error")

module("luci.controller.admin.url_block", package.seeall)

function index()
	entry({"pc", "urlBlock.htm"}, template("pc/urlBlock")).leaf = true
	entry({"pc", "urlSet.htm"}, template("pc/urlSet")).leaf = true

	register_keyword_data("url_block", "config", "get_url_block_config")
	register_keyword_data("url_block", "url_list", "get_url_list")
end

function get_url_block_config(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.url_block_plt")
	errcode, data = plt.get_url_config_plt(args, uciname, secname)
	return errcode, data
end

function get_url_list(args, uciname, secname)
	local errcode, data
	local plt = require("luci.controller.admin.url_block_plt")
	errcode, data = plt.get_url_list_plt(args, uciname, secname)
	return errcode, data
end