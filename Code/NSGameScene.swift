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
	var line: SKShapeNode!
	var ball: SKShapeNode!

	var scoreNode = NSScoreNode()
	
	var audioPlayer: AVAudioPlayer?
	
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
	
	// Load timestamps from a csv to an array
	func loadBeatTimestamps(from fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
			print("File not found")
			return
		}
		
		do {
			let data = try String(contentsOf: url)
			let lines = data.components(separatedBy: .newlines)
			
			// take the first value(timestamp) from each row and add to beatTimestamps array
			for line in lines {
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
		for (index, beat) in beatTimestamps.enumerated() {
			let accuracy = abs(tapTime - beat)
			if accuracy <= 0.02{
				showFeedback(forAccuracy: "Perfect!")
				context?.gameInfo.score += 10
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				beatTimestamps.remove(at: index)	// Remove so two taps can't get points from the same beat
				return
			}
			else if accuracy <= 0.25{
				showFeedback(forAccuracy: "Good")
				context?.gameInfo.score += 5
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				beatTimestamps.remove(at: index)
				return
			}
		}
//		showFeedback(forAccuracy: "Fail")
//		context?.gameInfo.score -= 5
//		scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
		// Stop music and move to game over state
		if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
			playingState.audioPlayer?.stop()
		}
		context?.stateMachine?.enter(NSGameOverState.self)
	}
	
	// Check if user did not tap to a valid beat
	func checkMissedBeat(currentTime: Double) {
		if currentTime - lastBeat > 0.5 && lastBeat > lastTap {
			print("Fail - Missed a beat at \(lastBeat) seconds.")
			lastCheckedTime = currentTime
		}
	}

	override func update(_ currentTime: TimeInterval) {
//		let playerTime = audioManager.audioPlayer.currentTime
			
//		audioManager.checkMissedBeat(currentTime: playerTime)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		// If tap in start state, move to playing state
		if context?.stateMachine?.currentState is NSStartState {
			backgroundColor = .gray
			context?.stateMachine?.enter(NSPlayingState.self)
		// If tap in playing state, handle tap and play sound effect
		} else if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
			playingState.handleTap(touch)

			run(SKAction.playSoundFileNamed("Tap Noise", waitForCompletion: false))
		}
	}
	
	// Start Screen: Gray screen with title
	func showStartScreen() {
		let title = SKLabelNode(text: "NSync")
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		title.fontName = "PPNeueMontreal-Bold"
		addChild(title)
	}
	
	func showPlayingScreen() {
		childNode(withName: "title")?.removeFromParent()
		
		// Show instructions for 1 second
		let title = SKLabelNode(text: "Tap to the beat.")
		title.name = "title"
		title.position = CGPoint(x: size.width / 2, y: size.height * (2.0 / 3))
		addChild(title)

		let waitAction = SKAction.wait(forDuration: 1.0)
		let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)

		let removeAction = SKAction.run {
			title.removeFromParent()
		}

		let sequence = SKAction.sequence([waitAction, fadeOutAction, removeAction])
		
		// Add line and balls and begin audio
		title.run(sequence) {
			self.scoreNode.setup(in: self.frame)
			self.addChild(self.scoreNode)
			
			self.line = SKShapeNode()
			self.line = SKShapeNode()
			let lineStartY = self.frame.height * (3.0 / 5.0)
			let linePath = CGMutablePath()
			linePath.move(to: CGPoint(x: self.frame.midX, y: lineStartY))
			linePath.addLine(to: CGPoint(x: self.frame.midX, y: 0))
			
			self.line.path = linePath
			self.line.fillColor = .red
			self.line.strokeColor = .red
			self.addChild(self.line)
			
			self.spawnBalls()
			
			if let playingState = self.context?.stateMachine?.currentState as? NSPlayingState {
				playingState.playAudio(fileName: "NSyncAudio1")
			}
		}
	}
	
	// Show score and play again
	func showGameOverScreen() {
		removeAllActions()
		removeAllChildren()
		backgroundColor = .red
		let title = SKLabelNode(text: "Game Over")
		title.fontName = "PPNeueMontreal-Bold"
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		addChild(title)
		
		scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
		scoreNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
		addChild(scoreNode)
		
//		self.scoreNode.setup(in: self.frame)
//		self.addChild(self.scoreNode)
	}
	
	// Output feedback based on accuracy of tap
	func showFeedback(forAccuracy accuracy: String) {
		feedbackLabel = SKLabelNode()
		feedbackLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height * (7 / 10))
		feedbackLabel.fontSize = 40
		feedbackLabel.fontName = "PPNeueMontreal-Book"
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
	
	// Blue balls moving horizontally, passing the middle of the screen at each beat to tap to
	func spawnBalls() {
		for timestamp in beatTimestamps {
			let ball = SKShapeNode(circleOfRadius: 15)
			ball.fillColor = .blue
			ball.position = CGPoint(x: self.frame.minX - 15, y: self.frame.midY)
			self.addChild(ball)
			
			let delay = timestamp - 1.15
			
			let moveAction = SKAction.moveTo(x: self.frame.maxX + 15, duration: 2.3)
			
			let waitAction = SKAction.wait(forDuration: delay)
			let sequence = SKAction.sequence([waitAction, moveAction])

			ball.run(sequence)
		}
	}

	func prepareGameContext() {
		guard let context else { return }
		
		context.scene = self
		context.updateLayoutInfo(withScreenSize: size)
		context.configureStates()
	}
	
}
