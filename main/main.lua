require 'LRGame'
Game = LRGame
Game.init()

-- Replace with states/splash_screen.lua at the end
LRStateManager.push('states/main_menu.lua')
LRStateManager.run()

