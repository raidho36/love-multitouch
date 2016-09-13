local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = require ( pathprefix .. ".pool" )
local Touch = require ( pathprefix .. ".touch" )

local pool
local matan2, msqrt, mpi, m2pi = math.atan2, math.sqrt, math.pi, math.pi * 2

local Gesture = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Gesture.__index = Gesture

if ffiloaded then
	ffi.cdef ( "typedef struct gesture_t { touch_t * a, * b; int group; double x, y, angle, distance, orig_angle, orig_distance; } gesture_t;" )
	pool = Pool ( "gesture_t" )
else
	pool = Pool ( Gesture )
end

function Gesture.new ( a, b )
	local self = pool:pop ( )
	self.group = 0
	self.a = a
	self.b = b
	self.x = ( a.x + b.x ) / 2
	self.y = ( a.y + b.y ) / 2
	self.angle = 0
	self.distance = 0
	self.orig_angle = matan2 ( b.y - a.y, b.x - a.x )
	self.orig_distance = msqrt ( ( a.x - b.x ) ^ 2 + ( a.y - b.y ) ^ 2 ) 
	return self
end

function Gesture:delete ( )
	pool:push ( )
end

function Gesture:update ( )
	local a, b = self.a, self.b
	self.x = ( a.x + b.x ) / 2
	self.y = ( a.y + b.y ) / 2
	self.angle = ( matan2 ( b.y - a.y, b.x - a.x ) - self.orig_angle + mpi ) % m2pi - mpi
	self.distance = msqrt ( ( a.x - b.x ) ^ 2 + ( a.y - b.y ) ^ 2 ) - self.orig_distance
end

if ffiloaded then
	ffi.metatype ( "gesture_t", Gesture )
end

return Gesture


