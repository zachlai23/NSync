//
//  NSGameContext.swift
//  NSync
//
//  Created by Zachary Lai on 10/23/24.
//
// Anything that is non core game logic specific
//  Any info for game and config for entire game cycle/session
// Game mode, score info, layout info referenced here

import Foundation
import GameplayKit

class NSGameContext: GameContext {
	var gameScene: NSGameScene? {
		scene as? NSGameScene
	}
	let gameMode: GameModeType
	var gameInfo: NSGameInfo
	var layoutInfo: NSLayoutInfo = .init(screenSize: .zero)
	
	private(set) var stateMachine: GKStateMachine?
	
	init(dependencies: Dependencies, gameMode: GameModeType) {
		self.gameInfo = NSGameInfo()
		self.gameMode = gameMode
		super.init(dependencies: dependencies)
	}
	
	func updateLayoutInfo(withScreenSize size: CGSize) {
		layoutInfo = NSLayoutInfo(screenSize: size)
	}
	
	func configureStates() {
		guard let gameScene else { return }
		stateMachine = GKStateMachine(
			states: [
				NSStartState(scene: gameScene, context: self),
				NSPlayingState(scene: gameScene, context: self),
				NSGameOverState(scene: gameScene, context: self)
		])
	}
	
}
