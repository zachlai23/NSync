//
//  NSAudioManager.swift
//  NSync
//
//  Created by Zachary Lai on 10/30/24.
//
//  AudioManager class for analyzing songs

import AudioKit
import Foundation

class AudioManager: ObservableObject {
	var audioPlayer: AudioPlayer!
	var frequencyTracker: FFTTap!
	let engine = AudioEngine()
	
	var beatTimestamps: [Double] = []	// Store timestamps
	var lastBeat: Double = 0
	var lastTap: Double = 0.0
	var lastCheckedTime: Double = 0.0
	
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
		
		// Calculate the energy of the FFT data
		let energy = fftData.map { $0 * $0 }.reduce(0, +)

		// Check for significant beats based on energy
		if energy > 1.95 && currentTime - lastBeat > 0.5 {
			lastBeat = currentTime
			beatTimestamps.append(currentTime)
		}
	}
	
	// Compare user tap to beat timestamp, output feedback
	func matchingBeat(tapTime: Double) {
		lastTap = tapTime
		
		for beat in beatTimestamps {
			let accuracy = abs(tapTime - beat)
			if accuracy <= 0.4 &&  accuracy > 0.25{
				print("Good.")
				return
			}
			else if accuracy <= 0.25{
				print("Perfect!")
				return
			}
		}
		print("Fail")
	}
	
	// Check if user did not tap to a valid beat
	func checkMissedBeat(currentTime: Double) {
		if currentTime - lastBeat > 0.5 && lastBeat > lastTap {
			print("Fail - Missed a beat at \(lastBeat) seconds.")
			lastCheckedTime = currentTime
		}
	}
}
