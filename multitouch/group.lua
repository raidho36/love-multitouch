local Pool = require ( pathprefix .. ".pool" )
local Callbacks = require ( pathprefix .. ".callbacks" )

local Group = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Group.__index = Group
Group._id = -1

function Group._generateId ( )
	Group._id = Group._id + 1
	return Group._id
end

local pool

do
	local _generator = function ( )
		local self = setmetatable ( { }, Group )
		self.present = { }
		self.past = { }
		self.callbacks = Callbacks ( )
		self.id = Group._generateId ( )
		return self
	end
	pool = Pool ( _generator )
end

function Group.new ( name )
	local self = pool:pop ( )
	self.name = name
	self.gesture = nil
	self.count = 0
	return self
end

function Group:delete ( )
	-- clear tables
	for k, v in pairs ( self.present ) do
		v:delete ( )
		self.present[ k ] = nil
	end
	for k, v in pairs ( self.past ) do
		v:delete ( )
		self.past[ k ] = nil
	end
	if self.gesture then self.gesture:delete ( ) end
	self.callbacks:clear ( )
	pool:push ( self )
end

return Group
