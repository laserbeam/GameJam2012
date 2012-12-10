LRInputManager = {}

--=========================================================================
-- Input constants
--=========================================================================
KEY = {
	[ "esc" ] = 27,
	[ "tab" ] = 9,
	[ " " ] = 32,
	[ "0" ] = 48,
	[ "1" ] = 49,
	[ "2" ] = 50,
	[ "3" ] = 51,
	[ "4" ] = 52,
	[ "5" ] = 53,
	[ "6" ] = 54,
	[ "7" ] = 55,
	[ "8" ] = 56,
	[ "9" ] = 57,
	[ "A" ] = 65,
	[ "B" ] = 66,
	[ "C" ] = 67,
	[ "D" ] = 68,
	[ "E" ] = 69,
	[ "F" ] = 70,
	[ "G" ] = 71,
	[ "H" ] = 72,
	[ "I" ] = 73,
	[ "J" ] = 74,
	[ "K" ] = 75,
	[ "L" ] = 76,
	[ "M" ] = 77,
	[ "N" ] = 78,
	[ "O" ] = 79,
	[ "P" ] = 80,
	[ "Q" ] = 81,
	[ "R" ] = 82,
	[ "S" ] = 83,
	[ "T" ] = 84,
	[ "U" ] = 85,
	[ "V" ] = 86,
	[ "W" ] = 87,
	[ "X" ] = 88,
	[ "Y" ] = 89,
	[ "Z" ] = 90,
	[ "a" ] = 97,
	[ "b" ] = 98,
	[ "c" ] = 99,
	[ "d" ] = 100,
	[ "e" ] = 101,
	[ "f" ] = 102,
	[ "g" ] = 103,
	[ "h" ] = 104,
	[ "i" ] = 105,
	[ "j" ] = 106,
	[ "k" ] = 107,
	[ "l" ] = 108,
	[ "m" ] = 109,
	[ "n" ] = 110,
	[ "o" ] = 111,
	[ "p" ] = 112,
	[ "q" ] = 113,
	[ "r" ] = 114,
	[ "s" ] = 115,
	[ "t" ] = 116,
	[ "u" ] = 117,
	[ "v" ] = 118,
	[ "w" ] = 119,
	[ "x" ] = 120,
	[ "y" ] = 121,
	[ "z" ] = 122
}


MOUSE_LEFT = 1
MOUSE_RIGHT = 2
MOUSE_MIDDLE = 3

---------------------------------------------------------------------------
local pointerX, pointerY = nil, nil

---------------------------------------------------------------------------
if MOAIInputMgr.device.pointer then

	local function pointerCallback ( x, y )
		
		pointerX, pointerY = x, y
		
		if touchCallbackFunc then
			touchCallbackFunc ( MOAITouchSensor.TOUCH_MOVE, 1, pointerX, pointerY, 1 )
		end
	end

	MOAIInputMgr.device.pointer:setCallback ( pointerCallback )
end

---------------------------------------------------------------------------
local keys = {}
local keysNext, keysLast = 0, 0
if MOAIInputMgr.device.keyboard then
	
	local function keyCallback ( key, down )
		if down then
			table.insert( keys, key )
			log( LRLogger.VERBOSE, 'LRInputManager. Key pressed: '..key)
		end
	end
	
	MOAIInputMgr.device.keyboard:setCallback ( keyCallback )
end


--=========================================================================
-- Public interface.
--=========================================================================

---------------------------------------------------------------------------
-- Returns the last pressed key
function LRInputManager.getKey ()
	return table.remove(keys, 1) or nil
end

---------------------------------------------------------------------------
-- Checks if a key is pressed down
function LRInputManager.keyIsDown( key )
	return MOAIInputMgr.device.keyboard:keyIsDown( key )
end

---------------------------------------------------------------------------
-- Checks if a key is up
function LRInputManager.keyIsUp( key )
	return MOAIInputMgr.device.keyboard:keyIsUp( key )
end

---------------------------------------------------------------------------
-- Checks if a button or touch id was pressed during the last MOAI iteration.
-- id can be ignored for touch and for mouse it defaults to left click
function LRInputManager.down ( id )
	if MOAIInputMgr.device.touch then
		return MOAIInputMgr.device.touch:down ( id )
	elseif MOAIInputMgr.device.pointer then
		if not id or id == MOUSE_LEFT then
			return MOAIInputMgr.device.mouseLeft:down ()
		elseif id == MOUSE_RIGHT then
			return MOAIInputMgr.device.mouseRight:down ()
		elseif id == MOUSE_MIDDLE then
			return MOAIInputMgr.device.mouseMiddle:down ()
		end
	end
end

---------------------------------------------------------------------------
-- Checks if a button or touch id was released during the last MOAI iteration.
-- id can be ignored for touch and for mouse it defaults to left click
function LRInputManager.up ( id )
	if MOAIInputMgr.device.touch then
		return MOAIInputMgr.device.touch:up ( id )
	elseif MOAIInputMgr.device.pointer then
		if not id or id == MOUSE_LEFT then
			return MOAIInputMgr.device.mouseLeft:up ()
		elseif id == MOUSE_RIGHT then
			return MOAIInputMgr.device.mouseRight:up ()
		elseif id == MOUSE_MIDDLE then
			return MOAIInputMgr.device.mouseMiddle:up ()
		end
	end
end

---------------------------------------------------------------------------
-- Return where the current touch id is on the screen (or where the mouse is)
function LRInputManager.getTouch ( id )
	if MOAIInputMgr.device.touch then
		return MOAIInputMgr.device.touch:getTouch ( id )
	elseif MOAIInputMgr.device.pointer then
		return pointerX, pointerY, 1
	end
end

---------------------------------------------------------------------------
-- Returns true if any touch is occuring or if the ID mouse button is down
function LRInputManager.isDown ( id )
	if MOAIInputMgr.device.touch then
		return MOAIInputMgr.device.touch:isDown ()
	elseif MOAIInputMgr.device.pointer then
		if id == nil or id == MOUSE_LEFT then
			return MOAIInputMgr.device.mouseLeft:isDown ()
		elseif id == MOUSE_RIGHT then
			return MOAIInputMgr.device.mouseRight:isDown ()
		elseif id == MOUSE_MIDDLE then
			return MOAIInputMgr.device.mouseMiddle:isDown ()
		end
	end
end

---------------------------------------------------------------------------
function LRInputManager.isUp ( id )
	return not LRInputManager.isDown (id)
end

---------------------------------------------------------------------------

return LRInputManager