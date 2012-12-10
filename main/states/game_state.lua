require 'LRState'
local state = LRState.new()

function makePathHolder() 
	
	local o = {}
	o.path = {}

	local onDraw = function ( index, xOff, yOff, xFlip, yFlip )
		MOAIGfxDevice.setPenColor( 1, 0, 0, 1 )
		MOAIDraw.drawLine( o.path )
	end

	o.addPoint = function ( self, x, y )
		table.insert( self.path, x )
		table.insert( self.path, y )
	end

	o.resetPath = function ( self )
		self.path = {}
	end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect( -64, -64, 64, 64 )
	scriptDeck:setDrawCallback ( onDraw )

	o.prop = MOAIProp2D.new()
	o.prop:setDeck( scriptDeck )

	return o

end


function state:onLoad()
	trace('onLoad called')
	self:initLayers()
	self.pathHolder = makePathHolder()
	self.layers[1]:insertProp( self.pathHolder.prop )
end

function state:onInput()
	local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())	
	-- print ( x, y )
	if LRInputManager.down () then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:resetPath()
		self.pathHolder:addPoint( x, y )
	elseif LRInputManager.isDown() then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:addPoint( x, y )
		self.pathHolder.prop:forceUpdate()
	end
end

function state:onUnload()
	-- self.button = nil
	self.pathHolder = nil
end

return state