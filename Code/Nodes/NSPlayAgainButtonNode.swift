//
//  NSPlayAgainButtonNode.swift
//  NSync
//
//  Created by Zachary Lai on 11/6/24.
//

import SpriteKit

class NSPlayAgainButtonNode: SKNode {
	func setup(screenSize: CGSize) {
		let textNode = SKLabelNode(text: "Play Again")
		textNode.fontName = "PPNeueMontreal-Bold"
		position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 - 75) // Adjust size solely based on screen size to account for different device sizes
		
		let backgroundNode = SKShapeNode(
			rect: CGRect(x: -100, y: -25, width: 200, height: 50),		// same here, make positioning/size relative to screen size
			cornerRadius: 5
		)
		backgroundNode.fillColor = .gray
		addChild(backgroundNode)
		addChild(textNode)
	}

}
