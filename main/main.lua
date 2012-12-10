----------------------------------------------------------------
-- Copyright (c) 2010-2011 Zipline Games, Inc. 
-- All Rights Reserved. 
-- http://getmoai.com
----------------------------------------------------------------
require 'LRGame'
Game = LRGame
Game.init()

LRStateManager.push('states/main_menu.lua')
LRStateManager.run()