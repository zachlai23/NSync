//
//  NSAudioManager.swift
//  NSync
//
//  Created by Zachary Lai on 10/30/24.
//
//  AudioManager class for analyzing songs

import AudioKit
import SpriteKit
import Foundation

class AudioManager: ObservableObject {
	var audioPlayer: AudioPlayer!
	var frequencyTracker: FFTTap!
	let engine = AudioEngine()
	
	var beatTimestamps: [Double] = []
	var lastBeat: Double = 0
	var lastTap: Double = 0.0
	var lastCheckedTime: Double = 0.0
	
	var scene: NSGameScene?
	
	init(scene: NSGameScene?) {
		self.scene = scene
	}
	
	// Loads audio file
	func loadAudioFile(url: URL) {
		audioPlayer = AudioPlayer(url: url)
		audioPlayer.isLooping = false
		engine.output = audioPlayer
		
		setupAudioAnalysis()
	}

	// Setup audio to receive fftdata and call analyzeFrequencyData
	func setupAudioAnalysis() {
		frequencyTracker = FFTTap(audioPlayer) { fftData in
			self.analyzeData(fftData)
		}
	}
	
	func startBeatDetection() {
		do {
			try engine.start()
			audioPlayer.start()
			frequencyTracker.start()
		} catch {
			print("Error starting audio engine or player: \(error)")
		}
	}
	
	func stopAudioAnalysis() {
		frequencyTracker.stop()
		audioPlayer.stop()
	}
	
	// Use the energy of the moment of the song to determine if it is a beat to tap to
	private func analyzeData(_ fftData: [Float]) {
		let currentTime = audioPlayer.currentTime
		
		let energy = fftData.map { $0 * $0 }.reduce(0, +)

		if energy > 2.25 && currentTime - lastBeat > 0.5 {
			lastBeat = currentTime
			beatTimestamps.append(currentTime)
			self.scene?.drawBeatDot()
		}
	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingBeat(tapTime: Double) {
		lastTap = tapTime
		
		for beat in beatTimestamps {
			let accuracy = abs(tapTime - beat)
			if accuracy <= 0.25{
				scene?.showFeedback(forAccuracy: "Perfect!")
				return
			}
			else if accuracy <= 0.5{
				scene?.showFeedback(forAccuracy: "Good")
				return
			}
		}
		scene?.showFeedback(forAccuracy: "Fail")
	}
	
	// Check if user did not tap to a valid beat
	func checkMissedBeat(currentTime: Double) {
		if currentTime - lastBeat > 0.5 && lastBeat > lastTap {
			print("Fail - Missed a beat at \(lastBeat) seconds.")
			lastCheckedTime = currentTime
		}
	}
}
