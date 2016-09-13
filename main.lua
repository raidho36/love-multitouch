local ffi = require ( "ffi" )
local utf = require ( "utf8" )

local Multitouch = require ( "multitouch" )

local mt = Multitouch ( )
local demomt = Multitouch ( )

local w, h = love.window.getMode ( )

local l = 3
local g = 2
local selectionpos = 2
local selectionobj = nil
local selectionlayer = nil
local selectionflash = 0
local listoffset = 200
local mode = "test" 
local namegroup = nil
local inputtext = ""
local oldinputmode = 0
local groupcolors = { [0] = { 0, 0, 0, 0 } }
local animations = { }
local layercanvas = { }
local controlscanvas = nil
local defaultpoly = { closed = true }
local drag = false
local tapx, tapy, xx, yy = 0, 0, 0, 0
local largefont, smallfont
local buttonsprites = { }
local gfxscale = love.window.getPixelScale ( ) / 2

function pressedcb ( evt, src, obj )
	local a = { 0.2, 0.2 }
	if obj.taps == 1 then
		a[ 3 ] = { 255, 255, 255, 255 }
	elseif obj.taps % 3 == 0 then 
		a[ 3 ] = { 255, 100, 100, 255 }
	elseif obj.taps % 3 == 1 then
		a[ 3 ] = { 100, 255, 100, 255 }
	elseif obj.taps % 3 == 2 then
		a[ 3 ] = { 100, 100, 255, 255 }
	end
	animations[ src.id ] = a
end

function releasedcb ( evt, src, obj )
	animations[ src.id ] = { 0.4, 0.4, { 50, 50, 50, 255 } }
end

function heldcb ( evt, src, obj )
	animations[ src.id ] = { 0.5, 0.5, { 100, 255, 100, 255 } }
end

function entercb ( evt, src, obj )
	animations[ src.id ] = { 0.5, 0.5, { 100, 100, 255, 255 } }
end

function leavecb ( evt, src, obj )
	animations[ src.id ] = { 0.5, 0.5, { 255, 100, 100, 255 } }
end

function gesturestartcb ( evt, src, obj )
	animations[ src.id ] = { 0.3, 0.3, { 255, 255, 100, 255 } }
end

function gesturestopcb ( evt, src, obj )
	animations[ src.id ] = { 0.3, 0.3, { 100, 100, 50, 255 } }
end

function love.load ( )
	smallfont = love.graphics.newFont ( "/demogfx/font.ttf", 16 )
	largefont = love.graphics.newFont ( "/demogfx/font.ttf", 52 )
	for k, v in pairs ( { "raise", "lower", "next", "previous", "newlayer", "newgroup", "newshape", "cyclegroup", "cycleshape", "delete" } ) do
		buttonsprites[ v ] = love.graphics.newImage ( "/demogfx/" .. v .. ".png" )
	end

	love.graphics.setLineStyle ( "rough" )
	love.graphics.setLineWidth ( 2 )
	
	for i = 1, 5 do
		local a = 360 / 5 * i / 180 * math.pi
		defaultpoly[ i * 2 - 1 ] = math.sin ( a + math.pi ) * 100
		defaultpoly[ i * 2 - 0 ] = math.cos ( a + math.pi ) * 100
	end
	
	demomt.rootlayer.transform:set ( w / 2, h / 2 )
	
	local g1 = demomt.Group ( "base" )
	local g2 = demomt.Group ( "back" )
	groupcolors[ g1.id ] = { math.random ( 100 ) + 100, math.random ( 100 ) + 100, math.random ( 100 ) + 100, 255 }
	groupcolors[ g2.id ] = { math.random ( 100 ) + 100, math.random ( 100 ) + 100, math.random ( 100 ) + 100, 255 }
	demomt:insertGroup ( g1 )
	demomt:insertGroup ( g2 )
	g1.callbacks:add ( "touchpressed", pressedcb )
	g1.callbacks:add ( "touchreleased", releasedcb )
	g1.callbacks:add ( "touchheld", heldcb )
	g1.callbacks:add ( "touchenter", entercb )
	g1.callbacks:add ( "touchleave", leavecb )
	g1.callbacks:add ( "gesturestart", gesturestartcb )
	g1.callbacks:add ( "gesturestop", gesturestopcb )
	
	g2.callbacks:add ( "touchpressed", pressedcb )
	g2.callbacks:add ( "touchreleased", releasedcb )
	g2.callbacks:add ( "touchheld", heldcb )
	g2.callbacks:add ( "touchenter", entercb )
	g2.callbacks:add ( "touchleave", leavecb )
	g2.callbacks:add ( "gesturestart", gesturestartcb )
	g2.callbacks:add ( "gesturestop", gesturestopcb )
	
	local l1 = demomt.Layer ( )
	demomt.rootlayer:insert ( l1, 10 )
	
	local s1 = mt.Shape ( "poly", nil, 0, 0, defaultpoly )
	local s2 = mt.Shape ( "rect", g1, 0, 0, 250, 250 )
	local s3 = mt.Shape ( "circle", g1, 0, 0, 150 )
	l1:insert ( s1, 0 )
	l1:insert ( s2, 10 )
	l1:insert ( s3, 20 )
	
	local s4 = mt.Shape ( "rect", g2, 100, 100, 200, 200 )
	demomt.rootlayer:insert ( s4, 20 )
	
	layercanvas[ 1 ] = love.graphics.newCanvas ( )
	layercanvas[ 2 ] = love.graphics.newCanvas ( )
	controlcanvas = love.graphics.newCanvas ( )
	
	local kb = { raise = "pageup", lower = "pagedown", previous = "up", next = "down", delete = "delete",
		newgroup = "f2", newlayer = "f3", newshape = "f4", cycleshape = "f5", cyclegroup = "f6" }
	local function cb ( event, source, data )
		love.keypressed ( nil, kb[ source.name ] )
	end
	local guilayer = mt.Layer ( )
	mt.rootlayer:insert ( guilayer, 0 )
	local xx = { 100*gfxscale, 100*gfxscale,   300*gfxscale, 300*gfxscale,   700*gfxscale, 1000*gfxscale, w-100*gfxscale, 700*gfxscale,   850*gfxscale,     1000*gfxscale }
	local yy = { 100*gfxscale, h-100*gfxscale, 100*gfxscale, h-100*gfxscale, 100*gfxscale, 100*gfxscale,  100*gfxscale,   h-100*gfxscale, h-100*gfxscale,   h-100*gfxscale }
	local gg = { "previous",   "next",         "raise",      "lower",         "newlayer",  "delete",      "newgroup",    "newshape",      "cycleshape",     "cyclegroup" }
	for k, v in pairs ( gg ) do
		local gg = mt.Group ( v )
		mt:insertGroup ( gg )
		local bb = mt.Shape ( "circle", gg, xx[ k ], yy[ k ], 50 * gfxscale )
		gg.callbacks:add ( "touchpressed", cb )
		guilayer:insert ( bb )
	end
end

function love.textinput ( text )
	inputtext = inputtext .. text
end

function love.keypressed ( key, code, rep )
	if rep then return end
	drag = false
	if mode ~= "test" and mode ~= "name" then
		-- select shape/layer
		if code == "up" then selectionpos = selectionpos - 1; selectionflash = 0.1
		elseif code == "down" then selectionpos = selectionpos + 1; selectionflash = 0.1 end
		if selectionpos < 2 then selectionpos = 2
		elseif selectionpos > l - 1 then selectionpos = l - 1 end
		
		-- add group
		if code == "f2" then
			-- create group, add it to multitouch object
			local gg = demomt.Group ( "new group" )
			demomt:insertGroup ( gg )
			gg.callbacks:add ( "touchpressed", pressedcb )
			gg.callbacks:add ( "touchreleased", releasedcb )
			gg.callbacks:add ( "touchheld", heldcb )
			gg.callbacks:add ( "touchenter", entercb )
			gg.callbacks:add ( "touchleave", leavecb )
			gg.callbacks:add ( "gesturestart", gesturestartcb )
			gg.callbacks:add ( "gesturestop", gesturestopcb )
			-- do misc. tasks
			g = math.max ( gg.id, g )
			groupcolors[ gg.id ] = { math.random ( 100 ) + 100, math.random ( 100 ) + 100, math.random ( 100 ) + 100, 255 }
			namegroup = gg
			inputtext = ""
			oldinputmode = love.keyboard.hasTextInput ( )
			love.keyboard.setTextInput ( true )
			mode = "name"
			mt:resetInput ( )
		-- add layer
		elseif code == "f3" then
			local ll = demomt.Layer ( )
			-- layer selected, insert into it
			if selectionobj and selectionobj.type == nil then
				local z = 0
				if selectionobj.children[ 1 ] then z = selectionobj.children[ 1 ].z - 10 end
				selectionobj:insert ( ll, z )
			-- object selected, insert above
			else
				local z = selectionobj and selectionobj.z - 10 or 0
				if selectionlayer.children[ 0 ] > 1 and selectionlayer.children[ 1 ] ~= selectionobj then
					for i = 2, selectionlayer.children[ 0 ] do
						if selectionlayer.children[ i ] == selectionobj then
							z = ( selectionlayer.children[ i - 1 ].z + selectionobj.z ) / 2
							break
						end
					end
				end
				selectionlayer:insert ( ll, z )
			end
			layercanvas[ #layercanvas + 1 ] = love.graphics.newCanvas ( )
		-- add shape
		elseif code == "f4" then
			local ss = demomt.Shape ( "rect", nil, 0, 0, 200, 200 )
			-- layer selected, insert into it
			if selectionobj and selectionobj.type == nil then
				local z = 0
				if selectionobj.children[ 1 ] then z = selectionobj.children[ 1 ].z - 10 end
				selectionobj:insert ( ss, z )
			-- object selected, insert above
			else
				local z = selectionobj and selectionobj.z - 10 or 0
				if selectionlayer.children[ 0 ] > 1 and selectionlayer.children[ 1 ] ~= selectionobj then
					for i = 2, selectionlayer.children[ 0 ] do
						if selectionlayer.children[ i ] == selectionobj then
							z = ( selectionlayer.children[ i - 1 ].z + selectionobj.z ) / 2
							break
						end
					end
				end
				selectionlayer:insert ( ss, z )
			end
		-- cycle shape
		elseif code == "f5" then
			if selectionobj and selectionobj.type ~= nil then
				local tt = selectionobj.transform
				local ss = nil
				-- rect > circle > closed poly > open poly > rect
				if selectionobj.type == "rect" then
					ss = demomt.Shape ( "circle", selectionobj.group, 0, 0, 100 )
				elseif selectionobj.type == "circle" then
					ss = demomt.Shape ( "poly", selectionobj.group, 0, 0, defaultpoly )
				elseif selectionobj.type == "poly" then
					-- if closed, remove last point (the closing one)
					if selectionobj.poly[ 1 ] == selectionobj.poly[ selectionobj.poly[ 0 ] - 1 ] and
					selectionobj.poly[ 2 ] == selectionobj.poly[ selectionobj.poly[ 0 ] - 0 ] then
						selectionobj:setPointCount ( #defaultpoly / 2 )
					else
						ss = demomt.Shape ( "rect", selectionobj.group, 0, 0, 200, 200 )
					end
				end
				if ss then
					ss.transform = tt
					selectionlayer:remove ( selectionobj )
					selectionlayer:insert ( ss, selectionobj.z )
					selectionobj:delete ( )
				end
			end
		-- cycle group
		elseif code == "f6" then
			if selectionobj and selectionobj.type ~= nil then
				selectionobj.group = selectionobj.group + 1
				while not demomt.group[ selectionobj.group ] do
					selectionobj.group = selectionobj.group + 1
					if selectionobj.group > g then selectionobj.group = 0 end
				end
			end
		-- delete
		elseif code == "delete" then
			if selectionobj then
				if selectionlayer.children[ 1 ] ~= selectionobj then
					selectionpos = selectionpos - 1
				end
				if selectionobj.type == nil then
					layercanvas[ #layercanvas ] = nil
				end
				selectionlayer:remove ( selectionobj )
				selectionobj:delete ( )
			end
		end
		-- move up
		if code == "pageup" then
			if selectionlayer.children[ 0 ] == 1 or selectionlayer.children[ 1 ] == selectionobj then
				selectionlayer:swapDepth ( selectionobj, selectionobj.z - 10 )
			else
				local prev = nil
				for i = 1, selectionlayer.children[ 0 ] - 1 do
					if selectionlayer.children[ i + 1 ] == selectionobj then
						prev = selectionlayer.children[ i ]
						break
					end
				end
				selectionlayer:swapDepth ( selectionobj, prev )
				selectionpos = selectionpos - 1
			end
		-- move down
		elseif code == "pagedown" then
			if selectionlayer.children[ 0 ] == 1 or selectionlayer.children[ selectionlayer.children[ 0 ] ] == selectionobj then
				selectionlayer:swapDepth ( selectionobj, selectionobj.z + 10 )
			else
				local next = nil
				for i = selectionlayer.children[ 0 ], 2, -1 do
					if selectionlayer.children[ i - 1 ] == selectionobj then
						next = selectionlayer.children[ i ]
					end
				end
				selectionlayer:swapDepth ( selectionobj, next )
				selectionpos = selectionpos + 1
			end
		end
	end
	-- toggle mode by pressing backspace (except name edit mode)
	if mode ~= "name" then
		selectionflash = 0.1
		if code == "acback" or code == "backspace" then
			if mode == "test" then
				mode = "edit"
				demomt:resetInput ( )
			elseif mode == "edit" then
				mode = "transform"
			elseif mode == "transform" then
				mt:resetInput ( )
				mode = "test"
			end
		end
	else
		-- backspace removes last character
		if code == "backspace"  then
			local pos = utf.offset ( inputtext, -1 )
			if pos and pos > 0 then
				inputtext = string.sub ( inputtext, 1, pos - 1 )
			end
		-- enter confirms new name
		elseif code == "return" then
			namegroup.name = inputtext
			namegroup = nil
			love.keyboard.setTextInput ( oldinputmode )
			mode = "edit"
		-- cancel edit name by pressing escape
		elseif code == "escape" then
			demomt:removeGroup ( namegroup )
			namegroup = nil
			love.keyboard.setTextInput ( oldinputmode )
			mode = "edit"
		end
	end
end

function love.mousepressed ( x, y, button, istouch )
	if not istouch then love.touchpressed ( 0, x, y, 0, 0, 0 ) end
end
function love.mousereleased ( x, y, button, istouch )
	if not istouch then love.touchreleased ( 0, x, y, 0, 0, 0 ) end
end
function love.mousemoved ( x, y, dx, dy, istouch )
	if not istouch then love.touchmoved ( 0, x, y, dx, dy, 0 ) end
end
function love.touchpressed ( id, x, y, dx, dy, p )
	tapx = x
	tapy = y
	drag = true
	if mode == "test" then
		demomt:touchpressed ( id, x, y, dx, dy, p )
	else
		mt:touchpressed ( id, x, y, dx, dy, p )
	end
end
function love.touchreleased ( id, x, y, dx, dy, p )
	drag = false
	if mode == "test" then
		demomt:touchreleased ( id, x, y, dx, dy, p )
	else 
		mt:touchreleased ( id, x, y, dx, dy, p )
	end
end
function love.touchmoved ( id, x, y, dx, dy, p )
	tapx = x
	tapy = y
	if mode == "test" then
		demomt:touchmoved ( id, x, y, dx, dy, p )
	else
		mt:touchmoved ( id, x, y, dx, dy, p )
	end
end
function love.update ( dt )
	demomt:update ( dt )
	if mode == "transform" or mode == "edit" then
		mt:update ( dt )
	end
	
	for k, v in pairs ( animations ) do
		v[ 1 ] = v[ 1 ] - dt
		if v[ 1 ] <= 0 then animations[ k ] = nil end
	end
	
	-- cancel name input by closing keyboard
	if mode == "name" and love.keyboard.hasTextInput ( ) == false then
		demomt:removeGroup ( namegroup )
		namegroup = nil
		love.keyboard.setTextInput ( oldinputmode )
		mode = "edit"
	end
	
	if selectionpos * 15 + listoffset < 300 * gfxscale then listoffset = listoffset + dt * 200
	elseif selectionpos * 15 + listoffset + 15 > h - 300 * gfxscale then listoffset = listoffset - dt * 200 end

	selectionflash = selectionflash + dt
	if selectionflash > 0.2 then selectionflash = selectionflash - 0.4 end
	
	demomt:postupdate ( dt )
	if mode == "transform" or mode == "edit" then
		mt:postupdate ( dt )
	end
end

function love.draw ( )
	-- render layers
	xx, yy = demomt.rootlayer.transform:inverse ( tapx, tapy )
	
	love.graphics.setColor ( 255, 255, 255, 255 )
	love.graphics.clear ( 30, 30, 40 )
	
	love.graphics.setCanvas ( controlcanvas )
	love.graphics.clear ( 0, 0, 0, 0 )
	love.graphics.setCanvas ( nil )
	
	love.graphics.setCanvas ( layercanvas[ #layercanvas ] )
	layercanvas[ #layercanvas ] = nil
	love.graphics.setBlendMode ( "replace", "premultiplied" )
	love.graphics.clear ( 0, 0, 0, 0 )
	love.graphics.push ( )
	
	_transform_apply ( demomt.rootlayer.transform )
	_layer_render ( demomt.rootlayer, groupcolors )
	
	love.graphics.pop ( )
	layercanvas[ #layercanvas + 1 ] = love.graphics.getCanvas ( )
	love.graphics.setCanvas ( nil )
	love.graphics.setBlendMode ( "alpha", "alphamultiply" )
	
	love.graphics.setColor ( 255, 255, 255, 255 )
	love.graphics.draw ( layercanvas[ #layercanvas ] )
	
	selectionobj = nil
	selectionlayer = nil
	
	if mode == "test" then
		love.graphics.setFont ( smallfont )
		love.graphics.print ( "press 'back' to toggle edit mode", 10, 10 )
	elseif mode == "name" then
		love.graphics.setFont ( largefont )
		love.graphics.setColor ( 20, 20, 30, 100 )
		love.graphics.rectangle ( "fill", 100, 100, w - 200, 100 )
		love.graphics.setColor ( 255, 255, 255, 255 )
		love.graphics.printf ( inputtext, 100, 120, w - 200, "center" )
		love.graphics.printf ( "enter group name", 100, 30, w - 200, "center" )
	else
	-- print list of objects and groups
		l = 1
		love.graphics.setFont ( smallfont )
		_list_layers ( demomt.rootlayer, 1 )
		love.graphics.setColor ( 255, 255, 255, 255 )
		love.graphics.printf ( "nil", w - 300, 200 * gfxscale, 280, "right" )
		local ii = 1
		for _, grp in pairs ( demomt.group ) do
			if grp.id ~= 0 then
				love.graphics.setColor ( groupcolors[ grp.id ] )
				love.graphics.printf ( grp.name, w - 300, 200 * gfxscale + ii * 20 + 10, 280, "right" )
				ii = ii + 1
			end
		end
		
		love.graphics.setColor ( 255, 255, 255, 255 )
		love.graphics.draw ( controlcanvas )
		
		love.graphics.draw ( buttonsprites.previous, 100 * gfxscale, 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.next, 100 * gfxscale, h - 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.raise, 300 * gfxscale, 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.lower, 300 * gfxscale, h - 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		
		love.graphics.draw ( buttonsprites.newlayer, 700 * gfxscale, 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.delete, 1000 * gfxscale, 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		
		love.graphics.draw ( buttonsprites.newgroup, w - 100 * gfxscale, 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		
		love.graphics.draw ( buttonsprites.newshape, 700 * gfxscale, h - 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.cycleshape, 850 * gfxscale, h - 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
		love.graphics.draw ( buttonsprites.cyclegroup, 1000 * gfxscale, h - 100 * gfxscale, 0, gfxscale, gfxscale, 64, 64 )
	end
	if drag and drag == true then drag = false end
end

-- further code is a big fucking mess, I did not even bother with comments
-- it doesn't contains anything relevant to the example anyway, it's all just debug rendering and shit like that

function _list_layers ( layer, t )
	love.graphics.setColor ( 0, 0, 0, 100 )
	love.graphics.rectangle ( "fill", 0, listoffset + l * 15, 350, 15 )
	love.graphics.setColor ( 255, 255, 255, 255 )
	if t == 1 then 
		love.graphics.print ( "rootlayer", t * 10, listoffset + l * 15 ) 
	else
		love.graphics.print ( "layer @ " .. layer.z, t * 10, listoffset + l * 15 ) 
	end
	if not selectionobj then selectionlayer = layer end
	l = l + 1
	t = t + 1
	for i = 1, layer.children[ 0 ] do
		if selectionpos == l then
			selectionobj = layer.children[ i ]
			love.graphics.setColor ( 100, 100, 150, 255 )
			love.graphics.polygon ( "fill", 
				0,   listoffset + l*15, 
				200, listoffset + l*15+10, 
				0,   listoffset + l*15+20 
			)
		end
		if layer.children[ i ].type == nil then
			_list_layers ( layer.children[ i ], t )
			if not selectionobj then selectionlayer = layer end
		else
			love.graphics.setColor ( 0, 0, 0, 100 )
			love.graphics.rectangle ( "fill", 0, listoffset + l * 15, 350, 15 )
			local gname = demomt.group[ layer.children[ i ].group ].name
			if not gname then gname = "nil" end
			local stype 
			if layer.children[ i ].type == "poly" then 
				local p = layer.children[ i ].poly
				local l = p[ 0 ]
				if p[ 1 ] == p[ l - 1 ] and p[ 2 ] == p[ l - 0 ] then stype = "poly" else stype = "open poly" end
			elseif layer.children[ i ].type == "rect" then stype = "rect" 
			elseif layer.children[ i ].type == "circle" then stype = "circle" end
			if layer.children[ i ].group == 0 then love.graphics.setColor ( 255, 255, 255, 255 ) else love.graphics.setColor ( groupcolors[ layer.children[ i ].group ] ) end
			love.graphics.print ( stype .. " @ " .. layer.children[ i ].z .. " in '" .. gname .. "' group" , t * 10, listoffset + l * 15 )
			l = l + 1
		end
	end
end

function _transform_apply ( t )
	love.graphics.translate ( t.ox + t.x, t.oy + t.y )
	love.graphics.rotate ( t.a )
	love.graphics.shear ( t.kx, t.ky )
	love.graphics.scale ( t.sx, t.sy )
	love.graphics.translate ( -t.ox, -t.oy )
end

function drag_object ( c )
	-- undo transformation for dragging
	local sxx, syy = c.transform:forward ( xx, yy )
	local oldcanvas = love.graphics.getCanvas ( )
	love.graphics.setCanvas ( controlcanvas )
	if selectionobj == c then
		-- additional outline
		love.graphics.setColor ( 255, 255, 255, 255 )
		love.graphics.setLineWidth ( 1 )
		if c.type == "rect" then
			love.graphics.rectangle ( "line", -c.w, -c.h, c.w * 2, c.h * 2 )
		elseif c.type == "circle" then
			love.graphics.circle ( "line", 0, 0, math.sqrt ( c.r ), math.ceil ( math.sqrt ( math.sqrt ( c.r ) ) ) * 2 )
		elseif c.type == "poly" then
			for i = 4, c.poly[ 0 ], 2 do
				love.graphics.line ( c.poly[ i - 3 ], c.poly[ i - 2 ], c.poly[ i - 1 ], c.poly[ i ] )
			end
		end
		if mode == "edit" then
			love.graphics.setLineWidth ( 5 )
			love.graphics.circle ( "line", c.transform.ox, c.transform.oy, 20, 8 )
			if drag == true and (xx-c.transform.ox) ^ 2 + (yy-c.transform.oy) ^ 2 < 400 then drag = 0
			elseif drag == 0 then c.transform.x = sxx-c.transform.ox; c.transform.y = syy-c.transform.oy; c.transform:update ( ) end
			if c.type == "rect" then
				love.graphics.circle ( "line", c.w, c.h, 20, 8 )
				if drag == true and (c.w-xx)^2 + (c.h-yy)^2 < 400 then drag = 1
				elseif drag == 1 then c.w = xx; c.h = yy end
			elseif c.type == "circle" then
				love.graphics.circle ( "line", math.sqrt ( c.r ), 0, 20, 8 )
				if drag == true and (math.sqrt(c.r)-xx)^2 + yy^2 < 400 then drag = 1
				elseif drag == 1 then c.r = xx^2 + yy^2 end
			elseif c.type == "poly" then
				local l, closed = c.poly[ 0 ], false
				if c.poly[ 1 ] == c.poly[ l - 1 ] and c.poly[ 2 ] == c.poly[ l - 0 ] then l = l - 2; closed = true end
				for i = 1, l, 2 do
					love.graphics.circle ( "line", c.poly[ i ], c.poly[ i + 1 ], 20, 8 )
					if drag == true and (xx-c.poly[i])^2 + (yy-c.poly[i+1])^2 < 400 then drag = i
					elseif drag == i then c.poly[i] = xx; c.poly[i+1] = yy; end
				end
				if drag and drag ~= true and closed then c.poly[ l + 1 ] = c.poly[ 1 ]; c.poly[ l + 2 ] = c.poly[ 2 ] end
			else
				love.graphics.setLineWidth ( 2 )
				love.graphics.rectangle ( "line", -150, -150, 300, 300 )
				love.graphics.line ( -150, -200, -200, -200, -200, -150 )
				love.graphics.line ( -200, 150, -200, 200, -150, 200 )
				love.graphics.line ( 150, 200, 200, 200, 200, 150 )
				love.graphics.line ( 200, -150, 200, -200, 150, -200 )
			end
		elseif mode == "transform" then
			if c.type == nil then
				love.graphics.setLineWidth ( 2 )
				love.graphics.rectangle ( "line", -150, -150, 300, 300 )
				love.graphics.line ( -150, -200, -200, -200, -200, -150 )
				love.graphics.line ( -200, 150, -200, 200, -150, 200 )
				love.graphics.line ( 150, 200, 200, 200, 200, 150 )
				love.graphics.line ( 200, -150, 200, -200, 150, -200 )
			end
			love.graphics.setLineWidth ( 5 )
			love.graphics.arc ( "line", c.transform.ox, c.transform.oy, 150, -0.2, 0.2, 2 )
			love.graphics.rectangle ( "line", 100, 100, 20, 20 )
			love.graphics.circle ( "line", 115, -115, 15 )
			love.graphics.circle ( "line", c.transform.ox, c.transform.oy, 20, 8 )
			if drag == true then
				if (c.transform.ox-xx)^2 + (c.transform.oy-yy)^2 < 400 then drag = 0 -- pivot
				elseif (xx-150-c.transform.ox)^2 + (yy-c.transform.oy)^2 < 400 then drag = 1 -- angle
				elseif (xx-115)^2 + (yy+115)^2 < 225 then drag = 2 -- scale
				elseif (xx-110)^2 + (yy-110)^2 < 400 then drag = 3 end -- shear
			elseif drag ~= false then
				if drag == 0 then c.transform.ox = sxx-c.transform.x; c.transform.oy = syy-c.transform.y; 
				elseif drag == 1 then c.transform.a = math.atan2 ( syy-c.transform.y-c.transform.oy, sxx-c.transform.x-c.transform.ox )
				elseif drag == 2 then c.transform.sx = c.transform.sx * xx/115; c.transform.sy = c.transform.sy * -yy/115
				elseif drag == 3 then c.transform.kx = ( xx + yy * c.transform.kx ) / 110 - 1; c.transform.ky = ( yy + xx * c.transform.ky ) / 110 - 1 end
				c.transform:update ( )
			end
		end
	end
	love.graphics.setCanvas ( oldcanvas )
end

function _layer_render ( layer, colors )
	for i = layer.children[ 0 ], 1, -1 do
		local c = layer.children[ i ]
		if ( selectionobj == c or selectionobj == layer ) and selectionflash > 0 then love.graphics.setLineWidth ( 5 )
		else love.graphics.setLineWidth ( 2 ) end
		
		love.graphics.push ( )
		_transform_apply ( c.transform )
		xx, yy = c.transform:inverse ( xx, yy )
		
		if c.type == nil then
			local cc = love.graphics.getCanvas ( )
			love.graphics.setCanvas ( layercanvas[ #layercanvas ] )
			love.graphics.clear ( 0, 0, 0, 0 )
			layercanvas[ #layercanvas ] = nil
			
			_layer_render ( c, colors )
			
			layercanvas[ #layercanvas + 1 ] = love.graphics.getCanvas ( )
			love.graphics.setCanvas ( cc )
			love.graphics.push ( )
			love.graphics.origin ( )
			love.graphics.setBlendMode ( "alpha", "alphamultiply" )
			love.graphics.setColor ( 255, 255, 255, 255 )
			love.graphics.draw ( layercanvas[ #layercanvas ] )
			love.graphics.setBlendMode ( "replace", "premultiplied" )
			love.graphics.pop ( )
		else
			if not animations[ c.group ] then
				love.graphics.setColor ( colors[ c.group ] )
			else
				local r, g, b = colors[ c.group ][ 1 ], colors[ c.group ][ 2 ], colors[ c.group ][ 3 ]
				local l1 = animations[ c.group ][ 1 ] / animations[ c.group ][ 2 ]
				local l2 = 1 - l1
				r = animations[ c.group ][ 3 ][ 1 ] * l1 + r * l2
				g = animations[ c.group ][ 3 ][ 2 ] * l1 + g * l2
				b = animations[ c.group ][ 3 ][ 3 ] * l1 + b * l2
				love.graphics.setColor ( r, g, b, colors[ c.group ][ 4 ] )
			end
			if c.type == "rect" then
				love.graphics.rectangle ( "fill", -c.w, -c.h, c.w * 2, c.h * 2 )
				if mode ~= "test" then
					love.graphics.setColor ( 255, 255, 255, 255 )
					love.graphics.rectangle ( "line", -c.w, -c.h, c.w * 2, c.h * 2 )
				end
			elseif c.type == "circle" then
				love.graphics.circle ( "fill", 0, 0, math.sqrt ( c.r ), math.ceil ( math.sqrt ( math.sqrt ( c.r ) ) ) * 2 )
				if mode ~= "test" then
					love.graphics.setColor ( 255, 255, 255, 255 )
					love.graphics.circle ( "line", 0, 0, math.sqrt ( c.r ), math.ceil ( math.sqrt ( math.sqrt ( c.r ) ) ) * 2 )
				end
			elseif c.type == "poly" then
				local poly = { }
				for i = 1, c.poly[ 0 ] do poly[ i ] = c.poly[ i ] end
				-- polygon is not closed
				if c.poly[ 1 ] ~= c.poly[ c.poly[ 0 ] - 1 ] or c.poly[ 2 ] ~= c.poly[ c.poly[ 0 ] ] then
					local l = c.poly[ 0 ]
					local x1, y1, x2, y2 = c.poly[ 3 ], c.poly[ 4 ], c.poly[ 1 ], c.poly[ 2 ]
					local x3, y3, x4, y4 = c.poly[ l - 3 ], c.poly[ l - 2 ], c.poly[ l - 1 ], c.poly[ l - 0 ]
					local x12, x34, y12, y34 = x1 - x2, x3 - x4, y1 - y2, y3 - y4
					local d = x12 * y34 - y12 * x34
					if d < 0 then
						--convergent
						local a, b = x1 * y2 - y1 * x2, x3 * y4 - y3 * x4
						local x = ( a * x34 - b * x12 ) / d
						local y = ( a * y34 - b * y12 ) / d
						poly[ 1 ], poly[ l - 1 ] = x, x
						poly[ 2 ], poly[ l - 0 ] = y, y
					else
						--divergent
						local l = math.sqrt ( x12 ^ 2 + y12 ^ 2 )
						local x = x2 - x12 / l * ( w + h )
						local y = y2 - y12 / l * ( w + h )
						poly[ 1 ], poly[ 2 ] = x, y
						l = math.sqrt ( x34 ^ 2 + y34 ^ 2 )
						x = x4 - x34 / l * w
						y = y4 - y34 / l * w
						poly[ #poly - 1 ], poly[ #poly - 0 ] = x, y
					end
				end
				love.graphics.polygon ( "fill", poly )
				if mode ~= "test" then
					love.graphics.setColor ( 255, 255, 255, 255 )
					for i = 4, c.poly[ 0 ], 2 do
						love.graphics.line ( c.poly[ i - 3 ], c.poly[ i - 2 ], c.poly[ i - 1 ], c.poly[ i ] )
					end
				end
			end
		end
		drag_object ( c )
		
		love.graphics.pop ( )
		
		xx, yy = c.transform:forward ( xx, yy )
	end
end
