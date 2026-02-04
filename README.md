# SuperCollider on Raspberry Pi Zero 2 W

Complete installation guide for SuperCollider 3.14.1 headless on Raspberry Pi Zero 2 W with Expert Sleepers ES-9 audio interface.

## System Information

- **Hardware**: Raspberry Pi Zero 2 W (4 cores @ 1000 MHz)
- **OS**: Debian GNU/Linux 12 (Bookworm) - aarch64
- **SuperCollider Version**: 3.14.1 (headless, no GUI)
- **Audio Interface**: Expert Sleepers ES-9 (16 inputs / 16 outputs)
- **Installation Date**: February 4, 2026

---

## Table of Contents

1. [System Update](#1-system-update)
2. [Install Dependencies](#2-install-dependencies)
3. [Clone SuperCollider Repository](#3-clone-supercollider-repository)
4. [Configure Build with CMake](#4-configure-build-with-cmake)
5. [Compile and Install](#5-compile-and-install)
6. [Configure JACK Audio](#6-configure-jack-audio)
7. [Configure CPU Performance Mode](#7-configure-cpu-performance-mode)
8. [Benchmarks](#8-benchmarks)
9. [Autostart Configuration](#9-autostart-configuration)
10. [Usage Examples](#10-usage-examples)
11. [Troubleshooting](#11-troubleshooting)

---

## Installation Steps

### 1. System Update

Update all system packages:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
```

### 2. Install Dependencies

Install all required libraries and build tools:

```bash
sudo apt-get install -y \
  build-essential \
  cmake \
  libjack-jackd2-dev \
  libsndfile1-dev \
  libfftw3-dev \
  libxt-dev \
  libavahi-client-dev \
  libudev-dev \
  libasound2-dev \
  libreadline-dev \
  libxkbcommon-dev \
  git \
  jackd2
```

**Note**: Accept realtime permissions for jackd when prompted.

### 3. Clone SuperCollider Repository

Clone the repository with all submodules:

```bash
cd ~
git clone --branch main --recurse-submodules https://github.com/supercollider/supercollider.git
cd supercollider
mkdir build && cd build
```

### 4. Configure Build with CMake

Configure for 64-bit headless build (no GUI):

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
  -DSUPERNOVA=OFF \
  -DSC_EL=OFF \
  -DSC_VIM=ON \
  -DNATIVE=ON \
  -DSC_IDE=OFF \
  -DNO_X11=ON \
  -DSC_QT=OFF \
  ..
```

**Configuration Details**:
- `Release`: Optimized build
- `SUPERNOVA=OFF`: Disable supernova audio server
- `SC_IDE=OFF`: No graphical IDE
- `NO_X11=ON`: No X11 support
- `SC_QT=OFF`: No Qt GUI framework
- `NATIVE=ON`: Optimize for this specific CPU

### 5. Compile and Install

⚠️ **IMPORTANT**: Compilation takes 2-4 hours on Pi Zero 2 W!

Compile without parallelization (to avoid running out of RAM):

```bash
make
```

**Note**: If compilation fails due to low RAM, reboot and run `make` again. CMake will resume from where it stopped.

Install SuperCollider system-wide:

```bash
sudo make install
sudo ldconfig
```

Verify installation:

```bash
sclang --version
# Should output: sclang 3.14.1 (Built from branch 'main' [426edf6d8])
```

Add user to audio group and reboot:

```bash
sudo usermod -aG audio $USER
sudo reboot
```

### 6. Configure JACK Audio

After reboot, check available audio devices:

```bash
aplay -l
cat /proc/asound/cards
```

**Important**: Note which card number your audio interface is assigned (usually `card 0` or `card 1`).

Create JACK configuration:

```bash
echo '/usr/bin/jackd -P75 -dalsa -dhw:0 -r48000 -p512 -n3' > ~/.jackdrc
```

**JACK Settings Explained**:
- `-P75`: Realtime priority 75
- `-dalsa`: Use ALSA driver
- `-dhw:0`: Hardware device 0 (change to `-dhw:1` if ES-9 is on card 1)
- `-r48000`: 48000 Hz sample rate
- `-p512`: 512 samples per period (~10.7ms latency)
- `-n3`: 3 periods

Start JACK:

```bash
nohup jackd -P75 -dalsa -dhw:0 -r48000 -p512 -n3 >/tmp/jackd.log 2>&1 &
```

Verify JACK is running:

```bash
pgrep -x jackd && echo "JACK RUNNING"
```

### 7. Configure CPU Performance Mode

Install CPU frequency utilities:

```bash
sudo apt-get install -y cpufrequtils
```

Set performance mode (temporary):

```bash
sudo cpufreq-set -g performance
```

Make performance mode permanent (survives reboot):

```bash
(sudo crontab -l 2>/dev/null; echo "@reboot sleep 10 && cpufreq-set -g performance") | sudo crontab -
```

Verify:

```bash
cpufreq-info | grep governor
# Should show: "performance"
```

### 8. Benchmarks

Run benchmark tests to evaluate performance:

**Test 1: Math Operations**

```bash
cat > /tmp/math_bench.scd << 'EOF'
s.waitForBoot {
    {1000000.do{2.5.sqrt}}.bench.postln;
    1.wait;
    0.exit;
};
EOF

sclang -D /tmp/math_bench.scd
```

**Test 2: Audio Processing CPU Usage**

```bash
cat > /tmp/cpu_bench.scd << 'EOF'
s.waitForBoot {
    "Starting audio test...".postln;
    ~a = {Mix(50.collect{RLPF.ar(SinOsc.ar)});DC.ar(0)}.play;
    
    3.wait;
    
    ("CPU 1: " ++ s.avgCPU.asString).postln;
    1.wait;
    ("CPU 2: " ++ s.avgCPU.asString).postln;
    1.wait;
    ("CPU 3: " ++ s.avgCPU.asString).postln;
    
    2.wait;
    ~a.free;
    0.exit;
};
EOF

sclang -D /tmp/cpu_bench.scd
```

**Benchmark Results for Pi Zero 2 W**:
- Math benchmark: **0.62 seconds**
- Audio CPU usage: **~15.6%** (50 filtered oscillators)

Comparison with other Raspberry Pi models:
- **Math**: RPi3: 0.56s | RPi2: 0.84s | RPi0: 1.7s | **Zero 2 W: 0.62s**
- **CPU**: RPi3: 11% | RPi2: 18% | RPi0: 37% | **Zero 2 W: 15.6%**

**Conclusion**: Pi Zero 2 W performs between RPi2 and RPi3, closer to RPi3!

See [benchmark_results.txt](benchmark_results.txt) for detailed results.

### 9. Autostart Configuration

Configure SuperCollider to start automatically on boot:

**Step 1**: Create autostart script:

```bash
cat > ~/autostart.sh << 'EOF'
#!/bin/bash
export PATH=/usr/local/bin:$PATH
export QT_QPA_PLATFORM=offscreen
export JACK_NO_AUDIO_RESERVATION=1
sleep 10
sclang ~/mycode.scd
EOF

chmod +x ~/autostart.sh
```

**Step 2**: Create your SuperCollider code:

```bash
cat > ~/mycode.scd << 'EOF'
s.waitForBoot{ 
    {SinOsc.ar([400, 404])}.play 
}
EOF
```

**Step 3**: Add to crontab:

```bash
(crontab -l 2>/dev/null; echo "@reboot ~/autostart.sh") | crontab -
```

**Step 4**: Test manually before rebooting:

```bash
~/autostart.sh &
sleep 15
ps aux | grep -E "sclang|scsynth|jackd" | grep -v grep
```

**Step 5**: Reboot to test autostart:

```bash
sudo reboot
```

After reboot, SuperCollider should start automatically and play the dual sine wave.

**To stop autostart processes**:

```bash
killall jackd sclang scsynth
```

---

## 10. Usage Examples

### Start SuperCollider Interactively

```bash
sclang
```

### Basic Commands

```supercollider
// Boot the server
s.boot;

// Simple oscillator on output 0
x = { Out.ar(0, SinOsc.ar(440) * 0.3) }.play;

// Stop it
x.free;

// Multiple outputs
{
    Out.ar(0, SinOsc.ar(440) * 0.2);  // Output 0
    Out.ar(1, SinOsc.ar(550) * 0.2);  // Output 1
    Out.ar(2, SinOsc.ar(660) * 0.2);  // Output 2
}.play;

// Stop all sounds
s.freeAll;

// Exit SuperCollider
0.exit
```

### Example: LFO Modulation

```supercollider
(
x = {
    var freq = SinOsc.kr(0.5).range(200, 800);  // LFO
    Out.ar(0, SinOsc.ar(freq) * 0.3);
}.play;
)
x.free;
```

### Example: Envelope

```supercollider
(
{
    var env = EnvGen.kr(Env.perc(0.01, 1), doneAction: 2);
    Out.ar(0, SinOsc.ar(440) * env * 0.3);
}.play;
)
```

---

## 11. Troubleshooting

### JACK Won't Start

**Check audio card number**:
```bash
cat /proc/asound/cards
```

**Update JACK config** if card number changed:
```bash
echo '/usr/bin/jackd -P75 -dalsa -dhw:X -r48000 -p512 -n3' > ~/.jackdrc
# Replace X with your card number (0 or 1)
```

### Audio Dropouts / Xruns

**Increase blocksize** for stability (higher latency):
```bash
echo '/usr/bin/jackd -P75 -dalsa -dhw:0 -r48000 -p1024 -n3' > ~/.jackdrc
```

**Or decrease for lower latency** (may cause xruns):
```bash
echo '/usr/bin/jackd -P75 -dalsa -dhw:0 -r48000 -p256 -n3' > ~/.jackdrc
```

### Low Audio Volume

Adjust ALSA mixer:
```bash
alsamixer
# Use arrow keys to set PCM to 85
# Press ESC to exit
```

### Can't Exit sclang

**Correct way**:
```supercollider
0.exit
```

**Or use**:
```supercollider
thisProcess.shutdown
```

**From terminal**: Press `Ctrl+C`

### Check if Processes are Running

```bash
ps aux | grep -E "sclang|scsynth|jackd" | grep -v grep
```

### View JACK Log

```bash
tail -f /tmp/jackd.log
```

### Compilation Failed (Out of Memory)

Reboot and run `make` again:
```bash
sudo reboot
# After reboot:
cd ~/supercollider/build
make
```

CMake remembers progress, so it will continue from where it stopped.

---

## File Locations

- **JACK config**: `~/.jackdrc`
- **Autostart script**: `~/autostart.sh`
- **SuperCollider code**: `~/mycode.scd`
- **JACK log**: `/tmp/jackd.log`
- **Binaries**: `/usr/local/bin/sclang`, `/usr/local/bin/scsynth`
- **Class library**: `/usr/local/share/SuperCollider/`

---

## Performance Summary

### System Configuration
- **Sample Rate**: 48000 Hz
- **Blocksize**: 512 samples (~10.7ms latency)
- **CPU Governor**: performance (1000 MHz)
- **Audio Interface**: ES-9 (16 channels I/O)

### Benchmark Results
- **Math operations**: 0.62s (better than RPi2, close to RPi3)
- **Audio CPU usage**: ~15.6% for 50 filtered oscillators
- **Performance ranking**: **RPi3 > Zero 2 W > RPi2 > RPi0**

### Recommended Settings
- **For low latency**: blocksize 256 or 512
- **For stability**: blocksize 1024
- **For quality**: Use external USB audio interface (ES-9 recommended)
- **CPU mode**: Always use "performance" governor for audio work

---

## Important Notes

⚠️ **Audio card numbers may change** after reboot. Always verify with `cat /proc/asound/cards` and update `~/.jackdrc` accordingly.

⚠️ **Compilation is slow** on Pi Zero 2 W (2-4 hours). Be patient and don't interrupt.

⚠️ **ES-9 provides 16 channels** but JACK auto-detects the channel count. No need to specify manually.

⚠️ **Don't use `:qa!` to exit sclang** - that's for Vim. Use `0.exit` instead.

---

## Credits

- SuperCollider: https://github.com/supercollider/supercollider
- Official Raspberry Pi README: [README_RASPBERRY_PI.md](https://github.com/supercollider/supercollider/blob/develop/README_RASPBERRY_PI.md)
- Expert Sleepers ES-9: https://expert-sleepers.co.uk/es9.html

---

## License

This guide is released under MIT License. SuperCollider is licensed under GPLv3.

---

**Installation by**: FedeRepic  
**Repository**: https://github.com/FedeRepic/raspberrypi-zero2w-supercollider  
**Date**: February 4, 2026
