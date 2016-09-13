local ffiloaded, ffi = pcall ( require, "ffi" )

if ffiloaded then 
	ffi.cdef ( "typedef struct transform_t { double x, y, a, sx, sy, ox, oy, kx, ky, _sin, _cos, _sxk, _syk; } transform_t;" )
end

local Transform = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Transform.__index = Transform

local msin, mcos = math.sin, math.cos

function Transform.new ( )
	local self = setmetatable ( { }, Transform )
	self.x = 0 --position
	self.y = 0
	self.a = 0 -- angle
	self.sx = 0 --scale
	self.sy = 0
	self.ox = 0 --origin
	self.oy = 0
	self.kx = 0 --shear
	self.ky = 0
	self._sin = 0
	self._cos = 0
	self._sxk = 0
	self._syk = 0
	return self
end

function Transform:set ( x, y, a, sx, sy, ox, oy, kx, ky )
	self.x = x or self.x
	self.y = y or self.y
	self.a = a or self.a 
	self.sx = sx or self.sx
	self.sy = sy or self.sy
	self.ox = ox or self.ox
	self.oy = oy or self.oy
	self.kx = kx or self.kx
	self.ky = ky or self.ky
	self:update ( )
end

function Transform:update ( )
	local k = 1 - self.kx * self.ky
	self._sin, self._cos = msin ( self.a ), mcos ( self.a )
	self._sxk, self._syk = 1 / ( self.sx * k ), 1 / ( self.sy * k )
end

-- world to local
function Transform:inverse ( x, y )
	x = x - self.ox - self.x
	y = y - self.oy - self.y
	local xx = x * self._cos + y * self._sin
	local yy = y * self._cos - x * self._sin
	x = ( xx - yy * self.kx ) * self._sxk + self.ox
	y = ( yy - xx * self.ky ) * self._syk + self.oy
	return x, y
end

-- local to world
function Transform:forward ( x, y )
	x = ( x - self.ox ) * self.sx
	y = ( y - self.oy ) * self.sy
	local xx = x + y * self.kx
	local yy = y + x * self.ky
	x = xx * self._cos - yy * self._sin + self.ox + self.x
	y = xx * self._sin + yy * self._cos + self.oy + self.y
	return x, y
end

if ffiloaded then
	Transform.new = ffi.typeof ( "transform_t" )
	ffi.metatype ( "transform_t", Transform )
end

return Transform
