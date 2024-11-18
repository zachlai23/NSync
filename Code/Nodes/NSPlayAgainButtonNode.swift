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
			rect: CGRect(x: -100, y: -25, width: 200, height: 50),
			cornerRadius: 5
		)
		backgroundNode.fillColor = .gray
	
		let textNode = SKLabelNode(text: "Play Again")
		textNode.fontName = "PPNeueMontreal-Bold"
		textNode.position = CGPoint(x: 0, y: -15)
		
		addChild(backgroundNode)
		addChild(textNode)
		
		self.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 - 100)
	}
}
