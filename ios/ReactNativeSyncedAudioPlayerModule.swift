import ExpoModulesCore
import AVFoundation

public class ReactNativeSyncedAudioPlayerModule: Module {
    private var composition = AVMutableComposition()
    private var player: AVQueuePlayer?
    private var audioMix = AVMutableAudioMix()
    private let queue = DispatchQueue(label: "com.syncedaudioplayer.queue")
    private var trackVolumes: [CMPersistentTrackID: Float] = [:] // Track ID to volume mapping
    private var mutedTracks: Set<CMPersistentTrackID> = [] // Set of muted track IDs
    private var playerLooper: AVPlayerLooper? // Added for looping support

    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    public func definition() -> ModuleDefinition {
        Name("ReactNativeSyncedAudioPlayer")

        // Function to add a new audio track
        Function("addTrack") { (value: AudioSource) -> Int in
            var trackIndex = 0
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                do {
                    let asset = AVURLAsset(url: value.uri!)
                    guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                        EXFatal(EXErrorWithMessage("No audio track found in asset"))
                        semaphore.signal()
                        return
                    }
                    
                    self.queue.sync {
                        do {
                            // Create a new composition track
                            guard let compositionTrack = self.composition.addMutableTrack(
                                withMediaType: .audio,
                                preferredTrackID: kCMPersistentTrackID_Invalid
                            ) else {
                                EXFatal(EXErrorWithMessage("Failed to create composition track"))
                                semaphore.signal()
                                return
                            }
                            
                            // Insert the audio track into the composition
                            try compositionTrack.insertTimeRange(
                                CMTimeRange(start: .zero, duration: asset.duration),
                                of: assetTrack,
                                at: .zero
                            )
                            
                            // Create audio mix parameters for the track
                            let inputParameters = AVMutableAudioMixInputParameters(track: compositionTrack)
                            inputParameters.trackID = compositionTrack.trackID
                            inputParameters.setVolume(1.0, at: .zero)
                            
                            // Initialize track volume to 1.0
                            self.trackVolumes[compositionTrack.trackID] = 1.0
                            
                            // Update audio mix parameters
                            self.audioMix.inputParameters = self.audioMix.inputParameters + [inputParameters]
                            
                            trackIndex = self.audioMix.inputParameters.count
                        } catch {
                            EXFatal(EXErrorWithMessage("Failed to add track: \(error.localizedDescription)"))
                        }
                    }
                    semaphore.signal()
                } catch {
                    EXFatal(EXErrorWithMessage("Failed to add track: \(error.localizedDescription)"))
                    semaphore.signal()
                    return
                }
            }
            
            semaphore.wait()
            return trackIndex
        }

        // Function to play all tracks simultaneously
        Function("play") { () -> Void in
            if self.player == nil {
                // Create a player item from the composition
                let playerItem = AVPlayerItem(asset: self.composition)
                
                // Apply audio mix to player item
                playerItem.audioMix = audioMix
                
                // Create and store the player
                self.player = AVQueuePlayer(playerItem: playerItem)
                
                // Setup looping
                if let player = self.player {
                    self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                }
            }
            
            // Start playback
            self.player?.play()
        }

        // Function to pause playback
        Function("pause") { () -> Void in
            self.player?.pause()
        }

        // Function to get current playback position in milliseconds
        Function("currentPosition") { () -> Double in
            guard let player = self.player else {
                return 0;
            }
            
            let seconds = CMTimeGetSeconds(player.currentTime())
            return seconds * 1000 // Convert to milliseconds
        }

        // Function to reset by removing all tracks
        Function("reset") { () -> Void in
            self.player?.pause()
            self.playerLooper = nil
            self.player = nil
            self.composition = AVMutableComposition()
            self.audioMix = AVMutableAudioMix()
            self.trackVolumes.removeAll()
            self.mutedTracks.removeAll()
        }

        // Function to set playback speed with pitch correction
        Function("setPlaybackSpeed") { (rate: Double) -> Void in
            guard let player = self.player else {
                return
            }
            
            // Ensure rate is within reasonable bounds
            let boundedRate = min(max(rate, 0.5), 2.0)
            
            // Enable audio pitch correction
            player.currentItem?.audioTimePitchAlgorithm = .spectral
            
            // Set the playback rate
            player.rate = Float(boundedRate)
        }

        // Optional: Function to stop playback
        Function("stop") { () -> Void in
            self.player?.pause()
            self.player?.seek(to: .zero)
        }
        
        Function("mute") { (trackID: CMPersistentTrackID) -> Void in
            self.mutedTracks.insert(trackID)
            setVolume(trackID: trackID, volume: 0)
        }

        // Function to unmute a specific track
        Function("unmute") { (trackID: CMPersistentTrackID) -> Void in
            self.mutedTracks.remove(trackID)
            let volume = self.trackVolumes[trackID] ?? 1.0
            setVolume(trackID: trackID, volume: volume)
        }

        // Function to set volume for a specific track
        Function("setVolume") { (trackID: CMPersistentTrackID, volume: Float) -> Void in
            if !self.mutedTracks.contains(trackID) {
                self.trackVolumes[trackID] = volume
            }
            setVolume(trackID: trackID, volume: self.mutedTracks.contains(trackID) ? 0 : volume)
        }
        
    }
    
    private func setVolume (trackID: CMPersistentTrackID, volume: Float) {
        guard let playerItem = player?.currentItem,
              let asset = playerItem.asset as? AVMutableComposition else { return }
            
        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []
        
        // Apply volume settings for all tracks
        for track in asset.tracks(withMediaType: .audio) {
            let params = AVMutableAudioMixInputParameters(track: track)
            if track.trackID == trackID {
                params.setVolume(volume, at: CMTime.zero)
            } else {
                let trackVolume = self.mutedTracks.contains(track.trackID) ? 0 : (self.trackVolumes[track.trackID] ?? 1.0)
                params.setVolume(trackVolume, at: CMTime.zero)
            }
            inputParameters.append(params)
        }
            
        // Apply input parameters to the audio mix
        audioMix.inputParameters = inputParameters
        playerItem.audioMix = audioMix
    }
}
