local Pool = require ( pathprefix .. ".pool" )

local pool

local Callbacks = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Callbacks.__index = Callbacks

pool = Pool ( )

function Callbacks.new ( )
	local self = setmetatable ( { }, Callbacks )
	self._callbacks = { }
	return self
end

function Callbacks:add ( event, callback )
	if self._callbacks[ event ] == nil then 
		self._callbacks[ event ] = callback 
		return
	elseif type ( self._callbacks[ event ] == "function" ) then
		local cb = self._callbacks[ event ]
		self._callbacks[ event ] = pool:pop ( )
		self._callbacks[ event ][ cb ] = cb
	end
	self._callbacks[ event ][ callback ] = callback
end

function Callbacks:remove ( event, callback )
	if self._callbacks[ event ] == nil then return
	elseif type ( self._callbacks[ event ] ) == "functon" then
		self._callbacks[ event ] = nil
	elseif type ( self._callbacks[ event ] == "table" ) then
		self._callbacks[ event ][ callbacks ] = nil
	end
end

function Callbacks:clear ( event )
	if event then
		if type ( self._callbacks[ event ] ) == "table" then
			for k, v in pairs ( self._callbacks[ event ] ) do
				self._callbacks[ event ][ k ] = nil
			end
			pool:push ( self._callbacks[ event ] )
		end
		self._callbacks[ event ] = nil
	else
		for event, cblist in pairs ( self._callbacks ) do
			self:clear ( event )
		end
	end
end

function Callbacks:run ( event, ... )
	if self._callbacks[ event ] == nil then return
	elseif type ( self._callbacks[ event ] ) == "function" then self._callbacks[ event ]( event, ... )
	else for _, func in pairs ( self._callbacks[ event ] ) do func ( event, ... ) end end
end

return Callbacks
