//
//  NSGameScene.swift
//  NSync
//
//  Created by Zachary Lai on 10/23/24.
//
// Screen suers will see when playing
// Contains/references score game logic

import SpriteKit

class NSGameScene: SKScene {
	
	weak var context: NSGameContext?	// reference game context
	
	private var lastUpdateTime: TimeInterval = 0
	
	init(context: NSGameContext, size: CGSize) {
		self.context = context
		super.init(size: size)
		print("Game scene initialized")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func didMove(to view: SKView) {
		guard let context else {
			return
		}
		
		backgroundColor = .white
		
		prepareGameContext()
		prepareStartNodes()
		
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

	
	override func update(_ currentTime: TimeInterval) {
		let deltaTime = currentTime - lastUpdateTime
		lastUpdateTime = currentTime
		context?.stateMachine?.update(deltaTime: deltaTime)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		run(SKAction.playSoundFileNamed("Tap Noise", waitForCompletion: false))
		
		if context?.stateMachine?.currentState is NSStartState {
			backgroundColor = .gray
			context?.stateMachine?.enter(NSPlayingState.self)
		}
	}
	
	func showStartScreen() {
		let title = SKLabelNode(text: "NSync")
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		addChild(title)
	}
	
	func showPlayingScreen() {
		childNode(withName: "title")?.removeFromParent()
		let title = SKLabelNode(text: "Tap to beat.")
		title.position = CGPoint(x: size.width / 2, y: size.height / 2)
		addChild(title)
	}

	
	func prepareGameContext() {
		guard let context else {
			return
		}
		
		context.scene = self
		context.updateLayoutInfo(withScreenSize: size)
		context.configureStates()
	}
	
	func prepareStartNodes() {
		guard let context else {
			return
		}

	}
	
	
}
