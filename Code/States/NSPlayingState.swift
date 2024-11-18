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
	
	var audioPlayer: AVAudioPlayer?
		
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
//		scene.removeAllChildren()
		for node in scene.children {
			if node.name != "scoreNode" {
				node.removeFromParent()
			}
		}
		self.scene.loadBeatTimestamps(from: "NSyncTapHold")
		self.scene.showPlayingScreen()
	}
	
	func handleTap(_ touch: UITouch) {
		let tapTime = audioPlayer?.currentTime
		scene.matchingTap(tapTime: tapTime ?? 0.0)
	}
	
	func playAudio(fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
			print("Audio file not found")
			return
		}
		
		do {
			audioPlayer = try AVAudioPlayer(contentsOf: url)
//			audioPlayer?.numberOfLoops = -1
			if audioPlayer != nil {
				audioPlayer?.currentTime = 0
				audioPlayer?.rate = context.speedMultiplier ?? 1.0
				audioPlayer?.enableRate = true
				audioPlayer?.play()
			}
		} catch {
			print("Error playing audio file: \(error)")
		}
	}
	
	func checkIfSongFinished() {
		if let player = audioPlayer {
				if player.currentTime >= player.duration - 0.1 { // Check if song is finished
					print("Song finished. Restarting game.")
					scene.restartGameStillPlaying()
				}
			}
	}

}
