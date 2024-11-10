//
//  NSStartState.swift
//  NSync
//
//  Created by Zachary Lai on 10/28/24.
//

import GameplayKit

class NSStartState: GKState {
	unowned let scene: NSGameScene
	unowned let context: NSGameContext
	
	init(scene: NSGameScene, context: NSGameContext) {
		self.scene = scene
		self.context = context
		super.init()
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		stateClass is NSPlayingState.Type
	}
	
	override func didEnter(from previousState: GKState?) {
		print("Entered Start State")
		scene.showStartScreen()
	}
	
	func tapToStart() {
		context.stateMachine?.enter(NSPlayingState.self)
	}
}
