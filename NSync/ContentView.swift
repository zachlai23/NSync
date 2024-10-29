//
//  ContentView.swift
//  NSync
//
//  Created by Zachary Lai on 10/22/24.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
	let context = NSGameContext(dependencies: .init(), gameMode: .single)
	
	let screenSize: CGSize = UIScreen.main.bounds.size
	
    var body: some View {
		SpriteView(scene: NSGameScene(context: context, size: screenSize)).ignoresSafeArea()
    }
}

#Preview {
	ContentView().ignoresSafeArea()
}
