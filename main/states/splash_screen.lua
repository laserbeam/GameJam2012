require 'LRState'
local state = LRState.new()

function state:onLoad()
	trace('onLoad called')
	self:initLayers()

	gfxQuad1 = MOAIGfxQuad2D.new ()
	gfxQuad1:setTexture ( "assets/moaiattribution_horiz_black.png" )
	gfxQuad1:setRect ( -320, -240, 320, 240 )
	gfxQuad1:setUVRect ( 0, 0, 1, 1 )
	gfxQuad2 = MOAIGfxQuad2D.new ()
	gfxQuad2:setTexture ( "assets/logo_colors.png" )
	gfxQuad2:setRect ( -240, -240, 240, 240 )
	gfxQuad2:setUVRect ( 0, 0, 1, 1 )

	prop = MOAIProp2D.new ()
	prop:setDeck( gfxQuad1 )

	self.objectLayer:insertProp( prop )
	local t = MOAIThread.new()

	t:run(
		function() 
			prop:setColor( 0, 0, 0, 0 )
			MOAIThread.blockOnAction( prop:seekColor( 1, 1, 1, 1, .5 ) )
			MOAIThread.blockOnAction( prop:moveLoc( 0, 0, 2 ) )
			MOAIThread.blockOnAction( prop:seekColor( 0, 0, 0, 0, .5 ) )
			prop:setDeck( gfxQuad2 )
			self.objectLayer:seekColor( 1, 1, 1, 1 )
			MOAIThread.blockOnAction( prop:seekColor( 1, 1, 1, 1, .5 ) )
			MOAIThread.blockOnAction( prop:moveLoc( 0, 0, 2 ) )
			MOAIThread.blockOnAction( prop:seekColor( 0, 0, 0, 0, .5 ) )
			
			self.isDone = true
		end
	)
end

function state:onUpdate( time )
	if self.isDone then
		LRStateManager.swap( "states/main_menu.lua" )
	end
end

function state:onUnload()
	self.layers = nil
end

return state