import AVFoundation

class AudioEngineManager: ObservableObject {
    private var engine = AVAudioEngine()
    private var mainMixer: AVAudioMixerNode { engine.mainMixerNode }
    
    // Nodes
    private var binauralNode: AVAudioSourceNode!
    private var rainNode: AVAudioSourceNode!
    private var solfeggio432Node: AVAudioSourceNode!
    private var solfeggio528Node: AVAudioSourceNode!
    
    // Parameters
    @Published var isPlaying = false
    @Published var brainwaveFrequency: Float = 10.0
    @Published var binauralVolume: Float = 0.5 {
        didSet { binauralNode.volume = binauralVolume }
    }
    @Published var rainVolume: Float = 0.5 {
        didSet { rainNode.volume = rainVolume }
    }
    @Published var is432HzEnabled = false {
        didSet { solfeggio432Node.volume = is432HzEnabled ? 0.1 : 0.0 }
    }
    @Published var is528HzEnabled = false {
        didSet { solfeggio528Node.volume = is528HzEnabled ? 0.1 : 0.0 }
    }
    
    // State variables for oscillators
    private var time: Double = 0
    private let carrierFreq: Double = 200.0
    private let sampleRate: Double = 44100.0
    
    // Rain state
    private var lastBrownOut: Float = 0.0

    init() {
        setupAudioSession()
        setupEngine()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
    
    private func setupEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        // 1. Binaural Node (Left: Carrier, Right: Carrier + Brainwave)
        binauralNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftBuffer = ablPointer[0].mData!.assumingMemoryBound(to: Float.self)
            let rightBuffer = ablPointer[1].mData!.assumingMemoryBound(to: Float.self)
            
            for frame in 0..<Int(frameCount) {
                // Left channel gets the carrier frequency
                let leftVal = sin(Float(self.time * self.carrierFreq * 2.0 * .pi))
                
                // Right channel gets carrier + target brainwave frequency
                let rightVal = sin(Float(self.time * (self.carrierFreq + Double(self.brainwaveFrequency)) * 2.0 * .pi))
                
                leftBuffer[frame] = leftVal
                rightBuffer[frame] = rightVal
                
                self.time += 1.0 / self.sampleRate
            }
            return noErr
        }
        binauralNode.volume = binauralVolume
        
        // 2. Rain Node (Brown Noise approximation)
        rainNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                let white = Float.random(in: -1...1)
                self.lastBrownOut = (self.lastBrownOut + (0.02 * white)) / 1.02
                let out = self.lastBrownOut * 3.5
                
                // Copy to all channels (Mono to Stereo)
                for channel in 0..<ablPointer.count {
                    let buffer = ablPointer[channel].mData!.assumingMemoryBound(to: Float.self)
                    buffer[frame] = out
                }
            }
            return noErr
        }
        rainNode.volume = rainVolume
        
        // Lowpass filter for Rain (Creates that deep rumble sound)
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        let filterParams = eq.bands[0]
        filterParams.filterType = .lowPass
        filterParams.frequency = 800.0
        filterParams.bypass = false
        
        // 3. Solfeggio Nodes
        var time432: Double = 0
        solfeggio432Node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let val = sin(Float(time432 * 432.0 * 2.0 * .pi))
                for channel in 0..<ablPointer.count {
                    let buffer = ablPointer[channel].mData!.assumingMemoryBound(to: Float.self)
                    buffer[frame] = val
                }
                time432 += 1.0 / 44100.0
            }
            return noErr
        }
        solfeggio432Node.volume = 0.0
        
        var time528: Double = 0
        solfeggio528Node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let val = sin(Float(time528 * 528.0 * 2.0 * .pi))
                for channel in 0..<ablPointer.count {
                    let buffer = ablPointer[channel].mData!.assumingMemoryBound(to: Float.self)
                    buffer[frame] = val
                }
                time528 += 1.0 / 44100.0
            }
            return noErr
        }
        solfeggio528Node.volume = 0.0
        
        // Attach and connect
        engine.attach(binauralNode)
        engine.attach(rainNode)
        engine.attach(eq)
        engine.attach(solfeggio432Node)
        engine.attach(solfeggio528Node)
        
        engine.connect(binauralNode, to: mainMixer, format: format)
        engine.connect(rainNode, to: eq, format: format)
        engine.connect(eq, to: mainMixer, format: format)
        engine.connect(solfeggio432Node, to: mainMixer, format: format)
        engine.connect(solfeggio528Node, to: mainMixer, format: format)
    }
    
    func togglePlay() {
        if isPlaying {
            engine.pause()
            isPlaying = false
        } else {
            do {
                try engine.start()
                isPlaying = true
            } catch {
                print("Error starting engine: \(error)")
            }
        }
    }
}
