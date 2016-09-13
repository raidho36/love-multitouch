local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = require ( pathprefix .. ".pool" )
local Transform = require ( pathprefix .. ".transform" )

local pool

local ShapeRect = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
ShapeRect.__index = ShapeRect

local mabs = math.abs

if ffiloaded then
	ffi.cdef ( "typedef struct shape_rect_t { shapetype_t type; int group; transform_t transform; double z, w, h;  } shape_rect_t;" )
	pool = Pool ( "shape_rect_t" )
else
	local _generator = function ( )
		local self = setmetatable ( { }, ShapeRect )
		self.transform = Transform ( )
		return self
	end
	pool = Pool ( _generator )
end

function ShapeRect.new ( group, x, y, w, h )
	local self = pool:pop ( )
	self.transform:set ( x, y, 0, 1, 1, 0, 0, 0, 0 )
	self.type = "rect"
	self.group = group
	self.z = 0
	self.w = w / 2
	self.h = h / 2
	return self
end

function ShapeRect:delete ( )
	pool:push ( self )
end

function ShapeRect:setGroup ( group )
	self.group = ( type ( group ) == "table" ) and group.id or ( group or 0 )
end

function ShapeRect:hitTest ( x, y )
	x, y = self.transform:inverse ( x, y )
	if mabs ( x ) > self.w or mabs ( y ) > self.h then return nil
	else return self.group end
end	

function ShapeRect:setDimensions ( w, h )
	self.w = w / 2
	self.h = h / 2
end

if ffiloaded then
	ffi.metatype ( "shape_rect_t", ShapeRect )
end

return ShapeRect

