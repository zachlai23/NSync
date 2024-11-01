//
//  NSPlayingState.swift
//  NSync
//
//  Created by Zachary Lai on 10/28/24.
//

import GameplayKit
import SpriteKit
import AVFoundation

class NSPlayingState: GKState {
	unowned let scene: NSGameScene
	unowned let context: NSGameContext
		
	init(scene: NSGameScene, context: NSGameContext) {
		self.scene = scene
		self.context = context
		super.init()
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		stateClass is NSGameOverState.Type
	}
	
	override func didEnter(from previousState: GKState?) {
		print("Entered Playing State.")
		scene.removeAllChildren()
		scene.showPlayingScreen()
		
		scene.audioManager.startBeatDetection()
	}
	
	func handleTap(_ touch: UITouch) {
		guard let audioManager = scene.audioManager else { return }
		let tapTime = audioManager.audioPlayer.currentTime
		
		scene.audioManager.matchingBeat(tapTime: tapTime)
	}
	
}
