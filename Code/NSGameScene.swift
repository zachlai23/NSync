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
	var ring: SKShapeNode!
	var ball: SKShapeNode!
	var doublePointsLabel: SKLabelNode!
	
	var scoreNode = NSScoreNode()
	var doublePointsNode = NSDoublePointsNode()
	var playAgainButtonNode = NSPlayAgainButtonNode()
		
	var isLongPressActive = false
	
	var isFirstBeat = true
	
	var initialTimestamp: TimeInterval?
	
	var audioPlayer: AVAudioPlayer?
	var typingNoisePlayer: AVAudioPlayer?
	
	struct Beat {
		var timestamp: Double
		var type: String // "tap" or "hold"
		var duration: Double? // Duration of hold
		var node: SKShapeNode?
	}
	
	var beatToNodeMap: [Double: SKShapeNode] = [:]
	
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
	
	func startTypingNoise() {
		guard let soundURL = Bundle.main.url(forResource: "longType3", withExtension: "mp3") else { return }
		do {
			typingNoisePlayer = try AVAudioPlayer(contentsOf: soundURL)
			typingNoisePlayer?.numberOfLoops = -1  // Loop indefinitely while holding
			typingNoisePlayer?.volume = 0.8  // Adjust volume to your preference
			typingNoisePlayer?.play()
		} catch {
			print("Error loading sound file: \(error)")
		}
	}
	
	func stopTypingNoise() {
	 typingNoisePlayer?.stop()
	 typingNoisePlayer = nil
	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingTap(tapTime: Double) {
		lastTap = tapTime

		let firstBeat = beatTimestamps.first
		// Compare with first beat in list
		if firstBeat?.type == "tap" {
			let accuracy = abs(tapTime - (firstBeat?.timestamp ?? 0.0))
			
			// Check accuracy and award corresponding points
			if accuracy <= 0.15 {
				// Only apply double points period if game has been played for at least 40 seconds
				if firstBeat!.timestamp > 40.0 {
					doublePointsPerfect()
				}
				showFeedback(forAccuracy: "Perfect!")
				context?.gameInfo.score += 10
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				
				// Scale ball/bar up during correct tap
				if let shapeNode = beatToNodeMap[firstBeat!.timestamp] {
					let scaleUpAction = SKAction.scale(to: 1.35, duration: 0.1)
					let scaleDownAction = SKAction.scale(to: 1.0, duration: 0.1)
					let scaleSequence = SKAction.sequence([scaleUpAction, scaleDownAction])
					shapeNode.run(scaleSequence)
				}
				
				beatTimestamps.removeFirst()  // Remove current beat
				return

			} else if accuracy <= 0.25 {
				if firstBeat!.timestamp > 40.0 {
					doublePointsGood()
				}
				showFeedback(forAccuracy: "Good")
				context?.gameInfo.score += 5
				scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
				
				// Scale ball/bar up during correct tap
				if let shapeNode = beatToNodeMap[firstBeat!.timestamp] {
					let scaleUpAction = SKAction.scale(to: 1.25, duration: 0.1)
					let scaleDownAction = SKAction.scale(to: 1.0, duration: 0.1)
					let scaleSequence = SKAction.sequence([scaleUpAction, scaleDownAction])
					shapeNode.run(scaleSequence)
				}
				
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
			run(SKAction.playSoundFileNamed("keyboardClick3", waitForCompletion: false))
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
			
			startTypingNoise()
			
			// Record start time gesture begins
			pressStartTime = Date()
			
		} else if gestureRecognizer.state == .ended {
			isLongPressActive = false
			print("Long press ended")
			
			stopTypingNoise()
			
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
		
		if accuracy <= 0.4 {
			showFeedback(forAccuracy: "Perfect!")
			context?.gameInfo.score += 10
			scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
			
			// Scale up after correct hold
			if let shapeNode = beatToNodeMap[currentBeat.timestamp] {
				let scaleUpAction = SKAction.scale(to: 1.35, duration: 0.1)
				let scaleDownAction = SKAction.scale(to: 1.0, duration: 0.1)
				let scaleSequence = SKAction.sequence([scaleUpAction, scaleDownAction])
				shapeNode.run(scaleSequence)
			}
			
			beatTimestamps.removeFirst() // Remove beat just checked
		} else if accuracy <= 0.75{
			showFeedback(forAccuracy: "Good")
			context?.gameInfo.score += 5
			scoreNode.updateScore(with: context?.gameInfo.score ?? 0)
			
			if let shapeNode = beatToNodeMap[currentBeat.timestamp] {
				let scaleUpAction = SKAction.scale(to: 1.2, duration: 0.1)
				let scaleDownAction = SKAction.scale(to: 1.0, duration: 0.1)
				let scaleSequence = SKAction.sequence([scaleUpAction, scaleDownAction])
				shapeNode.run(scaleSequence)
			}
			
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
			self.spawnBalls()
			
			if let playingState = self.context?.stateMachine?.currentState as? NSPlayingState {
				playingState.playAudio(fileName: "Song")
			}
			
			self.scoreNode.setup(in: self.frame)
			self.scoreNode.updateScore(with: self.context?.gameInfo.score ?? 0)
			self.addChild(self.scoreNode)
			
			self.line = SKShapeNode()
			let lineStartY = self.frame.height * (3.0 / 5.0)
			let linePath = CGMutablePath()
			linePath.move(to: CGPoint(x: self.frame.midX, y: lineStartY))
			linePath.addLine(to: CGPoint(x: self.frame.midX, y: 0))
			
			self.line.path = linePath
			self.line.fillColor = .red
			self.line.strokeColor = .red
			self.addChild(self.line)
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
		for var beat in beatTimestamps {
			// Create ball node and action
			if beat.type == "tap" {
				let ball = SKShapeNode(circleOfRadius: 15)
				ball.fillColor = .blue
				ball.position = CGPoint(x: self.frame.minX - 15, y: self.frame.midY)
				self.addChild(ball)
				beatToNodeMap[beat.timestamp] = ball
				
				let delay = (beat.timestamp - 0.8) / Double(context!.speedMultiplier)
				let duration = 1.6 / context!.speedMultiplier
							
				let moveAction = SKAction.moveTo(x: self.frame.maxX + 15, duration: TimeInterval(duration))
				
				let waitAction = SKAction.wait(forDuration: delay)
				let sequence = SKAction.sequence([waitAction, moveAction])
				ball.run(sequence)
			} else {	//  If it is a "hold" beat
				let barWidth = CGFloat(beat.duration!) * 200.0 / CGFloat(context!.speedMultiplier)
				let barHeight: CGFloat = 30.0
				
				let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 15)
				bar.fillColor = .red
				bar.position = CGPoint(x: self.frame.minX - barWidth / 2, y: self.frame.midY)
				self.addChild(bar)
				beatToNodeMap[beat.timestamp] = bar
				
				// Calculate delay and duration adjusted for speed
				let delay = (beat.timestamp - 0.8) / Double(context!.speedMultiplier)
				let holdDuration = beat.duration! / Double(context!.speedMultiplier)
				
				let moveDistance = self.frame.width + barWidth
				let moveDuration = (1.6 + holdDuration) / Double(context!.speedMultiplier)
				
				let moveAction = SKAction.moveBy(x: moveDistance, y: 0, duration: TimeInterval(moveDuration))
				let waitAction = SKAction.wait(forDuration: delay)
				let sequence = SKAction.sequence([waitAction, moveAction])
				bar.run(sequence)
				}
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
