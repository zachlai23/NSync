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

class NSGameScene: SKScene {
	
	weak var context: NSGameContext?
	
	
	var feedbackLabel: SKLabelNode!
	var dot: SKShapeNode!
	var line:SKShapeNode!
	
	var audioPlayer: AVAudioPlayer!
	
	var beatTimestamps: [Double] = []
	var lastBeat: Double = 0
	var lastTap: Double = 0.0
	var lastCheckedTime: Double = 0.0
	
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
				
		prepareGameContext()
		
		
		
		backgroundColor = .blue
		context.stateMachine?.enter(NSStartState.self)
		context.layoutInfo = NSLayoutInfo(screenSize: size)
		
	}

	func handleGameStart() {
		context?.stateMachine?.enter(NSPlayingState.self)
	}

	func handleGameOver() {
		context?.stateMachine?.enter(NSGameOverState.self)
	}
	
	func loadBeatTimestamps(from fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
			print("File not found")
			return
		}
		
		do {
			let data = try String(contentsOf: url)
			let lines = data.components(separatedBy: .newlines)
			
			// Assuming the CSV contains timestamps in the first column
			for line in lines {
				// Split the line by comma and take the first element
				let columns = line.split(separator: ",")
				if let firstColumn = columns.first,
				   let timestamp = Double(firstColumn.trimmingCharacters(in: .whitespaces)) {
					beatTimestamps.append(timestamp)
				}
			}
		} catch {
			print("Error reading CSV file: \(error)")
		}
	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingBeat(tapTime: Double) {
		lastTap = tapTime
		print("User Tap Time: \(tapTime)")
		for beat in beatTimestamps {
			let accuracy = abs(tapTime - beat)
			if accuracy <= 0.1{
				showFeedback(forAccuracy: "Perfect!")
				return
			}
			else if accuracy <= 0.25{
				showFeedback(forAccuracy: "Good")
				return
			}
		}
		showFeedback(forAccuracy: "Fail")
	}
	
	// Check if user did not tap to a valid beat
	func checkMissedBeat(currentTime: Double) {
		if currentTime - lastBeat > 0.5 && lastBeat > lastTap {
			print("Fail - Missed a beat at \(lastBeat) seconds.")
			lastCheckedTime = currentTime
		}
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
