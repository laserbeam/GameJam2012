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


-- overloads die so that it gives score and gold
function makeEnemy( health, scoreValue, goldValue )
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

function makeEnemyTurret( health, damage, cooldown, range )
	turret = makeEnemy( health, 50, 10 )
	
	turret.prop:setDeck( decks.enemyTurret )
	-- turret.prop:setScl( 0.4 )
	turret.damage = damage or 2
	turret.maxCooldown = cooldown or 1
	turret.cooldown = 0
	turret.range = 150

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown
	
	function turret:update( scene, time )
		self:updateCooldown( time )
		if scene.theSnake then
			self.target = pickTargetInRangeFromTable( self, scene.theSnake.mountedTurrets, self.range )
		end
		if self.target then
			rotateToTarget( self, self.target )
			if self.cooldown <= 0 then
				fire( scene, self, self.target, decks.bullet )
			end
		end
	end

	return turret
end

function makeSmallSeeker( health, damage, cooldown, range )
	seeker = makeEnemy( health, 10, 1 )
	seeker.prop:setDeck( decks.seeker )

	seeker.damage = damage or .3
	seeker.maxCooldown = cooldown or .3
	seeker.cooldown = 0
	seeker.range = 50
	seeker.speed = 70

	seeker.updateCooldown = updateCooldown
	seeker.resetCooldown = resetCooldown

	function seeker:update( scene, time )
		self:updateCooldown( time )
		if scene.theSnake then
			self.target = pickTargetInRangeFromTable( self, scene.theSnake.mountedTurrets )
		end
		if self.target then
			local angle = rotateToTarget( self, self.target )
			if distanceSq( self.prop, self.target.prop ) <= self.range * self.range then
				if self.cooldown <= 0 then
					fire( scene, self, self.target, decks.bullet )
				end
			else
				local dx, dy = self.speed*time*cos(angle), self.speed*time*sin(angle)
				self.prop:moveLoc( dx, dy )
			end
		end			
	end

	return seeker
end

function makeSeekerSpawner( health, cooldown )
	spawner = makeEnemy( health, 100, 15 )
	spawner.prop:setDeck( decks.spawner )

	spawner.maxCooldown = cooldown or 5
	spawner.cooldown = spawner.maxCooldown

	spawner.updateCooldown = updateCooldown
	spawner.resetCooldown = resetCooldown
	
	function spawner:update( scene, time )
		if not scene.gameStarted then return end
		self:updateCooldown( time )
		if self.cooldown <= 0 then
			e = makeSmallSeeker( 10 )
			e.prop:setLoc( self.prop:getLoc() )
			scene.enemies[e] = e
			scene.objectLayer:insertProp( e.prop )
			self:resetCooldown()
		end
	end

	return spawner

end