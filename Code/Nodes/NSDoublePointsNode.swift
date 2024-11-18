//
//  NSDoublePointsNode.swift
//  NSync
//
//  Created by Zachary Lai on 11/11/24.
//

import SpriteKit
class NSDoublePointsNode: SKNode {
	private let textNode = SKLabelNode()
	
	func setup(in frame: CGRect) {
		removeAllChildren()
		position = CGPoint(x: frame.size.width / 2, y: frame.size.height * (9 / 10))
		textNode.fontSize = 40
		textNode.fontColor = .white
		textNode.fontName = "PPNeueMontreal-Bold"
		textNode.text = "DOUBLE POINTS!!!"
		addChild(textNode)
	}

}
