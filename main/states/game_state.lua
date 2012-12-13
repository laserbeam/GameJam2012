require 'LRState'
require 'components'
require 'player'
require 'enemies'
require 'snake'

local sin = math.sin 
local cos = math.cos 
local abs = math.abs 

local state = LRState.new()

-- Distinctive states a game can be:
-- Idle == no simulations, the player can start drawing
-- Drawing == the player is drawing the path
-- Running == simulations are taking place and the snake is walking
STATUS_IDLE = 1
STATUS_DRAWING = 2
STATUS_RUNNING = 3

-- Arena coordinates
minX = -400+45
maxX = 400-45
minY = -240+45
maxY = 240-45

local function makePathHolder() 
	
	local startX = minX
	local startY = maxY-30
	local prestartX = startX -60
	local prestartY = startY

	local pathHolder = {}
	function pathHolder:resetPath()
		self.pathXY = {}
		self.lengths = {0}
		self.totalLength = 0
	end

	pathHolder:resetPath()

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
				self.totalLength = d + aux
			end
		else
			table.insert( self.pathXY, x )
			table.insert( self.pathXY, y )
		end
	end

	-- Rebuilds the path to have a beginning and an end behind the wall
	function pathHolder:finalizePath()
		local p = self.pathXY
		self:resetPath()
		self:addPoint( prestartX, prestartY )
		self:addPoint( startX, startY )
		for i=1,#p,2 do
			self:addPoint( p[i], p[i+1] )
		end
		self:addPoint( startX+10, startY )
		self:addPoint( prestartX, prestartY )
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
	-- pathHolder.prop:setVisible( false )

	return pathHolder

end

--- Populates the state with enemies based on some level file
--- but right now it just adds a couple turrets
local function loadLevel( state, levelName )
	state.status = STATUS_IDLE

	local level = loadJSONFile( 'levels/' .. (levelName or 'level1.json') )
	state:clearEnemies()
	for _, template in pairs(level.enemies) do
		local e = makeTemplateEnemy( template.t )
		state:insertEnemy( e, template.x, template.y )
	end
end

function state:insertEnemy( enemy, x, y )
	self.enemies[enemy] = enemy
	self.objectLayer:insertProp( enemy.prop )
	enemy.prop:setPriority(100)
	enemy.prop:setLoc( x, y )
end

function state:clearEnemies()
	if self.enemies then
		for _, enemy in pairs(self.enemies) do
			self.objectLayer:removeProp( enemy.prop )
		end
	end
	self.enemies = {}
end

function state:removeEnemy( enemy )
	self.enemies[enemy] = nil
	self.objectLayer:removeProp( enemy.prop )
end

function state:onLoad()
	trace('onLoad called')
	self.status = STATUS_IDLE
	self:initLayers( 3 )
	self.pathHolder = makePathHolder()
	self.objectLayer:insertProp( self.pathHolder.prop )

	gfxQuad = MOAIGfxQuad2D.new ()
	gfxQuad:setTexture ( "assets/BACKGROUND.png" )
	gfxQuad:setRect ( -400, -240, 400, 240 )
	gfxQuad:setUVRect ( 0, 0, 1, 1 )

	bg = MOAIProp2D.new ()
	bg:setDeck( gfxQuad )
	self.bgLayer:insertProp( bg )

	loadLevel( self, 'level1.json' )

	if not PLAYER.snakeConfig then
		PLAYER.snakeConfig = makeSnakeConfig()
		PLAYER.snakeConfig:setMountLength( 3 )
		PLAYER.snakeConfig:setMountTemplate( 1, 'turret' )
		PLAYER.snakeConfig:setMountTemplate( 2, 'healer' )
		PLAYER.snakeConfig:setMountTemplate( 3, 'turret' )
	end
end

local function inStartArea( x, y )
	return x < minX+60 and y > maxY-60
end

function state:onInput()
	if LRInputManager.down() and self.status == STATUS_IDLE then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		x = clamp( x, minX, maxX )
		y = clamp( y, minY, maxY )
		
		if inStartArea( x, y ) then
			self.pathHolder:resetPath()
			self.pathHolder:addPoint( x, y )
			self.status = STATUS_DRAWING
		end
	elseif LRInputManager.isDown() and self.status == STATUS_DRAWING then
		local x, y = self.objectLayer:wndToWorld ( LRInputManager.getTouch ())
		x = clamp( x, minX, maxX )
		y = clamp( y, minY, maxY )
		self.pathHolder:addPoint( x, y )
		self.pathHolder.prop:forceUpdate()
	elseif LRInputManager.up() and self.status == STATUS_DRAWING then
		if self.pathHolder.totalLength > 300 then
			self.pathHolder:finalizePath()
			if self.theSnake then
				self.theSnake.tDist = 0
			else
				self.theSnake = makeRunningSnake( self, PLAYER.snakeConfig )
			end
			self.status = STATUS_RUNNING
		else
			self.pathHolder:resetPath()
			self.status = STATUS_IDLE
		end
	end

	local k = LRInputManager.getKey()
	if k == KEY['a'] then
		LRStateManager.setSpeedScale( 1.5 )
	elseif k == KEY['s'] then
		LRStateManager.setSpeedScale( 2 )
	elseif k == KEY['d'] then
		LRStateManager.setSpeedScale( 0.5 )
	elseif k == KEY['f'] then
		LRStateManager.setSpeedScale( 1 )
	end
end

local function updateMovingSnake( gameState, time )
	if gameState.theSnake then
		local dist = gameState.theSnake.tDist
		for i,v in ipairs(gameState.theSnake.joints) do
			local x1, y1 = gameState.pathHolder:getXYAngleAtDistance( dist - gameState.theSnake.jointSpacing/2)
			local x2, y2 = gameState.pathHolder:getXYAngleAtDistance( dist + gameState.theSnake.jointSpacing/2)
			local x, y = midPoint( x1, y1, x2, y2 )
			-- local x, y, angle = gameState.pathHolder:getXYAngleAtDistance(dist)
			angle = angleFromXY( x1, y1, x2, y2 )
			v.prop:setLoc( x, y )
			v.prop:setRot( degree(angle)+90 )
			if gameState.theSnake.mountedTurrets[i] then
				local t = gameState.theSnake.mountedTurrets[i]
				t.prop:setLoc( x, y )
				if t.target then
					angle = angleFromXY( x, y, t.target.prop:getLoc() )
				end
				t.prop:setRot( degree(angle)+90 )
			end
			dist = dist - gameState.theSnake.jointSpacing
		end
		gameState.theSnake.tDist = gameState.theSnake.tDist + gameState.theSnake.speed*time
		if gameState.theSnake.tDist > gameState.pathHolder.totalLength + gameState.theSnake.totalLength then
			gameState.status = STATUS_IDLE
		end
	end
end


local function updateSnakeTurrets( gameState, time )
	for i, turret in pairs( gameState.theSnake.mountedTurrets ) do
		if turret.isDead then
			print (turret, "died... awwwwwwww, not cool")
			gameState.theSnake.mountedTurrets[i] = nil
			gameState.objectLayer:removeProp( turret.prop )
		else
			turret:update( gameState, time )
		end
	end
end

local function updateEnemies( gameState, time )
	for _, e in pairs( gameState.enemies ) do
		if e.isDead then
			print (e, "died... how sad")
			gameState:removeEnemy(e)
		else
			e:update( gameState, time )
		end
	end
end

function state:onUpdate( time )
	if self.status == STATUS_RUNNING then
			updateMovingSnake( self, time )
		if self.theSnake then
			updateSnakeTurrets( self, time )
		end
		updateEnemies( self, time )
	end
end

function state:onUnload()
	-- self.button = nil
	self.pathHolder = nil
end

return state