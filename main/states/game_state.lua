require 'LRState'
require 'components'
require 'player'
require 'enemies'
require 'snake'

local sin = math.sin 
local cos = math.cos 
local abs = math.abs 

local state = LRState.new()

local function makePathHolder() 
	
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
			if d>4 then
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
		-- This is called when the path is finished, the path should be smoothed here!
		print (table.getn(self.pathXY), table.getn(self.lengths))
	end

	function pathHolder:getXYAngleAtDistance( distance )
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
		local angle = angleFromXY( x, y )
		x, y = x*alpha, y*alpha
		return xa+x, ya+y, angle
	end

	scriptDeck = MOAIScriptDeck.new()
	scriptDeck:setRect( -64, -64, 64, 64 )
	scriptDeck:setDrawCallback( onDraw )

	pathHolder.prop = MOAIProp2D.new()
	pathHolder.prop:setDeck( scriptDeck )

	return pathHolder

end

isDrawing = false

--- Populates the state with enemies based on some level file
--- but right now it just adds a couple turrets
local function loadLevel( state, levelName )
	state.enemies = {}
	e = makeEnemyTurret( 20, 7, 3 )
	e.prop:setLoc( -200, -200 )
	state.objectLayer:insertProp( e.prop )
	state.enemies[e] = e

	e = makeEnemyTurret( 20, 7, 3 )
	e.prop:setLoc( 100, 100 )
	state.objectLayer:insertProp( e.prop )
	state.enemies[e] = e
end

function state:onLoad()
	trace('onLoad called')
	self:initLayers( 3 )
	self.pathHolder = makePathHolder()
	self.objectLayer:insertProp( self.pathHolder.prop )

	gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture ( "assets/moai.png" )
	gfxQuad:setRect ( -128, -128, 128, 128 )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	loadLevel( self, '1.json' )
end

function state:onInput()
	local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())	
	-- print ( x, y )
	if LRInputManager.down () then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:resetPath()
		self.pathHolder:addPoint( x, y )

		isDrawing = true
	elseif LRInputManager.isDown() then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		self.pathHolder:addPoint( x, y )
		self.pathHolder.prop:forceUpdate()
	elseif LRInputManager.up() then
		self.pathHolder:finalizePath()
		print (self.theSnake)
		makeRunningSnake( self, 10 )
		print (self.theSnake)
		isDrawing = false
	end
end

local function updateMovingSnake( gameScene, time )
	if (not isDrawing) and gameScene.theSnake then
		local dist = gameScene.theSnake.tDist
		for i,v in ipairs(gameScene.theSnake.joints) do
			local x, y, angle = gameScene.pathHolder:getXYAngleAtDistance(dist)
			angle = angle or 0
			v.prop:setLoc( x, y )
			v.prop:setRot( degree(angle)+90 )
			if gameScene.theSnake.mountedTurrets[i] then
				local t = gameScene.theSnake.mountedTurrets[i]
				t.prop:setLoc( x, y )
				if t.target then
					angle = angleFromXY( x, y, t.target.prop:getLoc() )
				end
				t.prop:setRot( degree(angle)+90 )
			end
			dist = dist - gameScene.theSnake.jointSpacing
		end
		gameScene.theSnake.tDist = gameScene.theSnake.tDist + gameScene.theSnake.speed*time
	end
end


local function updateSnakeTurrets( gameScene, time )
	for i, turret in pairs( gameScene.theSnake.mountedTurrets ) do
		if turret.isDead then
			gameScene.theSnake.mountedTurrets[i] = nil
			gameScene.objectLayer:removeProp( turret.prop )
		else
			if turret.target then
				if turret.target.isDead or distanceSq( turret.prop, turret.target.prop ) > turret.range * turret.range then
					turret.target = nil
				end
			end
			if not turret.target and gameScene.enemies then
				turret.target = pickTargetInRangeFromTable( turret, gameScene.enemies, turret.range )
			end

			-- If the turent has cooldown on its weapon, update it
			if turret.updateCooldown then turret:updateCooldown( time ) end
			if turret.cooldown <= 0 and turret.target then
				fire( gameScene, turret, turret.target, turret.bulletDeck )
			end
		end
	end
end

local function updateEnemies( gameScene, time )
	for _, e in pairs( gameScene.enemies ) do
		if e.isDead then
			print (e, " died... how sad")
			gameScene.objectLayer:removeProp( e.prop )
			gameScene.enemies[e] = nil
		else
			e:update( gameScene, time )
		end
	end
end

function state:onUpdate( time )
	updateMovingSnake( self, time )
	if self.theSnake then
		updateSnakeTurrets( self, time )
	end
	updateEnemies( self, time )
end

function state:onUnload()
	-- self.button = nil
	self.pathHolder = nil
end

return state