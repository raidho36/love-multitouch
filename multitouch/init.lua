pathprefix = (...)

local Pool = require ( pathprefix .. ".pool" )
local Shape = require ( pathprefix .. ".shape" )
local Layer = require ( pathprefix .. ".layer" )
local Touch = require ( pathprefix .. ".touch" )
local Group = require ( pathprefix .. ".group" )
local Gesture = require ( pathprefix .. ".gesture" )
local Callbacks = require ( pathprefix .. ".callbacks" )

pathprefix = nil

local Multitouch = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Multitouch.__index = Multitouch

Multitouch.Shape = Shape
Multitouch.Layer = Layer
Multitouch.Group = Group

function Multitouch.new ( )
	local self = 
	{ 
		config = {
			maxTouches = 5,
			doubleTapDist = 160 * 0.2 * love.window.getPixelScale ( ),
			doubleTapTime = 0.2,
			holdTime = 0.2,
			forceUpdate = false,
			dropMoved = false,
		},
		touch = { 
			count = 0,
			present = { },
			past = { },
		},
		group = { },
		gesture = { },
		rootlayer = nil,
		rootgesture = nil,
		callbacks = nil,
		_dropcache = { },
	}
	self.rootlayer = Layer ( )
	self.callbacks = Callbacks ( )
	self.group[ 0 ] = Group ( )
	self.group[ 0 ].id = 0
	return setmetatable ( self, Multitouch )
end

function Multitouch:hookUpdates ( )
	local f = love.touchpressed
	love.touchpressed = function ( ... )
		self.touchpressed ( ... )
		if f then f ( ... ) end
	end
	
	f = love.touchreleased
	love.touchreleased = function ( ... )
		self.touchreleased ( ... )
		if f then f ( ... ) end
	end
	
	f = love.touchmoved
	love.touchmoved = function ( ... )
		self.touchmoved ( ... )
		if f then f ( ... ) end
	end
	
	f = love.update
	love.update = function ( ... )
		self.update ( ... )
		f ( ... )
		self.postupdate ( ... )
	end
end

function Multitouch:touchpressed ( dev, x, y, dx, dy, pressure )
	if self.touch.count >= self.config.maxTouches then 
		self.callbacks:run ( "maxtouches", self, dev, x, y, dx, dy, pressure )
		return
	end
	-- calling new touch object sets values for newly tapped touch
	local touch = Touch ( x, y, dx, dy, pressure ) 
	self.touch.present[ dev ] = touch
	self.touch.count = self.touch.count + 1
	
	-- double tap check
	local group_past
	local taptime = self.config.doubleTapTime
	local tapdist = self.config.doubleTapDist ^ 2
	for dev, past in pairs ( self.touch.past ) do
		if past.timer <= taptime then
			if ( x - past.x ) ^ 2 + ( y - past.y ) ^ 2 <= tapdist then
				-- record group-touch, this is used below to carry over group tap count
				group_past = self.group[ past.group ].past[ dev ] 
				-- carry over group from last touch
				touch.group = past.group
				-- carry over tap count from last touch
				touch.taps = past.taps + 1
				-- set old touch to expire immediately
				past.timer = taptime
				break
			end
		end
	end
	
	local newgroup = self.rootlayer:hitTest ( x, y ) or 0 
	-- newly tapped touch, new Touch object needed
	local gtouch = Touch ( x, y, dx, dy, pressure )
	 -- carry over touch count from same group group-touch
	if newgroup == touch.group and group_past then
		gtouch.taps = group_past.taps + 1
	else
		gtouch.taps = 1
	end
	touch.group = newgroup
	-- add group-touch to the group
	newgroup = self.group[ touch.group ]
	newgroup.present[ dev ] = gtouch
	newgroup.count = newgroup.count + 1

	self.callbacks:run ( "touchpressed", self, touch )
	newgroup.callbacks:run ( "touchpressed", newgroup, gtouch )
	-- register gesture
	if self.touch.count == 2 and not self.gesture then
		for odev, otouch in pairs ( self.touch.present ) do
			if otouch ~= touch then
				self.rootgesture = Gesture ( touch, otouch )
				self.rootgesture.group = -1
				self.gesture[ self.rootgesture ] = self.rootgesture
				self.callbacks:run ( "gesturestart", self, self.rootgesture )
				break
			end
		end
	end
	-- register group gesture
	if newgroup.count == 2 and not newgroup.gesture then
		for otdev, othertouch in pairs ( newgroup.present ) do
			if othertouch ~= gtouch then 
				newgroup.gesture = Gesture ( touch, self.touch.present[ otdev ] ) -- refer to live touches
				newgroup.gesture.group = newgroup.id
				self.gesture[ newgroup.gesture ] = newgroup.gesture
				newgroup.callbacks:run ( "gesturestart", newgroup, newgroup.gesture )
				break 
			end
		end
	end
	touch._updated = true
end

function Multitouch:touchreleased ( dev, x, y, dx, dy, pressure )
	local touch = self.touch.present[ dev ]
	if touch == nil then return end
	
	-- remove touch from present touches list, add to past touches list
	self.touch.present[ dev ] = nil
	self.touch.count = self.touch.count - 1
	self.touch.past[ dev ] = touch
	-- reset timer, keep tap count, update fields
	touch:set ( x, y, dx, dy, pressure, nil, 0, false, false, true )
	
	local newgroup = self.rootlayer:hitTest ( x, y ) or 0
	local group = self.group[ touch.group ]
	local gtouch = group.present[ dev ]
	
	-- remove touch from original group
	group.present[ dev ] = nil
	group.count = group.count - 1
	
	if newgroup ~= touch.group then
		-- put to new group past touches
		self.group[ newgroup ].past[ dev ] = gtouch
		-- reset timer and tap count, update fields
		gtouch:set ( x, y, dx, dy, pressure, 0, 0, false, false, true ) 
	else
		-- put to same group past touches
		group.past[ dev ] = gtouch
		-- don't reset tap count if it's in the same group
		gtouch:set ( x, y, dx, dy, pressure, nil, 0, false, false, true )
	end
	touch.group = newgroup
	touch._updated = true
	
	newgroup = self.group[ newgroup ]
	self.callbacks:run ( "touchreleased", self, touch )
	newgroup.callbacks:run ( "touchreleased", newgroup, gtouch )
	
	-- cancel all gestures that use this touch
	for _, gesture in pairs ( self.gesture ) do
		if gesture.a == touch or gesture.b == touch then
			if gesture.group < 0 then
				self.callbacks:run ( "gesturestop", self, gesture )
				self.rootgesture = nil
			else
				local group = self.group[ gesture.group ]
				group.callbacks:run ( "gesturestop", group, gesture )
				group.gesture = nil
			end
			self.gesture[ gesture ] = nil
		end
	end
end

local function _multitouch_touchmoved ( self, dev, x, y, dx, dy, pressure )
	local touch = self.touch.present[ dev ]
	if touch == nil then return end
	-- update basic fields
	touch:set ( x, y, dx, dy, pressure )
	
	local newgroup = self.rootlayer:hitTest ( x, y ) or 0
	local group = self.group[ touch.group ]
	local gtouch = group.present[ dev ]
	
	if touch.group ~= newgroup then
		-- reset tap count, held state and counter for different groups
		gtouch:set ( x, y, dx, dy, pressure, 0, 0, false, nil, nil )
		-- remove group-touch from original group
		group.present[ dev ] = nil
		group.count = group.count - 1
		group.callbacks:run ( "touchleave", group, gtouch )
		-- put group-touch into new group
		local group = self.group[ newgroup ]
		group.present[ dev ] = gtouch
		group.count = group.count + 1
		group.callbacks:run ( "touchenter", group, gtouch )
	else
		-- only update fields for same group
		gtouch:set ( x, y, dx, dy, pressure )
		group.callbacks:run ( "touchmoved", group, gtouch )
	end
	touch.group = newgroup
	touch._updated = true

	self.callbacks:run ( "touchmoved", self, touch )
	
	-- update all gestures that use this touch
	for _, gesture in pairs ( self.gesture ) do
		if gesture.a == touch or gesture.b == touch then
			gesture:update ( )
			if gesture.group < 0 then
				self.callbacks:run ( "gestureupdate", self, gesture )
			else
				local group = self.group[ gesture.group ]
				group.callbacks:run ( "gestureupdate", group, gesture )
			end
		end
	end
end

function Multitouch:touchmoved ( dev, x, y, dx, dy, pressure )
	if self.config.dropMoved then
		local cache = self._dropcache[ dev ] or Touch ( )
		-- accumulate DX for all touchmoved events
		cache:set ( x, y, cache.dx + dx, cache.dy + dy, pressure )
		self._dropcache[ dev ] = cache
	else
		_multitouch_touchmoved ( self, dev, x, y, dx, dy, pressure )
	end
end

function Multitouch:update ( dt )
	if self.config.dropMoved then
		for dev, touch in pairs ( self._dropcache ) do
			_multitouch_touchmoved ( self, dev, touch.x, touch.y, touch.dx, touch.dy, touch.pressure )
			self._dropcache[ dev ] = nil
			touch:delete ( )
		end
	end
	if self.config.forceUpdate then
		for dev, touch in pairs ( self.touch.present ) do
			if not touch._updated then 
				-- dx, dy = 0, 0 since it haven't moved anywhere
				_multitouch_touchmoved ( self, dev, touch.x, touch.y, 0, 0, touch.pressure ) 
			end
		end
	end
end

function Multitouch:postupdate ( dt )
	self.rootlayer:sortAll ( )
	
	-- for present touches increment timer, remove tapped state, set held state
	for dev, touch in pairs ( self.touch.present ) do
		touch._updated = false
		touch.pressed = false
		touch.timer = touch.timer + dt
		if touch.timer >= self.config.holdTime then
			if not touch.held then self.callbacks:run ( "touchheld", self, touch ) end
			touch.held = true
		end
		
		local group = self.group[ touch.group ]
		local gtouch = group.present[ dev ]
		gtouch.pressed = false
		gtouch.timer = gtouch.timer + dt
		if touch.held and touch.timer == gtouch.timer then -- prevents activating held for rolled-in group-touches
			if not gtouch.held then group.callbacks:run ( "touchheld", group, gtouch ) end
			gtouch.held = true
		end
	end
	
	-- for past touches increment timer, remove released state, autocull old touches
	for dev, touch in pairs ( self.touch.past ) do
		touch.released = false
		touch.timer = touch.timer + dt
		
		local gtouch = self.group[ touch.group ].past[ dev ]
		gtouch.released = false
		gtouch.timer = gtouch.timer + dt
		
		if touch.timer > self.config.doubleTapTime then
			self.touch.past[ dev ]:delete ( )
			self.touch.past[ dev ] = nil
			self.group[ touch.group ].past[ dev ]:delete ( )
			self.group[ touch.group ].past[ dev ] = nil
		end
	end
end

-- clears input state
function Multitouch:resetInput ( )
	-- remove present and past touches and gesture
	for dev, touch in pairs ( self.touch.present ) do
		self.touch.present[ dev ] = nil
		touch:delete ( )
	end
	for dev, touch in pairs ( self.touch.past ) do
		self.touch.past[ dev ] = nil
		touch:delete ( )
	end
	if self.rootgesture then self.rootgesture = nil end
	self.touch.count = 0
	-- ditto, per group
	for id, group in pairs ( self.group ) do
		for dev, gtouch in pairs ( group.present ) do
			group.present[ dev ] = nil
			gtouch:delete ( )
		end
		for dev, gtouch in pairs ( group.past ) do
			group.past[ dev ] = nil
			gtouch:delete ( )
		end
		if group.gesture then group.gesture = nil end
		group.count = 0
	end
	-- remove gestures
	for key, gesture in pairs ( self.gesture ) do
		self.gesture[ key ] = nil
		gesture:delete ( )
	end
end

function Multitouch:insertGroup ( group )
	self.group[ group.id ] = group
end

function Multitouch:removeGroup ( group )
	self.group[ group.id ] = nil
	-- reset group input
	for dev, gtouch in pairs ( group.present ) do
		group.present[ dev ] = nil
		gtouch:delete ( )
	end
	for dev, gtouch in pairs ( group.past ) do
		group.past[ dev ] = nil
		gtouch:delete ( )
	end
	group.count = 0
	-- clear reference, leave object hanging (it'll get scrapped eventually)
	if group.gesture then group.gesture = nil end
end

return Multitouch

