--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local io = require "io"
local fs = require "nixio.fs"
--local util = require "luci.util"
local debug = require "debug"
local string = require "string"
local package = require "package"

local type, loadfile, unpack = type, loadfile, unpack
local pairs, math, setmetatable = pairs, math, setmetatable
local loadstring, getmetatable = loadstring, getmetatable

module "luci.ccache"

--
-- Pythonic string formatting extension
--
getmetatable("").__mod = function(a, b)
	if not b then
		return a
	elseif type(b) == "table" then
		for k, _ in pairs(b) do if type(b[k]) == "userdata" then b[k] = tostring(b[k]) end end
		return a:format(unpack(b))
	else
		if type(b) == "userdata" then b = tostring(b) end
		return a:format(b)
	end
end

-- Serialize the contents of a table value.
function _serialize_table(t, seen)
	assert(not seen[t], "Recursion detected.")
	seen[t] = true

	local data  = ""
	local idata = ""
	local ilen  = 0

	for k, v in pairs(t) do
		if type(k) ~= "number" or k < 1 or math.floor(k) ~= k or ( k - #t ) > 3 then
			k = serialize_data(k, seen)
			v = serialize_data(v, seen)
			data = data .. ( #data > 0 and ", " or "" ) ..
				'[' .. k .. '] = ' .. v
		elseif k > ilen then
			ilen = k
		end
	end

	for i = 1, ilen do
		local v = serialize_data(t[i], seen)
		idata = idata .. ( #idata > 0 and ", " or "" ) .. v
	end

	return idata .. ( #data > 0 and #idata > 0 and ", " or "" ) .. data
end

--- Recursively serialize given data to lua code, suitable for restoring
-- with loadstring().
-- @param val	Value containing the data to serialize
-- @return		String value containing the serialized code
-- @see			restore_data
-- @see			get_bytecode
function serialize_data(val, seen)
	seen = seen or setmetatable({}, {__mode="k"})

	if val == nil then
		return "nil"
	elseif type(val) == "number" then
		return val
	elseif type(val) == "string" then
		return "%q" % val
	elseif type(val) == "boolean" then
		return val and "true" or "false"
	elseif type(val) == "function" then
		return "loadstring(%q)" % get_bytecode(val)
	elseif type(val) == "table" then
		return "{ " .. _serialize_table(val, seen) .. " }"
	else
		return '"[unhandled data type:' .. type(val) .. ']"'
	end
end

--- Restore data previously serialized with serialize_data().
-- @param str	String containing the data to restore
-- @return		Value containing the restored data structure
-- @see			serialize_data
-- @see			get_bytecode
function restore_data(str)
	return loadstring("return " .. str)()
end


--
-- Byte code manipulation routines
--

--- Return the current runtime bytecode of the given data. The byte code
-- will be stripped before it is returned.
-- @param val	Value to return as bytecode
-- @return		String value containing the bytecode of the given data
function get_bytecode(val)
	local code

	if type(val) == "function" then
		code = string.dump(val)
	else
		code = string.dump( loadstring( "return " .. serialize_data(val) ) )
	end

	return code -- and strip_bytecode(code)
end

function cache_ondemand(...)
	if debug.getinfo(1, 'S').source ~= "=?" then
		cache_enable(...)
	end
end

function cache_enable(cachepath, mode)
	cachepath = cachepath or "/tmp/luci-modulecache"
	mode = mode or "r--r--r--"

	local loader = package.loaders[2]

	if not fs.stat(cachepath) then
		fs.mkdir(cachepath)
	end

	local function _encode_filename(name)
		local encoded = ""
		for i=1, #name do
			encoded = encoded .. ("%2X" % string.byte(name, i))
		end
		return encoded
	end

	local function _load_sane(file)
		local stat = fs.stat(file)
		if stat then
			return loadfile(file)
		end
	end

	local function _write_sane(file, func)
        local fp = io.open(file, "w")
        if fp then
            fp:write(get_bytecode(func))
            fp:close()
            fs.chmod(file, mode)
		end
	end

	package.loaders[2] = function(mod)
		local encoded = cachepath .. "/" .. _encode_filename(mod)
		local modcons = _load_sane(encoded)
		
		if modcons then
			return modcons
		end

		-- No cachefile
		modcons = loader(mod)
		if type(modcons) == "function" then
			_write_sane(encoded, modcons)
		end
		return modcons
	end
end
