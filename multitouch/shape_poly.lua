local ffiloaded, ffi = pcall ( require, "ffi" )

local Pool = require ( pathprefix .. ".pool" )
local Transform = require ( pathprefix .. ".transform" )

local pool, polypool

local ShapePoly = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
ShapePoly.__index = ShapePoly

local function bytes ( cells )
	cells = cells * ffi.sizeof ( "double" )
	return math.max ( 128, math.pow ( 2, math.ceil ( math.log ( cells ) / math.log ( 2 ) ) ) )
end

if ffiloaded then
	ffi.cdef ( "typedef struct shape_poly_t { shapetype_t type; int group; transform_t transform; double z; double * poly; } shape_poly_t;" )
	ffi.cdef ( "void * malloc ( size_t ); void * realloc ( void *, size_t ); void free ( void * );" )
	ShapePoly.__gc = function ( self ) polypool[ self.poly ] = nil; ffi.C.free ( self.poly ); end
	pool = Pool ( "shape_poly_t" )
	polypool = setmetatable ( { }, { __mode = "k" } )
else
	local _generator = function ( )
		local self = setmetatable ( { }, ShapePoly )
		self.transform = Transform ( )
		return self
	end
	pool = Pool ( _generator )
	polypool = Pool ( )
end

function ShapePoly.new ( group, x, y, poly )
	local self = pool:pop ( )
	self.transform:set ( x, y, 0, 1, 1, 0, 0, 0, 0 )
	self.type = "poly"
	self.group = group
	self.z = 0
	if ffiloaded then
		if self.poly == nil then
			self.poly = ffi.C.malloc ( bytes ( #poly + 1 + ( poly.closed and 2 or 0 ) ) )
			polypool[ self.poly ] = self.poly -- store reference in Lua code, prevent GC from collecting array
		else
			polypool[ self.poly ] = nil
			self.poly = ffi.C.realloc ( self.poly, bytes ( #poly + 1 + ( poly.closed and 2 or 0 ) ) )
			polypool[ self.poly ] = self.poly
		end
	else
		self.poly = polypool:pop ( )
	end
	-- testing shows that using length operator significantly impacts performance
	self.poly[ 0 ] = #poly
	for i = 1, #poly do
		self.poly[ i ] = poly[ i ]
	end
	if poly.closed then
		self.poly[ 0 ] = self.poly[ 0 ] + 2
		self.poly[ #poly + 1 ] = poly[ 1 ]
		self.poly[ #poly + 2 ] = poly[ 2 ]
	end
	return self
end

function ShapePoly:delete ( )
	if ffiloaded then
		-- don't do anything, meta GC function takes care of that
	else
		for i = self.poly[ 0 ], 3, -1 do
			self.poly[ i ] = nil
		end
		polypool:push ( self.poly )
	end
	pool:push ( self )
end

function ShapePoly:hitTest ( x, y )
	x, y = self.transform:inverse ( x, y )
	local p = self.poly
	for i = 1, self.poly[ 0 ] - 2, 2 do
		if ( p[ i + 2 ] - p[ i ] ) * ( y - p[ i + 1 ] ) -
			( p[ i + 3 ] - p[ i + 1 ] ) * ( x - p[ i ] ) > 0 then
			return nil
		end
	end
	return self.group
end	

function ShapePoly:setGroup ( group )
	self.group = ( type ( group ) == "table" ) and group.id or ( group or 0 )
end

function ShapePoly:setPoint ( i, x, y )
	i = ( i - 1 ) * 2
	self.poly[ i + 1 ] = x
	self.poly[ i + 2 ] = y
end

function ShapePoly:setPointCount ( n )
	n = n * 2
	if ffiloaded then
		polypool[ self.poly ] = nil
		self.poly = ffi.C.realloc ( self.poly, bytes ( n + 1 ) )
		polypool[ self.poly ] = self.poly
	else
		if n > self.poly[ 0 ] then
			for i = self.poly[ 0 ] + 1, n do self.poly[ i ] = 0 end
		else
			for i = self.poly[ 0 ], n + 1, -1 do self.poly[ i ] = nil end
		end
	end
	self.poly[ 0 ] = n
end

if ffiloaded then
	ffi.metatype ( "shape_poly_t", ShapePoly )
end

return ShapePoly

