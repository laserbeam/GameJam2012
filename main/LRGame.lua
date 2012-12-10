--=========================================================================
-- LRGame
-- This module makes sure all modules from LREngine are loaded and provides
-- LRGame:init(name) which returns a viewport 
--=========================================================================
require 'LRLogger' -- Also initialize
-- require 'LRResourceManager'
require 'LRInputManager' -- Also initialize
require 'LRStateManager' -- Also initialize
require 'util'

math.randomseed ( os.time() )
-- don't ask... just leave it here. I AM INSANE! (and lua does some
-- weird shit with the first few random numbers which end up being
-- not quite random enough to be usable)
math.random()
math.random()
math.random()

LR_DEBUG = true

LRGame = {}

--=========================================================================
-- Creates and initializes the game.
-- Creates a 800/480 window (my phone's screen), or takes the phone's screen
--=========================================================================
function LRGame.init( name )
	name = name or 'WORK IN PROGRESS'
	local w, h = 800, 600
	local r = 800/600
	if MOAIEnvironment.screenHeight and MOAIEnvironment.screenWidth then
		w = MOAIEnvironment.screenWidth
		h = MOAIEnvironment.screenHeight
		print ( 'SCREEN', w, h )
		r = w/h
	end

	MOAISim.openWindow ( name, w, h )
	MOAISim.setStep( 1/30 ) -- Run simulation at 30 hz

	MAIN_VIEWPORT = MOAIViewport.new ()
	MAIN_VIEWPORT:setSize ( w, h )
	MAIN_VIEWPORT:setScale ( r*600, -600 )

end

return LRGame