local ffiloaded, ffi = pcall ( require, "ffi" )

if ffiloaded then
	ffi.cdef ( "typedef enum { circle, rect, poly } shapetype_t;" )
end

local ShapeCircle = require ( pathprefix .. ".shape_circle" )
local ShapeRect = require ( pathprefix .. ".shape_rect" )
local ShapePoly = require ( pathprefix .. ".shape_poly" )

local Shape = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Shape.__index = Shape

--Shape.new ( "circle", group, x, y, radius )
--Shape.new ( "rectangle", group, x, y, width, height )
--Shape.new ( "polygon", group, x, y, { x1, y1, x2, y2,.. } )
function Shape.new ( shapetype, group, x, y, a, b )
	if group == nil then group = 0 elseif type ( group ) == "table" then group = group.id end
	if shapetype == "poly" then
		return ShapePoly ( group, x, y, a )
	elseif shapetype == "rect" then
		return ShapeRect ( group, x, y, a, b )
	elseif shapetype == "circle" then
		return ShapeCircle ( group, x, y, a )
	end
end

return Shape
