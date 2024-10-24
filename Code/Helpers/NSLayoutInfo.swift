//
//  NSLayoutInfo.swift
//  NSync
//
//  Created by Zachary Lai on 10/23/24.
//
// Size and position info about elements will be using from the start

import Foundation

struct NSLayoutInfo {
	let screenSize: CGSize
	let boxSize: CGSize = .init(width: 100, height: 100)
}
