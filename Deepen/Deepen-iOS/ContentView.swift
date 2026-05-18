import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioEngineManager()
    @State private var isBreathing = false
    
    // Custom Colors matching the Web MVP
    let midnightNavy = Color(red: 10/255, green: 17/255, blue: 40/255)
    let tealColor = Color.teal
    let panelBg = Color.white.opacity(0.05)
    
    var body: some View {
        ZStack {
            midnightNavy.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Deepen")
                        .font(.system(size: 40, weight: .semibold, design: .default))
                        .foregroundColor(tealColor)
                        .tracking(2)
                    Text("Binaural Beats & Soundscapes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Central Play Button
                Button(action: {
                    audioManager.togglePlay()
                    if audioManager.isPlaying {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            isBreathing = true
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isBreathing = false
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [tealColor, Color(red: 0, green: 77/255, blue: 77/255)]), center: .center, startRadius: 0, endRadius: 80)
                            )
                            .frame(width: 160, height: 160)
                            .shadow(color: tealColor.opacity(audioManager.isPlaying ? 0.8 : 0.4), radius: isBreathing ? 30 : 15)
                            .scaleEffect(isBreathing ? 1.15 : 1.0)
                        
                        Text(audioManager.isPlaying ? "PAUSE" : "START")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1)
                    }
                }
                
                Spacer()
                
                // Controls Panel
                VStack(spacing: 25) {
                    // Brainwave Slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("뇌파 주파수: \(audioManager.brainwaveFrequency, specifier: "%.1f") Hz")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Spacer()
                            Text(getBrainwaveType(freq: audioManager.brainwaveFrequency))
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(tealColor)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        Slider(value: $audioManager.brainwaveFrequency, in: 0.5...40, step: 0.5)
                            .accentColor(tealColor)
                    }
                    
                    // Binaural Volume Slider
                    VStack(alignment: .leading) {
                        Text("바이노럴 비트 강도")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        Slider(value: $audioManager.binauralVolume, in: 0...1)
                            .accentColor(tealColor)
                    }
                    
                    // Rain Volume Slider
                    VStack(alignment: .leading) {
                        Text("배경 빗소리 볼륨")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        Slider(value: $audioManager.rainVolume, in: 0...1)
                            .accentColor(tealColor)
                    }
                }
                .padding()
                .background(panelBg)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Solfeggio Toggles Panel
                VStack(spacing: 15) {
                    Text("솔페지오 주파수")
                        .foregroundColor(tealColor)
                        .font(.subheadline)
                    
                    HStack(spacing: 40) {
                        Toggle("432 Hz", isOn: $audioManager.is432HzEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: tealColor))
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize()
                        
                        Toggle("528 Hz", isOn: $audioManager.is528HzEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: tealColor))
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize()
                    }
                }
                .padding()
                .background(panelBg)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        // Allows audio to play in background
        .onAppear {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }
    
    func getBrainwaveType(freq: Float) -> String {
        if freq < 4 { return "Delta" }
        if freq < 8 { return "Theta" }
        if freq < 14 { return "Alpha" }
        if freq < 30 { return "Beta" }
        return "Gamma"
    }
}
