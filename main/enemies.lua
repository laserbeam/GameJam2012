local max = math.max -- simple access speed optimization
local min = math.min 
local cos = math.cos 
local sin = math.sin 

local decks = {}
decks.enemyTurret = MOAIGfxQuad2D.new ()
decks.enemyTurret:setTexture ( "assets/blue.png" )
decks.enemyTurret:setRect ( -24, -24, 24, 24 )
decks.enemyTurret:setUVRect ( 0, 0, 1, 1 )

decks.bullet = MOAIGfxQuad2D.new ()
decks.bullet:setTexture ( "assets/gray.png" )
decks.bullet:setRect ( -5, -5, 5, 5 )
decks.bullet:setUVRect ( 0, 0, 1, 1 )

decks.seeker = MOAIGfxQuad2D.new ()
decks.seeker:setTexture ( "assets/red.png" )
decks.seeker:setRect ( -12, -12, 12, 12 )
decks.seeker:setUVRect ( 0, 0, 1, 1 )

decks.spawner = MOAIGfxQuad2D.new ()
decks.spawner:setTexture ( "assets/orange.png" )
decks.spawner:setRect ( -24, -24, 24, 24 )
decks.spawner:setUVRect ( 0, 0, 1, 1 )


local templates = {}

-- overloads die so that it gives score and gold
function makeBaseEnemy( health, scoreValue, goldValue )
	enemy = makeUnit( health )
	enemy.scoreValue = scoreValue
	enemy.goldValue = goldValue

	function enemy:die()
		PLAYER.score = PLAYER.score + self.scoreValue
		PLAYER.gold = PLAYER.gold + self.goldValue
		self.isDead = true
	end
	return enemy
end

function makeEnemyTurret( health, scoreValue, goldValue, damage, cooldown, range )
	turret = makeBaseEnemy( health or 20, scoreValue or 50, goldValue or 10 )
	
	turret.prop:setDeck( decks.enemyTurret )
	-- turret.prop:setScl( 0.4 )
	turret.damage = damage or 2
	turret.maxCooldown = cooldown or 1
	turret.cooldown = 0
	turret.range = range or 150

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown
	
	function turret:update( gameState, time )
		self:updateCooldown( time )
		if gameState.theSnake then
			self.target = pickTargetInRangeFromTable( self, gameState.theSnake.mountedTurrets, self.range )
		end
		if self.target then
			rotateToTarget( self, self.target )
			if self.cooldown <= 0 then
				fire( gameState, self, self.target, decks.bullet )
			end
		end
	end

	return turret
end

function makeSmallSeeker( health, scoreValue, goldValue, damage, cooldown, range, speed )
	seeker = makeBaseEnemy( health or 8, scoreValue or 10, goldValue or 1 )
	seeker.prop:setDeck( decks.seeker )

	seeker.damage = damage or .3
	seeker.maxCooldown = cooldown or .3
	seeker.cooldown = 0
	seeker.range = range or 50
	seeker.speed = speed or 70

	seeker.updateCooldown = updateCooldown
	seeker.resetCooldown = resetCooldown

	function seeker:update( gameState, time )
		self:updateCooldown( time )
		if gameState.theSnake then
			self.target = pickTargetInRangeFromTable( self, gameState.theSnake.mountedTurrets )
		end
		if self.target then
			local angle = rotateToTarget( self, self.target )
			if distanceSq( self.prop, self.target.prop ) <= self.range * self.range then
				if self.cooldown <= 0 then
					fire( gameState, self, self.target, decks.bullet )
				end
			else
				local dx, dy = self.speed*time*cos(angle), self.speed*time*sin(angle)
				self.prop:moveLoc( dx, dy )
			end
		end			
	end

	return seeker
end

function makeUnitSpawner( health, scoreValue, goldValue, spawnedUnit, cooldown )
	spawner = makeBaseEnemy( health or 30, scoreValue or 100, goldValue or 15 )
	spawner.prop:setDeck( decks.spawner )

	spawner.maxCooldown = cooldown or 5
	spawner.cooldown = spawner.maxCooldown
	spawner.spawnedUnit = spawnedUnit or "seeker"

	spawner.updateCooldown = updateCooldown
	spawner.resetCooldown = resetCooldown
	
	function spawner:update( gameState, time )
		if not gameState.gameStarted then return end
		self:updateCooldown( time )
		if self.cooldown <= 0 then
			print ("SPAWN")
			e = makeTemplateEnemy( spawnedUnit )
			gameState:insertEnemy( e, self.prop:getLoc() )
			self:resetCooldown()
		end
	end

	return spawner

end

function makeTemplateEnemy( name )
	-- s stands for stats...
	local s = templates[name]
	if not s then return nil end
	local unit = nil
	if name == 'turret' then
		unit = makeEnemyTurret( s.health, s.scoreValue, s.goldValue, s.damage, s.cooldown, s.range )
	elseif name == 'seeker' then
		unit = makeSmallSeeker( s.health, s.scoreValue, s.goldValue, s.damage, s.cooldown, s.range, s.speed )
	elseif name == 'spawner' then
		unit = makeUnitSpawner( s.health, s.scoreValue, s.goldValue, s.spawnedUnit, s.cooldown )
	end
	return unit
end

local function loadTemplates()
	templates = loadJSONFile( 'assets/enemies.json' )
end	

loadTemplates()