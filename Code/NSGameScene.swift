//
//  NSGameScene.swift
//  NSync
//
//  Created by Zachary Lai on 10/23/24.
//
// Screen users will see when playing
// Contains/references score game logic

import SpriteKit
import AVFoundation
import AudioKit

class NSGameScene: SKScene {
	
	weak var context: NSGameContext?
	
	var audioManager: AudioManager!
	
	var feedbackLabel: SKLabelNode!
	var dot: SKShapeNode!
	var line:SKShapeNode!
	
	private var lastUpdateTime: TimeInterval = 0
	
	init(context: NSGameContext, size: CGSize) {
		self.context = context
		super.init(size: size)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func didMove(to view: SKView) {
		guard let context else { return }
		
		audioManager = AudioManager(scene: self)
		
		prepareGameContext()
		
		backgroundColor = .blue
		context.stateMachine?.enter(NSStartState.self)
		context.layoutInfo = NSLayoutInfo(screenSize: size)
		
		if let audioFileURL = Bundle.main.url(forResource: "NSyncAudio1", withExtension: "mp3") {
			audioManager.loadAudioFile(url: audioFileURL)
		} else {
			print("Audio file not found.")
		}
		
	}

	func handleGameStart() {
		context?.stateMachine?.enter(NSPlayingState.self)
	}

	func handleGameOver() {
		context?.stateMachine?.enter(NSGameOverState.self)
	}

	override func update(_ currentTime: TimeInterval) {
		let deltaTime = currentTime - lastUpdateTime
		lastUpdateTime = currentTime
		context?.stateMachine?.update(deltaTime: deltaTime)
		
		
//		let playerTime = audioManager.audioPlayer.currentTime
			
//		audioManager.checkMissedBeat(currentTime: playerTime)
	}
	
	func setupLine() {
		line = SKShapeNode()
		line.path = CGPath(rect: CGRect(x: frame.midX - 2, y: 0, width: 4, height: frame.height), transform: nil)
		line.fillColor = .red
		line.strokeColor = .red
		addChild(line)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		if context?.stateMachine?.currentState is NSStartState {
			backgroundColor = .gray
			context?.stateMachine?.enter(NSPlayingState.self)
		} else if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
			playingState.handleTap(touch)

			run(SKAction.playSoundFileNamed("Tap Noise", waitForCompletion: false))
		}
	}
	
	func showStartScreen() {
		let title = SKLabelNode(text: "NSync")
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		addChild(title)
	}
	
	func showPlayingScreen() {
		childNode(withName: "title")?.removeFromParent()
		let title = SKLabelNode(text: "Tap to the beat.")
		title.position = CGPoint(x: size.width / 2, y: size.height * (2.0 / 3))
		addChild(title)
		
		line = SKShapeNode()
		line.path = CGPath(rect: CGRect(x: frame.midX - 2, y: 0, width: 4, height: frame.height), transform: nil)
		line.fillColor = .red
		line.strokeColor = .red
		addChild(line)
	}
	
	func showFeedback(forAccuracy accuracy: String) {
		feedbackLabel = SKLabelNode()
		feedbackLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
		feedbackLabel.fontSize = 40
		if (accuracy == "Perfect!") {
			feedbackLabel.fontColor = .green
		}
		else if (accuracy == "Good") {
			feedbackLabel.fontColor = .yellow
		}
		else {
			feedbackLabel.fontColor = .red
		}
		feedbackLabel.text = accuracy
		addChild(feedbackLabel)
		

		let fadeOut = SKAction.sequence([
			SKAction.fadeOut(withDuration: 0.5),
			SKAction.removeFromParent()
		])
		
		feedbackLabel.run(fadeOut)
	}
	
	func drawBeatDot() {
		dot = SKShapeNode(circleOfRadius: 15)
		dot.fillColor = .blue
		dot.position = CGPoint(x: size.width / 2, y: size.height / 3)
		addChild(dot)
		
		let fadeOut = SKAction.sequence([
			SKAction.fadeOut(withDuration: 0.5),
			SKAction.removeFromParent()
		])
		
		dot.run(fadeOut)
		
	}
	
	func prepareGameContext() {
		guard let context else { return }
		
		context.scene = self
		context.updateLayoutInfo(withScreenSize: size)
		context.configureStates()
	}
	
}
