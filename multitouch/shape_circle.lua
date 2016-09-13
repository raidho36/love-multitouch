local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = require ( pathprefix .. ".pool" )
local Transform = require ( pathprefix .. ".transform" )

local pool

local ShapeCircle = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
ShapeCircle.__index = ShapeCircle

if ffiloaded then
	ffi.cdef ( "typedef struct shape_circle_t { shapetype_t type; int group; transform_t transform; double z, r; } shape_circle_t;" )
	pool = Pool ( "shape_circle_t" )
else
	local _generator = function ( )
		local self = setmetatable ( { }, ShapeCircle )
		self.transform = Transform ( )
		return self
	end
	pool = Pool ( _generator )
end

function ShapeCircle.new ( group, x, y, r )
	local self = pool:pop ( )
	self.transform:set ( x, y, 0, 1, 1, 0, 0, 0, 0 )
	self.type = "circle"
	self.group = group
	self.z = 0
	self.r = r ^ 2
	return self
end

function ShapeCircle:delete ( )
	pool:push ( self )
end

function ShapeCircle:setGroup ( group )
	self.group = ( type ( group ) == "table" ) and group.id or ( group or 0 )
end

function ShapeCircle:hitTest ( x, y )
	x, y = self.transform:inverse ( x, y )
	if x ^ 2 + y ^ 2 > self.r then return nil
	else return self.group end
end	

function ShapeCircle:setRadius ( r )
	self.r = r ^ 2
end

if ffiloaded then
	ffi.metatype ( "shape_circle_t", ShapeCircle )
end

return ShapeCircle

