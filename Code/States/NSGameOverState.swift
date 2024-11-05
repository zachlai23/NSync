//
//  NSGameOverState.swift
//  NSync
//
//  Created by Zachary Lai on 10/28/24.
//

import AVFoundation
import GameplayKit

class NSGameOverState: GKState {
	unowned let scene: NSGameScene
	unowned let context: NSGameContext
	
	var audioPlayer: AVAudioPlayer?
	
	init(scene: NSGameScene, context: NSGameContext) {
		self.scene = scene
		self.context = context
		super.init()
	}
	
	override func isValidNextState(_ stateClass: AnyClass) -> Bool {
		stateClass is NSPlayingState.Type
	}
	
	override func didEnter(from previousState: GKState?) {
		print("Entered Game Over State.")
		scene.showGameOverScreen()
	}
}
