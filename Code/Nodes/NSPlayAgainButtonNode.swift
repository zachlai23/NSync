//
//  NSPlayAgainButtonNode.swift
//  NSync
//
//  Created by Zachary Lai on 11/6/24.
//

import SpriteKit

class NSPlayAgainButtonNode: SKNode {
	func setup(screenSize: CGSize) {
		self.name = "playAgainButton"

		
		let backgroundNode = SKShapeNode(
//			rect: CGRect(x: (screenSize.width / 2) - 100, y: (screenSize.height / 2) - 115, width: 200, height: 50),		// same here, make positioning/size relative to screen size
			rect: CGRect(x: -100, y: -25, width: 200, height: 50),
			cornerRadius: 5
		)
		backgroundNode.fillColor = .gray
	
		let textNode = SKLabelNode(text: "Play Again")
		textNode.fontName = "PPNeueMontreal-Bold"
		textNode.position = CGPoint(x: 0, y: -15)
//		textNode.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 - 100) // Adjust size solely based on screen size to account for different device sizes
		
		addChild(backgroundNode)
		addChild(textNode)
		
		self.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 - 100)
	}
}
