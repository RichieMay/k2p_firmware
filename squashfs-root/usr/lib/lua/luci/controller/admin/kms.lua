local e=require("luci.phicomm.error")

module("luci.controller.admin.kms",package.seeall)

function index()
entry({"pc","kms.htm"},template("pc/kms")).leaf=true

register_keyword_data("kms","config","get_kms_config")
end

function get_kms_config()
local l=require("luci.model.uci").cursor()
local re={enable=l:get("kms","kms","enable"),autokms=l:get("kms","kms","autokms")}
return e.E_NONE,re
end



