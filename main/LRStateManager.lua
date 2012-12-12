LRStateManager = {}

--=========================================================================
-- Simple singleton to handle the state stack
-- methods all states should have and be called by the state manager:
-- onFocus 		- called whenever the state is moved to the top of the stack
-- onLoseFocus 	- called whenever the state is moved from the top of the stack
-- onInput 		- called when the state is at the top of the stack and input occurs
-- onLoad		- called when the state is added to the stack - receives arguments to initialise the state
-- onUnload		- called when the state is removed from the stack
-- onUpdate		- called every frame while the state is on the top of the stack
-- The state manager does not asume these functions exist
--
-- The state manager only asumes states have a scene which can provide a sorted list of layers
--
-- Other state members that appear here such as IS_FORCED_RENDER are handled
-- by the state manager and DO NOT have to be included in the state 
--=========================================================================

local currentState = nil	-- the state on the top of the stack
local stateStack = {}		-- the state stack
local loadedStates = {}		-- this module loads states in a lazy way, if a lua state file was
							-- loaded keep the state here, otherwise it will load it with dofile

local delta
local updateThread = MOAIThread.new ()
FRAME_TIME = 0
local speedScale = 1

--=========================================================================
-- Local functions.
--=========================================================================
local function updateFunction ()
	local lastTime = MOAISim.getElapsedTime()
	delta = 0
	local now = 0
	while true do
		coroutine.yield ()
		now = MOAISim.getElapsedTime()
		delta = now - lastTime
		delta = delta*speedScale
		FRAME_TIME = delta
		lastTime = now

		if currentState then
			if type ( currentState.onInput ) == 'function' then
				currentState:onInput ()
			end
			
			if type ( currentState.onUpdate ) == 'function' then
				currentState:onUpdate ( delta )
			end
		else
			print ( 'WARNING - There is no current state. Call state.push/state.swap to add a state.' )
			MOAISim.crash ()
		end

	end
end

function LRStateManager.getTime()
	return delta
end

local currentLayers = {}	-- used to pass MOAIRenderables (Layers) to MOAIRenderMgr
---------------------------------------------------------------------------
local function addStateLayers( state )
	for i, layer in ipairs ( state:getLayers() ) do
		table.insert ( currentLayers, layer )
	end
end

---------------------------------------------------------------------------
local function rebuildRenderStack ()
	MOAIRenderMgr.clearRenderStack ()
	MOAISim.forceGarbageCollection ()
	currentLayers = {}	

	for i, state in ipairs ( stateStack ) do
		if i == #stateStack or state.IS_FORCED_RENDER then
			addStateLayers ( state )
		end
	end

	MOAIRenderMgr.setRenderTable ( currentLayers )
end

---------------------------------------------------------------------------
function loadState( stateFile )
	if not loadedStates [ stateFile ] then
		local newState = dofile ( stateFile )
		loadedStates [ stateFile ] = newState
		loadedStates [ stateFile ].stateFilename = stateFile
	end

	return loadedStates [ stateFile ]
end

--=========================================================================
-- Public functions.
--=========================================================================

function LRStateManager.setSpeedScale( scale )
	speedScale = scale or 1
end

function LRStateManager.run ()
	updateThread:run ( updateFunction )
end

---------------------------------------------------------------------------
function LRStateManager.stop ()
	updateThread:stop ()
end

---------------------------------------------------------------------------
function LRStateManager.getCurrentState ()
	return currentState
end

---------------------------------------------------------------------------
function LRStateManager.push ( stateFile, ... )
	
	-- do the old current state's onLoseFocus
	if currentState then 
		
		if type ( currentState.onLoseFocus ) == 'function' then
			currentState:onLoseFocus ( )
		end
	end
	
	-- update the current state to the new one
	local newState = loadState ( stateFile )
	table.insert ( stateStack, newState )	
	currentState = newState
	
	-- do the state's onLoad
	if type ( currentState.onLoad ) == 'function' then		
		currentState:onLoad ( ... )
	end
	
	-- do the state's onFocus
	if type ( currentState.onFocus ) == 'function' then	
		currentState:onFocus ()
	end
		
	if currentState.IS_POPUP then
		addStateLayers ( currentState, #stateStack )
	else	
		rebuildRenderStack ()
	end
end

---------------------------------------------------------------------------
function LRStateManager.pop ()
	
	-- do the state's onLoseFocus
	if type ( currentState.onLoseFocus ) == 'function' then
		currentState:onLoseFocus ()
	end
	
	-- do the state's onUnload
	if type ( currentState.onUnload ) == 'function' then
		currentState:onUnload ()
	end

	table.remove ( stateStack )
	currentState = stateStack [ #stateStack ]

	rebuildRenderStack ()
	MOAISim.forceGarbageCollection ()


	-- do the state's onFocus

	if currentState and type ( currentState.onFocus ) == 'function' then
		currentState:onFocus ()
	end

end

---------------------------------------------------------------------------
function LRStateManager.swap( stateFile, ... )
	LRStateManager.pop ()
	LRStateManager.push ( stateFile, ... )
end

---------------------------------------------------------------------------
function LRStateManager.setPupupMode( state, bool )
	state.IS_POPUP = bool
end

---------------------------------------------------------------------------
function LRStateManager.setForcedRenderMode( state, bool )
	state.IS_FORCED_RENDER = bool
end

---------------------------------------------------------------------------
return LRStateManager
