# MULTITOUCH INPUT HANDLING LIBRARY FOR LÖVE
### love-multitouch

## ABOUT

The 'love-multitouch' is an input handling library for LÖVE game framework. 
It functions as an extension to basic functionality rather than a replacement.
It provides all the same features and a lot more other stuff on top of that.

## FEATURES

- all basic framework touch input features
- registering double-tapping, registering held state
- force touch updates every frame, drop mid-frame touch updates (optional)
- fullscreen touch events processing
- custom screen areas touch events processing
	- groups of custom areas
		- individual touch status data, callbacks and gestures for each group
	- layers for custom areas
		- freeform geometry transform for invididual shapes and for layers
		- rectangle and circle basic area shapes, convex polygon area shape
- low to none GC footprint through recycling of objects
- FFI support

## QUICK START

```
local mt = require ( "multitouch" ) ( )

local group = mt.Group ( "foo" )
local shape = mt.Shape ( "circle", group, 100, 200, 50 )

mt.rootlayer:insert ( shape )
mt:insertGroup ( group )

group.callbacks:add ( "touchpressed", 
	function ( event, source, object ) 
		print ( event, source.name, object.x, object.y,  )
	end )

mt:hookUpdates ( )
```

## USER MANUAL
- [Multitouch](https://github.com/raidho36/love-multitouch/wiki/Multitouch)
- [Group](https://github.com/raidho36/love-multitouch/wiki/Group)
- [Shape](https://github.com/raidho36/love-multitouch/wiki/Shape)
- [Layer](https://github.com/raidho36/love-multitouch/wiki/Layer)
- [Touch](https://github.com/raidho36/love-multitouch/wiki/Touch)
- [Gesture](https://github.com/raidho36/love-multitouch/wiki/Gesture)
- [Transform](https://github.com/raidho36/love-multitouch/wiki/Transform)
- [Callbacks](https://github.com/raidho36/love-multitouch/wiki/Callbacks)
- [Usage Notes](https://github.com/raidho36/love-multitouch/wiki/Usage-Notes)
