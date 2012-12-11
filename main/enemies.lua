local max = math.max -- simple access speed optimization
local min = math.min 

local enemyTurretDeck = MOAIGfxQuad2D.new ()
enemyTurretDeck:setTexture ( "assets/T.png" )
enemyTurretDeck:setRect ( -64, -64, 64, 64 )
enemyTurretDeck:setUVRect ( 0, 0, 1, 1 )

function makeEnemy( health, scoreValue, goldValue )
	enemy = {}
	enemy.health = health
	enemy.maxHealth = health
	enemy.scoreValue = scoreValue
	enemy.goldValue = goldValue

	enemy.prop = MOAIProp2D.new()

	function enemy:applyDamage( damage ) 
		self.health = self.health - damage
		if self.health < 0 then self.die() end
	end

	function enemy:healDamage( damage )
		self.health = min( self.health + damage, self.maxHealth )
	end

	function enemy:die()
		PLAYER.score = PLAYER.score + self.scoreValue
		PLAYER.gold = PLAYER.gold + self.goldValue
	end
	return enemy
end

function makeEnemyTurret( health, damage, fireCooldown, range )
	turret = makeEnemy( health, 50, 2 )
	
	turret.prop:setDeck( enemyTurretDeck )
	turret.prop:setScl( 0.4 )
	turret.gunCooldown = 0

	function turret:update( time )
		self.gunCooldown = max( 0, self.gunCooldown - time*fireCooldown)
	end
	return turret
end