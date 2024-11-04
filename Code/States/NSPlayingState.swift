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
		scene.removeAllChildren()
		scene.showPlayingScreen()
		
		scene.loadBeatTimestamps(from: "song1Beats")
		playAudio(fileName: "NSyncAudio1")
		
	}
	
	func handleTap(_ touch: UITouch) {
		let tapTime = audioPlayer?.currentTime
//		print("Current tap time: \(tapTime)")
		
		scene.matchingBeat(tapTime: tapTime ?? 0.0)
	}
	
	private func playAudio(fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
			print("Audio file not found")
			return
		}
		
		do {
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer?.play()
		} catch {
			print("Error playing audio file: \(error)")
		}
	}
	
}
