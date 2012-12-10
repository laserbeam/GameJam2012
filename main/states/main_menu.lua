require 'LRState'
local state = LRState.new()

function state:onLoad()
	trace('onLoad called')
	self:initLayers()

	-- gfxQuad = MOAIGfxQuad2D.new ()
	-- gfxQuad:setTexture ( "assets/moai.png" )
	-- gfxQuad:setRect ( -128, -128, 128, 128 )
	-- gfxQuad:setUVRect ( 0, 0, 1, 1 )

	self.button = makeButton( "assets/moai.png", 256, 256 )
	self.button:setCallback( function ( self ) 

		LRStateManager.push("states/game_state.lua")

	end )
	self.layers[1]:insertProp ( self.button.prop )

end

function state:onInput()
	if LRInputManager.up () then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		
		self.button:updateClick ( false, x, y )
		
	elseif LRInputManager.down () then
		local x, y = self.layers[1]:wndToWorld ( LRInputManager.getTouch ())
		
		self.button:updateClick ( true, x, y )
	end
end

function state:onUnload()
	self.button = nil
end

return state