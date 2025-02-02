import ExpoModulesCore
import AVFoundation

public class ReactNativeSyncedAudioPlayerModule: Module {
    private var composition = AVMutableComposition()
    private var player: AVPlayer?
    private var audioMix = AVMutableAudioMix()
    private let queue = DispatchQueue(label: "com.reactnativesyncedaudioplayer.queue")
    private var trackVolumes: [CMPersistentTrackID: Float] = [:]
    private var mutedTracks: Set<CMPersistentTrackID> = []
    private var audioSession: AVAudioSession?
    private var playerLooper: AVPlayerLooper?

    public func definition() -> ModuleDefinition {
        Name("ReactNativeSyncedAudioPlayer")

        Function("addTrack") { (value: AudioSource) -> Int in
            var trackIndex = 0
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                do {
                    // Configure audio session for background playback
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                    
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
                            
                            // Calculate how many times we need to repeat the track to fill an hour
                            let oneHour = CMTime(seconds: 3600, preferredTimescale: 1)
                            let assetDuration = asset.duration
                            let repeatCount = Int(ceil(oneHour.seconds / assetDuration.seconds))
                            
                            // Insert the audio track multiple times
                            var currentTime = CMTime.zero
                            for _ in 0..<repeatCount {
                                try compositionTrack.insertTimeRange(
                                    CMTimeRange(start: .zero, duration: assetDuration),
                                    of: assetTrack,
                                    at: currentTime
                                )
                                currentTime = CMTimeAdd(currentTime, assetDuration)
                            }
                            
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

        Function("play") { () -> Void in
            if self.player == nil {
                do {
                    // Configure audio session for background playback
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    let playerItem = AVPlayerItem(asset: self.composition)
                    playerItem.audioMix = audioMix
                    self.player = AVQueuePlayer(playerItem: playerItem)
                    
                    // Create a player looper
                    if let queuePlayer = self.player as? AVQueuePlayer {
                        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
                    }
                } catch {
                    EXFatal(EXErrorWithMessage("Failed to configure audio session: \(error.localizedDescription)"))
                    return
                }
            }
            self.player?.play()
        }

        Function("pause") { () -> Void in
            self.player?.pause()
        }

        Function("currentPosition") { () -> Double in
            guard let player = self.player else {
                return 0;
            }
            
            let seconds = CMTimeGetSeconds(player.currentTime())
            return seconds * 1000 // Convert to milliseconds
        }

        Function("reset") { () -> Void in
            self.player?.pause()
            self.playerLooper?.disableLooping()
            self.playerLooper = nil
            self.player = nil
            self.composition = AVMutableComposition()
            self.audioMix = AVMutableAudioMix()
            self.trackVolumes.removeAll()
            self.mutedTracks.removeAll()
            
            try? AVAudioSession.sharedInstance().setActive(false)
        }

        Function("setPlaybackSpeed") { (rate: Double) -> Void in
            guard let player = self.player else {
                return
            }
            
            let boundedRate = min(max(rate, 0.5), 2.0)
            player.currentItem?.audioTimePitchAlgorithm = .spectral
            player.rate = Float(boundedRate)
        }

        Function("stop") { () -> Void in
            self.player?.pause()
            self.player?.seek(to: .zero)
        }
        
        Function("seek") { (seconds: Double) -> Void in
            guard let player = self.player else {
                return
            }
            
            let currentTime = player.currentTime()
            let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
            player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        Function("mute") { (trackID: CMPersistentTrackID) -> Void in
            self.mutedTracks.insert(trackID)
            setVolume(trackID: trackID, volume: 0)
        }

        Function("unmute") { (trackID: CMPersistentTrackID) -> Void in
            self.mutedTracks.remove(trackID)
            let volume = self.trackVolumes[trackID] ?? 1.0
            setVolume(trackID: trackID, volume: volume)
        }

        Function("setVolume") { (trackID: CMPersistentTrackID, volume: Float) -> Void in
            if !self.mutedTracks.contains(trackID) {
                self.trackVolumes[trackID] = volume
            }
            setVolume(trackID: trackID, volume: self.mutedTracks.contains(trackID) ? 0 : volume)
        }
        
    }
    
    private func setVolume (trackID: CMPersistentTrackID, volume: Float) {
        guard let queuePlayer = player as? AVQueuePlayer else { return }
            
        // Create new audio mix
        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []
        
        // Apply volume settings for all tracks
        for track in composition.tracks(withMediaType: .audio) {
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
        
        // Update audio mix for all items in the queue
        for item in queuePlayer.items() {
            item.audioMix = audioMix
        }
    }
}
