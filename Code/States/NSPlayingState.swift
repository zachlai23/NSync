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
	
	var song: AVAudioPlayer?
	
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
		playSong()
	}
	
	func handleTap(_ touch: UITouch) {
		print("Touches received in PlayingState.")
		
		let tapTime = song?.currentTime
		print(tapTime ?? "No tap time.")
	}
	
//	func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent? ) {
//		print("Touches received in PlayingState.") 
//		
//		let tapTime = song?.currentTime
//		print(tapTime ?? "No tap time.")
//	}
	
	func playSong() {
		guard let musicURL = Bundle.main.url(forResource: "NSyncAudio1", withExtension: "mp3") else {
			return
		}
		do {
			song = try! AVAudioPlayer(contentsOf: musicURL)
			song?.play()
		}
	}


	
	
	
	
}
