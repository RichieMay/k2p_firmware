--[[

Session authentication
(c) 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id: sauth.lua 8900 2012-08-08 09:48:47Z jow $

]]--

--- LuCI session library.
module("luci.sauth", package.seeall)
require("luci.util")
require("luci.sys")
require("luci.config")
local nixio = require "nixio", require "nixio.util"
local fs = require "nixio.fs"

luci.config.sauth = luci.config.sauth or {}
sessionpath = luci.config.sauth.sessionpath
sessiontime = tonumber(luci.config.sauth.sessiontime) or 15 * 60

--- Prepare session storage by creating the session directory.
function prepare()
	fs.mkdir(sessionpath, 700)
	if not sane() then
		error("Security Exception: Session path is not sane!")
	end
end

local function _read(ip)
	local blob = fs.readfile(sessionpath .. "/" .. ip)
	return blob
end

local function _write(ip, data)
	local f = nixio.open(sessionpath .. "/" .. ip, "w", 600)
	f:writeall(data)
	f:close()

	local utime = luci.sys.uptime()
	fs.utimes(sessionpath .. "/" .. ip, utime, utime)
end

local function _checkid(ip)
	return not not (ip and ip:match("^[a-fA-F0-9_]+$"))
end

--- Write session data to a session file.
-- @param id	Session identifier
-- @param data	Session data table
function write(ip, data)
	if not sane() then
		prepare()
	end

	assert(_checkid(ip), "Security Exception: Session ID is invalid!")
	assert(type(data) == "table", "Security Exception: Session data invalid!")

	_write(ip, luci.util.get_bytecode(data))
end

--- Read a session and return its content.
-- @param id	Session identifier
-- @return		Session data table or nil if the given id is not found
function read(ip)
	if not ip or #ip == 0 then
		return nil
	end

	assert(_checkid(ip), "Security Exception: Session ID is invalid!")

	if not sane(sessionpath .. "/" .. ip) then
		return nil
	end

	local blob = _read(ip)
	local func = loadstring(blob)
	setfenv(func, {})

	local sess = func()
	assert(type(sess) == "table", "Session data invalid!")

	local mtime = fs.stat(sessionpath .. "/" .. ip, "mtime")
	local utime = luci.sys.uptime()
	if mtime + sessiontime < utime then
	    kill(ip)
	    return nil
	end

	-- modify mtime and atime of the sesstion file
	fs.utimes(sessionpath .. "/" .. ip, utime, utime)

	return sess
end

--- Check whether Session environment is sane.
-- @return Boolean status
function sane(file)
	return luci.sys.process.info("uid")
			== fs.stat(file or sessionpath, "uid")
		and fs.stat(file or sessionpath, "modestr")
			== (file and "rw-------" or "rwx------")
end

--- Kills a session
-- @param id	Session identifier
function kill(ip)
	-- assert(_checkid(ip), "Security Exception: Session ID is invalid!")
	if _checkid(ip) then fs.unlink(sessionpath .. "/" .. ip) end
end

--- Remove all session data files
function kill_all()
	if sane() then
		local ip
		for ip in nixio.fs.dir(sessionpath) do
			kill(ip)
		end
	end
end

--- Kills expired session
-- @param ip	Session identifier
function clear_expired_session(ip)
    if not ip or #ip == 0 then
		return nil
	end

	if not sane(sessionpath .. "/" .. ip) then
		return true
	end

	local blob = _read(ip)
	local func = loadstring(blob)
	setfenv(func, {})

	local sess = func()

	-- Session data invalid, clear it directly
	if type(sess) ~= "table" then
		kill(ip)
		return true
	end

	local mtime = fs.stat(sessionpath .. "/" .. ip, "mtime")
	local utime = luci.sys.uptime()
	if mtime + sessiontime < utime then
	    kill(ip)
	    return true
	end
    
    return true
end

--- Remove all expired session data files
function reap()
	if sane() then
		local ip
		for ip in nixio.fs.dir(sessionpath) do
			if _checkid(ip) then
				-- reading the session will kill it if it is expired
				clear_expired_session(ip)
			end
		end
	end
end
