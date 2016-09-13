local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Pool.__index = Pool

-- accepts custom generator function, nil, lua table, 
-- ffi cdecl, ffi ctype for object generator
function Pool.new ( generator )
	local self = setmetatable ( { }, Pool )
	if type ( generator ) == "function" then
		self.generator = generator
	elseif ffiloaded and ( type ( generator ) == "string" or type ( generator ) == "cdata" ) then
		self.generator = ffi.typeof ( generator )
	elseif generator == nil or type ( generator ) == "table" then
		self.generator = function ( ) return setmetatable ( { }, generator ) end
	end
	self.pool = { [ 0 ] = 0 } 
	return self
end

-- retreive object if available
function Pool:pop2 ( )
	-- return table.remove ( self.pool )
	if self.pool[ 0 ] == 0 then return nil end
	local obj = self.pool[ self.pool[ 0 ] ]
	self.pool[ self.pool[ 0 ] ] = nil
	self.pool[ 0 ] = self.pool[ 0 ] - 1
	return obj
end

-- allocate new object if none available, always returns an object
function Pool:pop ( )
	--return table.remove ( self.pool ) or self.generator ( )
	if self.pool[ 0 ] == 0 then return self.generator ( ) end
	local obj = self.pool[ self.pool[ 0 ] ]
	self.pool[ self.pool[ 0 ] ] = nil
	self.pool[ 0 ] = self.pool[ 0 ] - 1
	return obj
end

-- discard used object for later reuse
function Pool:push ( obj )
	--table.insert ( self.pool, obj )
	if obj == nil then return end
	self.pool[ 0 ] = self.pool[ 0 ] + 1
	self.pool[ self.pool[ 0 ] ] = obj
end

-- preallocate objects
function Pool:generate ( num )
	--for i = 1, num do table.insert ( self.pool, self.generator ( ) ) end
	for i = self.pool[ 0 ] + 1, self.pool[ 0 ] + num do self.pool[ i ] = self.generator ( ) end
	self.pool[ 0 ] = self.pool[ 0 ] + num
end

-- clear references
function Pool:clear ( )
	--while #self.pool > 1 do table.remove ( self.pool ) end
	for i = self.pool[ 0 ], 1, -1 do self.pool[ i ] = nil end
	self.pool[ 0 ] = 0
end

return Pool
