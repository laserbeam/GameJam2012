local max = math.max -- simple access speed optimization
local min = math.min 

local decks = {}
decks.enemyTurret = MOAIGfxQuad2D.new ()
decks.enemyTurret:setTexture ( "assets/T.png" )
decks.enemyTurret:setRect ( -64, -64, 64, 64 )
decks.enemyTurret:setUVRect ( 0, 0, 1, 1 )

decks.bullet = MOAIGfxQuad2D.new ()
decks.bullet:setTexture ( "assets/gun.png" )
decks.bullet:setRect ( -3, -3, 3, 3 )
decks.bullet:setUVRect ( 0, 0, 1, 1 )


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

function makeEnemyTurret( health, damage, fireCooldown, range )
	turret = makeEnemy( health, 50, 2 )
	
	turret.prop:setDeck( decks.enemyTurret )
	turret.prop:setScl( 0.4 )
	turret.gunCooldown = 0
	turret.damage = damage or 2
	turret.maxCooldown = fireCooldown or 1
	turret.cooldown = 0
	turret.range = 150

	turret.updateCooldown = updateCooldown
	turret.resetCooldown = resetCooldown
	
	function turret:update( scene, time )
		self:updateCooldown( time )
		if self.target then
			if self.target.isDead or distanceSq( self.prop, self.target.prop ) > self.range * self.range then
				self.target = nil
			end
		end
		if not self.target then
			local snake = scene.theSnake
			if snake then
				if snake:countMounts() > 0 then
					self.target = pickTargetInRangeFromTable( self, snake.mountedTurrets, self.range )
				end
			end
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