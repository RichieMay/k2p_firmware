local i=require("luci.phicomm.error")
local e=require("luci.controller.ds")
local a=e.filter_key.validator
local cursor = uci.cursor()

module("luci.data.freesocks",package.seeall)

function index()
  register_secname_cb("freesocks","config","check_freesocks_config","apply_freesocks_config")
  register_secname_cb("freesocks","freesocks_list","check_freesocks_config","apply_freesocks_list_config")
end

function check_freesocks_config(t,c,l,t,t,t)
  return i.E_NONE
end

function apply_freesocks_config(e,e,e,l,e,e)
  local e=require("luci.model.uci").cursor()
  e:set("freesocks","global","server_index",l.server_index)
  e:commit("freesocks")

  if l.server_index=="0" then
   luci.sys.call("/etc/init.d/openwrt_freesocks disable")
   luci.sys.call("/etc/init.d/openwrt_freesocks stop")
  else
   luci.sys.call("/etc/init.d/openwrt_freesocks enable")
   luci.sys.call("/etc/init.d/openwrt_freesocks restart")
  end

  return i.E_NONE, {wait_time = 2}
end

function apply_freesocks_list_config(e,e,e,l,e,e)
  local uci = require("luci.model.uci")
  local section
  local sectionarr={}
  local iloc=1
  local iloc2=1
  cursor:foreach("freesocks", "servers", function(s)
    section = s[".name"]
    sectionarr[iloc]=s[".name"]
    iloc=iloc+1
  end)

  local map = {
        name = "alias",
        ip = "server_ip",
        port = "server_port",
        password = "key"
      }

  for k,v in pairs(l) do
    if type(v) == "table" then
      if iloc2<iloc then
        section=sectionarr[iloc2]
        iloc2=iloc2+1
      else
        section = cursor:add("freesocks", "servers")
      end
      
      for m,n in pairs(v) do
        if nil ~= map[m] then
          cursor:set("freesocks", section, map[m],n)
        end
      end
    end
  end

  while (iloc2<iloc) do
    cursor:delete("freesocks", sectionarr[iloc2])
    iloc2=iloc2+1
  end

  cursor:save("freesocks")
  cursor:commit("freesocks")
  cursor:apply("freesocks", false, true)
  return i.E_NONE, {wait_time = 2}
end


