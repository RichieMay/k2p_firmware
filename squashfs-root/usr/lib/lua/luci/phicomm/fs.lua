local require, pairs = require, pairs
local string, ipairs, io = string, ipairs, io
local err = require("luci.phicomm.error")
local fs = require("luci.fs")
local util = require("luci.util")
local shell = require("luci.phicomm.lib.shell")

local print = print

-- 模块声明
local modname = "luci.phicomm.fs"
local M = {}
_G[modname] = M
package.loaded[modname] = M
-- 继承luci.fs中的所有的函数
setmetatable(M, {__index = fs})
setfenv(1, M)

function copy(srcpath, dstpath, force)
    local force = force or false
    local argstr = "-R"
    if force then
        argstr = argstr .. "f"
    end
    
    local args = {"cp", argstr, srcpath, dstpath}
    local cmd = shell.construct_cmd(args)
    return shell.execute_cmd(cmd)
end

function remove(path, force)
    if not fs.isdirectory(path) then
        return err.E_NONE
    end
    
    local force = force or false
    local argstr = "-r"
    if force then
        argstr = argstr .. "f"
    end
    
    local args = {"rm", argstr, path}
    local cmd = shell.construct_cmd(args)
    return shell.execute_cmd(cmd)
end

-- get filenames 
function get_pat_file(dirpath, pat)
    if dirpath == nil or pat == nil then
        return {} 
    end
    
    local listfiles = fs.dir(dirpath)
    if listfiles == nil then
        return {} 
    end
    
    local filenames = {}
    for k, filename in pairs(listfiles) do
        if string.match(filename, pat) then
            filenames[#filenames + 1] = filename
        end
    end
    
    return filenames
end








