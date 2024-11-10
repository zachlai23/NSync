//
//  NSScoreNode.swift
//  NSync
//
//  Created by Zachary Lai on 11/4/24.
//

import SpriteKit

class NSScoreNode: SKNode {
	private let textNode = SKLabelNode()
	
	func setup(in frame: CGRect) {
		removeAllChildren()
		position = CGPoint(x: frame.midX, y: frame.maxY - (frame.height * 0.2))
	    updateScore(with: 0)
		textNode.fontName = "PPNeueMontreal-Bold"
	    addChild(textNode)
	}

    func updateScore(with score: Int) {
		textNode.text = String(score)
	}
}


