local Pool = require ( pathprefix .. ".pool" )
local Transform = require ( pathprefix .. ".transform" )

local pool

local Layer = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Layer.__index = Layer

local function _sortfunc ( a, b )
	if not a then return false
	elseif not b then return true
	else return a.z < b.z end
end

do
	local _generator = function ( )
		local self = setmetatable ( { }, Layer )
		self.transform = Transform ( )
		self.children = { [ 0 ] = 0 }
		return self
	end
	pool = Pool ( _generator )
end

function Layer.new ( )
	local self = pool:pop ( )
	self.transform:set ( 0, 0, 0, 1, 1, 0, 0, 0, 0 )
	self.z = 0
	self._dosort = false
	return self
end

function Layer:delete ( dontDeleteShapes )
	local c = self.children
	for i = c[ 0 ], 1, -1 do
		if not dontDeleteShapes or c[ i ].type == nil then
			c[ i ]:delete ( dontDeleteShapes )
		end
		c[ i ] = nil
	end
	c[ 0 ] = 0
	pool:push ( self )
end

-- fastest method is push -> sort
function Layer:insert ( obj, z )
	local c = self.children
	c[ 0 ] = c[ 0 ] + 1
	c[ c[ 0 ] ] = obj
	obj.z = z or 0
	self._dosort = true
end

function Layer:remove ( obj )
	local c = self.children
	for i = 1, c[ 0 ] do
		if c[ i ] == obj then
			c[ i ] = false
			break
		end
	end
	self._dosort = true
end

function Layer:swapDepth ( a, b )
	if type ( b ) == "number" then
		a.z = b
		self._dosort = true
	elseif a.z ~= b.z then
		local z = a.z
		a.z = b.z
		b.z = z
		self._dosort = true
	else
		-- same z coordinate, sorting not needed nor would it change anything
		local z = 0
		for i = 1, self.children[ 0 ] do
			if self.children[ i ] == a then self.children[ i ] = b; z = z + 1
			elseif self.children[ i ] == b then self.children[ i ] = a; z = z + 1
			end
			if z > 1 then break end
		end
	end
end

function Layer:sort ( )
	self._dosort = false
	local c = self.children
	table.sort ( c, _sortfunc )
	for i = c[ 0 ], 1, -1 do
		if c[ i ] then break end
		c[ 0 ] = c[ 0 ] - 1
		c[ i ] = nil
	end
end

function Layer:sortAll ( )
	local c = self.children
	if self._dosort then self:sort ( ) end
	for i = 1, c[ 0 ] do
		if c[ i ].type == nil then
			c[ i ]:sortAll ( )
		end
	end
end

function Layer:hitTest ( x, y )
	local c = self.children
	x, y = self.transform:inverse ( x, y )
	for i = 1, c[ 0 ] do
		local group = c[ i ]:hitTest ( x, y )
		if group == 0 then return nil -- special "cut out" group is hit - report as no hit
		elseif group ~= nil then return group end -- normal group is hit - report as hit
		-- nothing is hit - continue iterating
	end
	return nil
end

return Layer
