require 'LRState'
local state = LRState.new()

function makePathHolder() 
	
	local pathHolder = {}
	pathHolder.pathXY = {}
	pathHolder.lengths = {}

	local onDraw = function ( index, xOff, yOff, xFlip, yFlip )
		MOAIGfxDevice.setPenColor( 1, 0, 0, 1 )
		MOAIDraw.drawLine( pathHolder.pathXY )
	end

	function pathHolder:addPoint( x, y )
		local len = table.getn( self.pathXY )
		if len > 1 then
			local oldx, oldy = self.pathXY[len-1], self.pathXY[len]
			local d = distanceXY( oldx, oldy, x, y )
			if d>6 then
				local aux = self.lengths[ table.getn(self.lengths) ]
				table.insert( self.lengths, d + aux )
				table.insert( self.pathXY, x )
				table.insert( self.pathXY, y )
			end
		else
			table.insert( self.pathXY, x )
			table.insert( self.pathXY, y )
		end
	end

	function pathHolder:resetPath()
		self.pathXY = {}
		self.lengths = {0}
	end

	function pathHolder:finalizePath()
		print (table.getn(self.pathXY), table.getn(self.lengths))
	end

	function pathHolder:getXYAngleatDistance( distance )
		if distance < 0 then distance = 0 end
		local i, d = binSearch( self.lengths, distance )
		if i == table.getn(self.lengths) then
			return self.pathXY[2*i-1], self.pathXY[2*i]
		end
		local xa, ya = self.pathXY[2*i-1], self.pathXY[2*i]
		local xb, yb = self.pathXY[2*i+1], self.pathXY[2*i+2]
		distance = distance - d
		local total = self.lengths[i+1] - d
		local alpha = distance/total
		local x, y = xb-xa, yb-ya
		x, y = x*alpha, y*alpha
		return xa+x, ya+y
	end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect( -64, -64, 64, 64 )
	scriptDeck:setDrawCallback( onDraw )

	pathHolder.prop = MOAIProp2D.new()
	pathHolder.prop:setDeck( scriptDeck )

	return pathHolder

end


moving = {}
tDist = 0
speed = 0
isDrawing = false

function state:onLoad()
	trace('onLoad called')
	self:initLayers()
	self.pathHolder = makePathHolder()
	self.layers[1]:insertProp( self.pathHolder.prop )

	gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture ( "assets/moai.png" )
	gfxQuad:setRect ( -128, -128, 128, 128 )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	moving = MOAIProp2D.new ()
	moving:setDeck( gfxQuad )
	moving:setScl( 0.1 )
	self.layers[1]:insertProp( moving )
	tDist = 0
	speed = 0
end

function state:onInput()
	local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())	
	-- print ( x, y )
	if LRInputManager.down () then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:resetPath()
		self.pathHolder:addPoint( x, y )

		isDrawing = true
		moving:setLoc(999, 999)
		tDist = 0
		speed = 0
	elseif LRInputManager.isDown() then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:addPoint( x, y )
		self.pathHolder.prop:forceUpdate()
	elseif LRInputManager.up() then
		self.pathHolder:finalizePath()
		tDist = 0
		speed = 2
		isDrawing = false
	end
end

function state:onUpdate( time )
	if not isDrawing then
		local x, y, angle = self.pathHolder:getXYAngleatDistance(tDist)
		moving:setLoc( x, y )
		tDist = tDist + speed
	end
end

function state:onUnload()
	-- self.button = nil
	self.pathHolder = nil
end

return state