let audioCtx;
let isPlaying = false;

// Binaural Beat Nodes
let leftOsc, rightOsc;
let leftPan, rightPan;
let binauralGain;
let carrierFreq = 200; // Base frequency

// Solfeggio Nodes
let osc432, osc528;
let gain432, gain528;

// Rain Nodes
let rainBufferSource, rainFilter, rainGain;

// UI Elements
const playBtn = document.getElementById('playBtn');
const playIcon = document.getElementById('playIcon');
const brainwaveSlider = document.getElementById('brainwaveSlider');
const brainwaveVal = document.getElementById('brainwaveVal');
const brainwaveType = document.getElementById('brainwaveType');
const binauralVolumeSlider = document.getElementById('binauralVolume');
const rainVolumeSlider = document.getElementById('rainVolume');
const toggle432 = document.getElementById('toggle432');
const toggle528 = document.getElementById('toggle528');

// Initialize Web Audio API
function initAudio() {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    
    // --- 1. Binaural Beats Setup ---
    leftOsc = audioCtx.createOscillator();
    rightOsc = audioCtx.createOscillator();
    
    leftPan = audioCtx.createStereoPanner();
    rightPan = audioCtx.createStereoPanner();
    leftPan.pan.value = -1; // Hard left
    rightPan.pan.value = 1;  // Hard right
    
    binauralGain = audioCtx.createGain();
    binauralGain.gain.value = binauralVolumeSlider.value;

    leftOsc.connect(leftPan).connect(binauralGain).connect(audioCtx.destination);
    rightOsc.connect(rightPan).connect(binauralGain).connect(audioCtx.destination);
    
    updateBinauralFreq();
    leftOsc.start();
    rightOsc.start();

    // --- 2. Solfeggio Setup ---
    osc432 = audioCtx.createOscillator();
    osc528 = audioCtx.createOscillator();
    osc432.frequency.value = 432;
    osc528.frequency.value = 528;
    
    gain432 = audioCtx.createGain();
    gain528 = audioCtx.createGain();
    gain432.gain.value = 0; // Initially off
    gain528.gain.value = 0; // Initially off

    osc432.connect(gain432).connect(audioCtx.destination);
    osc528.connect(gain528).connect(audioCtx.destination);
    
    osc432.start();
    osc528.start();

    // --- 3. Rain Sound (Filtered Brown Noise) Setup ---
    rainGain = audioCtx.createGain();
    rainGain.gain.value = rainVolumeSlider.value;
    rainGain.connect(audioCtx.destination);

    rainFilter = audioCtx.createBiquadFilter();
    rainFilter.type = 'lowpass';
    rainFilter.frequency.value = 800; // Lowpass to simulate distant rain rumble
    rainFilter.connect(rainGain);

    createRainBuffer();
}

function createRainBuffer() {
    const bufferSize = audioCtx.sampleRate * 5; // 5 seconds of noise
    const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
    const data = buffer.getChannelData(0);
    
    let lastOut = 0;
    for (let i = 0; i < bufferSize; i++) {
        let white = Math.random() * 2 - 1;
        data[i] = (lastOut + (0.02 * white)) / 1.02; // Brown noise approximation
        lastOut = data[i];
        data[i] *= 3.5; // Compensate gain
    }
    
    rainBufferSource = audioCtx.createBufferSource();
    rainBufferSource.buffer = buffer;
    rainBufferSource.loop = true;
    rainBufferSource.connect(rainFilter);
    rainBufferSource.start();
}

function updateBinauralFreq() {
    if (!audioCtx) return;
    const beatFreq = parseFloat(brainwaveSlider.value);
    // Left ear gets carrier, right gets carrier + beat
    leftOsc.frequency.setValueAtTime(carrierFreq, audioCtx.currentTime);
    rightOsc.frequency.setValueAtTime(carrierFreq + beatFreq, audioCtx.currentTime);
}

function getBrainwaveType(freq) {
    if (freq < 4) return "Delta";
    if (freq < 8) return "Theta";
    if (freq < 14) return "Alpha";
    if (freq < 30) return "Beta";
    return "Gamma";
}

// Event Listeners
playBtn.addEventListener('click', () => {
    if (!audioCtx) {
        initAudio();
        // Immediately pause everything to manage states correctly if needed
        // but since we want to play on first click:
        audioCtx.resume();
        isPlaying = true;
        playBtn.classList.add('playing');
        playIcon.innerText = "PAUSE";
        return;
    }

    if (isPlaying) {
        audioCtx.suspend();
        isPlaying = false;
        playBtn.classList.remove('playing');
        playIcon.innerText = "PLAY";
    } else {
        audioCtx.resume();
        isPlaying = true;
        playBtn.classList.add('playing');
        playIcon.innerText = "PAUSE";
    }
});

brainwaveSlider.addEventListener('input', (e) => {
    const val = parseFloat(e.target.value);
    brainwaveVal.innerText = val.toFixed(1);
    brainwaveType.innerText = getBrainwaveType(val);
    updateBinauralFreq();
});

binauralVolumeSlider.addEventListener('input', (e) => {
    if (binauralGain) {
        // Use setTargetAtTime to avoid clicks
        binauralGain.gain.setTargetAtTime(parseFloat(e.target.value), audioCtx.currentTime, 0.015);
    }
});

rainVolumeSlider.addEventListener('input', (e) => {
    if (rainGain) {
        rainGain.gain.setTargetAtTime(parseFloat(e.target.value), audioCtx.currentTime, 0.015);
    }
});

toggle432.addEventListener('change', (e) => {
    if (gain432) {
        gain432.gain.setTargetAtTime(e.target.checked ? 0.1 : 0, audioCtx.currentTime, 0.015);
    }
});

toggle528.addEventListener('change', (e) => {
    if (gain528) {
        gain528.gain.setTargetAtTime(e.target.checked ? 0.1 : 0, audioCtx.currentTime, 0.015);
    }
});

// Initialize UI
brainwaveType.innerText = getBrainwaveType(parseFloat(brainwaveSlider.value));
