local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = require ( pathprefix .. ".pool" )

local pool

local Touch = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Touch.__index = Touch

if ffiloaded then
	ffi.cdef ( "typedef struct touch_t { double x, y, dx, dy, pressure, timer; int taps, group; bool held, pressed, released, _updated; } touch_t;" )
	pool = Pool ( "touch_t" )
else
	pool = Pool ( Touch )
end

-- this is called when touch gets pressed
-- defaults are +pressed -held -released, timer=0, taps=1
function Touch.new ( x, y, dx, dy, pressure, taps, timer, held, pressed, released )
	local self = pool:pop ( )
	self._updated = true
	self.group = 0
	self.x = x or 0
	self.y = y or 0
	self.dx = dx or 0
	self.dy = dy or 0
	self.pressure = pressure or 0
	self.taps = taps or 1
	self.timer = timer or 0
	self.held = held or false
	self.pressed = pressed or true
	self.released = released or false
	return self
end

function Touch:delete ( )
	pool:push ( self )
end

function Touch:set ( x, y, dx, dy, pressure, taps, timer, held, pressed, released )
	self.x = x or self.x
	self.y = y or self.y
	self.dx = dx or self.dx
	self.dy = dy or self.dy
	self.pressure = pressure or self.pressure
	self.taps = taps or self.taps
	self.timer = timer or self.timer
	if held ~= nil then self.held = held end
	if pressed ~= nil then self.pressed = pressed end
	if released ~= nil then self.released = released end
	return self
end

if ffiloaded then
	ffi.metatype ( "touch_t", Touch )
end

return Touch
