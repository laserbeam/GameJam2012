require 'LRGame'
Game = LRGame
Game.init()

LRStateManager.push('states/main_menu.lua')
LRStateManager.run()