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
//	var frequencyTracker: FFTTap!
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
		
//		setupAudioAnalysis()
		loadBeatTimestamps(from: "song1Beats")
	}
	
	// Function to load beat timestamps from a CSV file
	func loadBeatTimestamps(from fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
			print("File not found")
			return
		}
		
		do {
			let data = try String(contentsOf: url)
			let lines = data.split(separator: "\n")
			
			// Assuming the CSV contains timestamps in the first column
			for line in lines {
				// Split the line by comma and take the first element
				let columns = line.split(separator: ",")
				if let firstColumn = columns.first,
				   let timestamp = Double(firstColumn.trimmingCharacters(in: .whitespaces)) {
					beatTimestamps.append(timestamp)
				}
			}
			print("Loaded \(beatTimestamps.count) beat timestamps.")
		} catch {
			print("Error reading CSV file: \(error)")
		}
	}

//	// Setup audio to receive fftdata and call analyzeFrequencyData
//	func setupAudioAnalysis() {
//		frequencyTracker = FFTTap(audioPlayer) { fftData in
//			self.analyzeData(fftData)
//		}
//	}
	
	func startBeatDetection() {
		do {
			try engine.start()
			audioPlayer.start()
//			frequencyTracker.start()
		} catch {
			print("Error starting audio engine or player: \(error)")
		}
	}
	
	func stopAudioAnalysis() {
		audioPlayer.stop()
	}
	
//	// Use the energy of the moment of the song to determine if it is a beat to tap to
//	private func analyzeData(_ fftData: [Float]) {
//		let currentTime = audioPlayer.currentTime
//		
//		let energy = fftData.map { $0 * $0 }.reduce(0, +)
//		
//		let amplitude = fftData.max() ?? 0.0
//
//		if energy > 3 && amplitude > 0.6 && currentTime - lastBeat > 1 {
//			lastBeat = currentTime
//			beatTimestamps.append(currentTime)
//			self.scene?.drawBeatDot()
//		}
//	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingBeat(tapTime: Double) {
		lastTap = tapTime
		print("User Tap Time: \(tapTime)")
		for beat in beatTimestamps {
			let accuracy = abs(tapTime - beat)
			print("Checking beat: \(beat), Accuracy: \(accuracy)")
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
