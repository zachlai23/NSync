//
//  NSGameScene.swift
//  NSync
//
//  Created by Zachary Lai on 10/23/24.
//
// Screen users will see when playing
// Contains/references score game logic

import SpriteKit
import SwiftUI
import AVFoundation

class NSGameScene: SKScene {
	
	weak var context: NSGameContext?
	var isScoreSetUp: Bool = false
	
	var feedbackLabel: SKLabelNode!
	var line: SKShapeNode!
	var ball: SKShapeNode!
	var doublePointsLabel: SKLabelNode!
	
	var scoreNode = NSScoreNode()
	var doublePointsNode = NSDoublePointsNode()
	var playAgainButtonNode = NSPlayAgainButtonNode()
		
	var isLongPressActive = false
	
	var isFirstBeat = true
	
	var initialTimestamp: TimeInterval?
	
	var audioPlayer: AVAudioPlayer?
	
	struct Beat {
		var timestamp: Double
		var type: String // "tap" or "hold"
		var duration: Double? // Duration of hold
	}
	
	var beatTimestamps: [Beat] = []
	var adjustedBeatTimestamps: [Beat] = []
	var lastBeat: Double = 0
	var lastTap: Double = 0.0
	var lastCheckedTime: Double = 0.0
	
	var touchStartTime: TimeInterval = 0
	var pressStartTime: Date?
	
	var numPerfects: Int = 0
	var doublePeriod: Int = 0
	var doublePointThreshold: Int = 5
	
	private var lastUpdateTime: TimeInterval = 0
	
	init(context: NSGameContext, size: CGSize, score: Int = 0) {
		self.context = context
		context.gameInfo.score = score
		scoreNode.updateScore(with: score)
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
	
	override func update(_ currentTime: TimeInterval) {
		if let currentState = context?.stateMachine?.currentState as? NSPlayingState {
			currentState.checkIfSongFinished()
		}
	}

	
	// Load timestamps, type(tap or hold), and duration(if hold) from a csv to an array of Beat objects
	func loadBeatTimestamps(from fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
			print("File not found")
			return
		}
		
		do {
			let data = try String(contentsOf: url)
			let lines = data.components(separatedBy: .newlines)
			
			for line in lines {
				let components = line.components(separatedBy: ",")
				
				if components.count >= 2 {
					// Parse timestamp and type
					if let timestamp = Double(components[0].trimmingCharacters(in: .whitespaces)) {
						let type = components[1].trimmingCharacters(in: .whitespaces).lowercased()
						if type == "tap" {
							// If tap, create Beat object without duraton
							let beat = Beat(timestamp: timestamp, type: "tap", duration: nil)
							beatTimestamps.append(beat)
							adjustedBeatTimestamps.append(beat)
						} else if type == "hold", components.count >= 3 {
							// If hold, get duration value
							if let duration = Double(components[2].trimmingCharacters(in: .whitespaces)) {
								let beat = Beat(timestamp: timestamp, type: "hold", duration: duration)
								beatTimestamps.append(beat)
								adjustedBeatTimestamps.append(beat)
							}
						}
					}
				}
			}
		} catch {
			print("Error reading CSV file: \(error)")
		}
	}
	
	// Adjust beat timestamps when game loops and speeds up
	func adjustBeatTimestamps() {
		if let context = context {
			let speed = context.speedMultiplier
			
			// Adjust each beat's timestamp
			let adjustedBeats = beatTimestamps.map { beat -> Beat in
				var adjustedBeat = beat
				adjustedBeat.timestamp /= Double(speed)
				
				// Adjust duration for "hold" beats
				if let duration = adjustedBeat.duration {
					adjustedBeat.duration = duration / Double(speed)
				}
				return adjustedBeat
			}
			
			adjustedBeatTimestamps = adjustedBeats
		}
	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingTap(tapTime: Double) {
		lastTap = tapTime

		let firstBeat = beatTimestamps.first
		// Compare with first beat in list
		if firstBeat?.type == "tap" {
			let accuracy = abs(tapTime - (firstBeat?.timestamp ?? 0.0))
			
			// Check accuracy and award corresponding points
			if accuracy <= 0.075 {
				// Only apply double points period if game has been played for at least 40 seconds
				if firstBeat!.timestamp > 40.0 {
					doublePointsPerfect()
				}
				showFeedback(forAccuracy: "Perfect!")
				context?.gameInfo.score += 10
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				beatTimestamps.removeFirst()  // Remove current beat
				return

			} else if accuracy <= 0.2 {
				if firstBeat!.timestamp > 40.0 {
					doublePointsGood()
				}
				showFeedback(forAccuracy: "Good")
				context?.gameInfo.score += 5
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				beatTimestamps.removeFirst()
				return
			} else {
				if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
					playingState.audioPlayer?.stop()
				}
				context?.stateMachine?.enter(NSGameOverState.self)
			}
		}
	}

		
	// Update double points feature for a perfect tap
	func doublePointsPerfect() {
		numPerfects += 1
		if numPerfects >= doublePointThreshold {
			if doublePeriod < doublePointThreshold {
				if doublePeriod == 0 {
					self.doublePointsNode.setup(in: self.frame)
					self.addChild(self.doublePointsNode)
				}
				context?.gameInfo.score += 10
				doublePeriod += 1
			}
			else {
				doublePeriod = 0
				numPerfects = 0
				doublePointsNode.removeFromParent()
				doublePointThreshold += 1
			}
		}
	}
	
	// Update double points feature for as 'good' tap
	func doublePointsGood() {
		if numPerfects > doublePointThreshold {
			if doublePeriod < doublePointThreshold {
				context?.gameInfo.score += 5
				doublePeriod += 1
			}
			else {
				print("Double points period ended.")
				doublePointsNode.removeFromParent()
				doublePeriod = 0
				numPerfects = 0
				doublePointThreshold += 1
			}
		} else if doublePeriod == 0{
			numPerfects = 0
		}
	}
	
	//	// Check if user did not tap to a valid beat
	//	func checkMissedBeat(currentTime: Double) {
	//		if currentTime - lastBeat > 0.5 && lastBeat > lastTap {
	//			print("Fail - Missed a beat at \(lastBeat) seconds.")
	//			lastCheckedTime = currentTime
	//		}
	//	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		// If tap in start state, move to playing state
		if context?.stateMachine?.currentState is NSStartState {
			backgroundColor = .gray
			context?.stateMachine?.enter(NSPlayingState.self)
			// If tap in playing state, handle tap and play sound effect
		} else if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
			run(SKAction.playSoundFileNamed("tapNoise2", waitForCompletion: false))
			playingState.handleTap(touch)
		} else if let gameOverState = context?.stateMachine?.currentState as? NSGameOverState {
			// If play again button hit, restart game
			if playAgainButtonNode.contains(touch.location(in: self)) {
				restartGame()
			}
		}
	}
	
	// Using long press gesture to detect "holds"
	@objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
		if gestureRecognizer.state == .began {
			isLongPressActive = true
			print("Long press started")
			
			// Record the start time when the gesture begins
			pressStartTime = Date()
			
		} else if gestureRecognizer.state == .ended {
			isLongPressActive = false
			print("Long press ended")
			
			// Get duration of long press
			if let startTime = pressStartTime {
				let duration = Date().timeIntervalSince(startTime)
				print("Long press duration: \(duration) seconds")
				processHold(touchDuration: duration)
			}
		}
	}
	
	
	// Handle long press compared to beat
	func processHold(touchDuration: TimeInterval) {
		guard let currentState = context?.stateMachine?.currentState, currentState is NSPlayingState else {
			return
		}
		guard let currentBeat = beatTimestamps.first(where: { $0.type == "hold" }) else { return }
		
		// Compare duration of long press with actual duration in song
		let accuracy = abs(touchDuration - currentBeat.duration!)
		
		if accuracy <= 0.25 {
			showFeedback(forAccuracy: "Perfect!")
			context?.gameInfo.score += 10
			scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
			beatTimestamps.removeFirst() // Remove beat just checked
		} else if accuracy <= 0.5{
			showFeedback(forAccuracy: "Good")
			context?.gameInfo.score += 5
			scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
			beatTimestamps.removeFirst()
		} else {
			if let playingState = context?.stateMachine?.currentState as? NSPlayingState {
				playingState.audioPlayer?.stop()
			}
			context?.stateMachine?.enter(NSGameOverState.self)
		}
	}
	
	
	func restartGame() {
		print("Game restarting.")
		
		audioPlayer?.stop()
		
		adjustedBeatTimestamps = beatTimestamps
		// Create new instance of GameScene to prevent lag when playing again
		if let view = self.view {
			let newScene = NSGameScene(context: self.context!, size: view.bounds.size, score: 0)
			
			let transition = SKTransition.fade(withDuration: 0.5)
			view.presentScene(newScene, transition: transition)
		}
		context?.gameInfo.score = 0
		scoreNode.updateScore(with: 0)
		children.forEach { $0.removeFromParent() }
		scoreNode.removeFromParent()
		
		context?.speedMultiplier = 1.0
				
		context?.stateMachine?.enter(NSPlayingState.self)
	}
	
	// Game loop if song finished, pass score into new scene
	func restartGameStillPlaying() {
		print("Still playing, looping back over.")
		
		if let context = context {
			context.speedMultiplier += 0.1 // Increase speed by 10%
		}
		
		adjustBeatTimestamps()
		
		audioPlayer?.stop()
		if let view = self.view {
			let newScene = NSGameScene(context: self.context!, size: view.bounds.size, score: context?.gameInfo.score ?? 0)
			
			let transition = SKTransition.fade(withDuration: 0.5)
			view.presentScene(newScene, transition: transition)
		}
				
		context?.stateMachine?.enter(NSPlayingState.self)
	}
	
	// Start Screen - Gray screen with title
	func showStartScreen() {
		let title = SKLabelNode(text: "NSync")
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		title.fontName = "PPNeueMontreal-Bold"
		addChild(title)
	}
	
	func showPlayingScreen() {
		for node in children {
			if node.name != "scoreNode" {
				node.removeFromParent()
			}
		}
		
		// Show instructions for 1 second
		let title = SKLabelNode(text: "Tap to the beat.")
		title.name = "title"
		title.position = CGPoint(x: size.width / 2, y: size.height * (2.0 / 3))
		addChild(title)
		
		backgroundColor = .gray
		
		let waitAction = SKAction.wait(forDuration: 1.0)
		let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
		
		let removeAction = SKAction.run {
			title.removeFromParent()
		}
		
		let sequence = SKAction.sequence([waitAction, fadeOutAction, removeAction])
		
		// Add line and balls and begin audio
		title.run(sequence) {
//			if self.scoreNode != nil {
			self.scoreNode.setup(in: self.frame)
			self.scoreNode.updateScore(with: self.context?.gameInfo.score ?? 0)
			self.addChild(self.scoreNode)
//			}
			
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
				playingState.playAudio(fileName: "Song")
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
		title.position = CGPoint(x: size.width / 2, y: size.height * (2 / 3))
		addChild(title)
		
		scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
		scoreNode.position = CGPoint(x: size.width / 2, y: size.height * (3 / 5))
		addChild(scoreNode)
		
		playAgainButtonNode.setup(screenSize: size)
		addChild(playAgainButtonNode)
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
		for beat in adjustedBeatTimestamps {
			// Create ball node and action
			let ball = SKShapeNode(circleOfRadius: 15)
			ball.position = CGPoint(x: self.frame.minX - 15, y: self.frame.midY)
			self.addChild(ball)
			
			let adjustedDelay = (beat.timestamp - 0.8) / Double(context!.speedMultiplier)
			let adjustedDuration = 1.6 / context!.speedMultiplier
			
//			let delay = beat.timestamp - 0.8
			
			let moveAction = SKAction.moveTo(x: self.frame.maxX + 15, duration: TimeInterval(adjustedDuration))
			
			let waitAction = SKAction.wait(forDuration: adjustedDelay)
			let sequence = SKAction.sequence([waitAction, moveAction])
			if beat.type == "tap" {
				ball.fillColor = .blue
			} else {	//  If it is a "hold" beat, ball is red and "hold" is displayed for as long as user should hold for
				ball.fillColor = .red
				
				let holdText = SKLabelNode()
				holdText.position = CGPoint(x: self.size.width / 2, y: self.size.height * (3 / 10))
				holdText.fontSize = 40
				holdText.color = .white
				holdText.text = "Hold"
				holdText.fontName = "PPNeueMontreal-Book"
				
				let adjustedTextDelay = beat.timestamp / Double(context!.speedMultiplier)
				let waitToShowText = SKAction.wait(forDuration: adjustedTextDelay)
				let addTextAction = SKAction.run {
					self.addChild(holdText)
				}

				if let holdDuration = beat.duration {
					let adjustedHoldDuration = holdDuration / Double(context!.speedMultiplier)
					let removeTextDelay = SKAction.wait(forDuration: adjustedHoldDuration)
					let removeTextAction = SKAction.run {
						holdText.removeFromParent()
					}
					
					let showAndRemoveSequence = SKAction.sequence([waitToShowText, addTextAction, removeTextDelay, removeTextAction])
					self.run(showAndRemoveSequence)
				}
			}
			ball.run(sequence)
		}
	}

	
	func prepareGameContext() {
		guard let context = context else { return }
		
		context.scene = self
		context.updateLayoutInfo(withScreenSize: size)
		context.configureStates()
		
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
		longPressRecognizer.minimumPressDuration = 0.2
		view?.addGestureRecognizer(longPressRecognizer)
	}
}
