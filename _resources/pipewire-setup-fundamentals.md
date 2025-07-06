---
layout: page
title: PipeWire Setup and Fundamentals
description: Complete guide to installing, configuring, and verifying PipeWire on Ubuntu 24.04 with all compatibility layers
permalink: /resources/pipewire-setup-fundamentals/
---

## 📋 PipeWire Audio Guide Series

**🔹 You are here: Part 1 of 4** - Foundation setup and verification

### Complete Series:
1. **PipeWire Setup and Fundamentals** ← *Foundation setup and verification*
2. **[PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)** - *Create virtual sinks, sources, and loopbacks*
3. **[PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)** - *PulseAudio compatibility and application routing*
4. **[PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/)** - *Professional audio processing with plugins*

### Next Steps:
- **Complete this guide first** - Essential foundation for all other guides
- **Go to Virtual Devices** when you need advanced audio routing or streaming setups
- **Go to PulseAudio Integration** when you need application-specific routing or configuration
- **Go to VST/Carla** when you need professional audio processing with plugins

---

## Introduction

This guide provides a comprehensive overview of audio systems on modern Linux distributions, covering everything from basic concepts to advanced configuration. The examples and configurations in this guide are primarily tested on **Ubuntu 24.04 LTS**, though most concepts apply to other modern Linux distributions.


## Ubuntu 24.04 Audio Stack

Ubuntu 24.04 LTS marks a significant shift in Linux audio by adopting **PipeWire** as the default audio system, replacing PulseAudio. This modernization brings improved performance, lower latency, and better professional audio support.

### Default Versions Shipped

Ubuntu 24.04 LTS ships with these versions by default:

```bash
# Check PipeWire version
pipewire --version
# Output: pipewire - Compiled with libpipewire 1.0.5

# Check WirePlumber version  
wireplumber --version
# Output: wireplumber - Compiled with libwireplumber 0.4.17
```

### Current Audio Architecture

- **PipeWire 1.0.5**: Core audio/video routing engine
- **WirePlumber 0.4.17**: Session manager for PipeWire
- **ALSA**: Kernel-level hardware interface
- **PulseAudio compatibility**: Maintained through PipeWire's pulse server

### Upgrading to Latest Upstream Versions

For cutting-edge features, bug fixes, and performance improvements, you can upgrade to the latest upstream versions:

```bash
# Add PipeWire upstream PPA (provides PipeWire 1.0.7+)
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream

# Add WirePlumber upstream PPA (provides WirePlumber 0.5.2+)
sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream

# Update package lists
sudo apt update

# Upgrade to latest versions
sudo apt dist-upgrade
```

**After upgrade you'll have:**
- **PipeWire 1.0.7** (latest stable)
- **WirePlumber 0.5.2** (latest stable)

### Verification Commands

```bash
# Verify PipeWire is running
systemctl --user status pipewire

# Check PipeWire status and devices
wpctl status

# Get PipeWire server info
wpctl status | grep PipeWire

# Confirm upgraded versions
pipewire --version
```

## Understanding wpctl status Output

The `wpctl status` command provides a comprehensive view of your PipeWire audio system. Understanding its output is essential for troubleshooting and configuration.

### Sample Output Structure

```text
PipeWire 'pipewire-0' [1.0.7, user@hostname, cookie:1234567890]
 └─ Clients:
        32. KDE Power Management System         [1.0.7, user@hostname, pid:1897]
        33. libcanberra                         [1.0.7, user@hostname, pid:1854]
        34. xdg-desktop-portal                  [1.0.7, user@hostname, pid:1691]
        35. WirePlumber                         [1.0.7, user@hostname, pid:12345]
        36. WirePlumber [export]                [1.0.7, user@hostname, pid:12345]
        74. Plasma PA                           [1.0.7, user@hostname, pid:1854]
        75. wpctl                               [1.0.7, user@hostname, pid:15892]

Audio
 ├─ Devices:
 │      45. Audio Controller                   [alsa]
 │
 ├─ Sinks:
 │      48. Audio Controller HDMI Output 1     [vol: 1.00 MUTED]
 │      49. Audio Controller HDMI Output 2     [vol: 1.00 MUTED]
 │  *   50. Audio Controller Speaker/Headphones [vol: 0.65]
 │
 ├─ Sources:
 │      51. Audio Controller Headset Mic       [vol: 1.00]
 │  *   52. Audio Controller Internal Mic      [vol: 1.00]
 │
 ├─ Filters:
 │
 └─ Streams:
        53. Firefox                           [RUNNING]

Video
 ├─ Devices:
 │      43. Integrated Camera                  [v4l2]
 │
 ├─ Sinks:
 │
 ├─ Sources:
 │  *   44. Integrated Camera (V4L2)
 │
 ├─ Filters:
 │
 └─ Streams:
```

### Audio Component Definitions

Understanding the different components shown in `wpctl status` output:

---

#### 🔌 Devices
*Physical or virtual audio hardware detected by your system*

| Real-World Examples | How They Appear in wpctl |
|---|---|
| Built-in laptop sound card | `45. Audio Controller [alsa]` |
| USB audio interface | `46. Focusrite Scarlett [alsa]` |
| Bluetooth headphones | `47. Sony WH-1000XM4 [bluetooth]` |
| HDMI audio output | `48. HDMI Audio [alsa]` |

---

#### 🔊 Sinks (Outputs)
*Where your audio goes - speakers, headphones, etc.*

| Real-World Examples | How They Appear in wpctl |
|---|---|
| Desktop speakers | `50. Built-in Audio Analog Stereo [vol: 0.65]` |
| Wireless headphones | `51. Sony Headphones A2DP Sink [vol: 1.00]` |
| HDMI monitor speakers | `52. HDMI Output [vol: 1.00 MUTED]` |
| USB interface outputs | `*53. Scarlett Solo Analog Stereo [vol: 0.80]` |

*The `*` indicates the **default** sink*

---

#### 🎤 Sources (Inputs)
*Where audio comes from - microphones and line inputs*

| Real-World Examples | How They Appear in wpctl |
|---|---|
| Built-in laptop mic | `*54. Internal Microphone [vol: 1.00]` |
| USB microphone | `55. Blue Yeti Stereo [vol: 0.75]` |
| Audio interface input | `56. Scarlett Solo Mono [vol: 1.00]` |
| Bluetooth headset mic | `57. Headset Microphone [vol: 0.90]` |

*The `*` indicates the **default** source*

---

#### 🎵 Streams
*Active audio connections between apps and devices*

| Real-World Examples | How They Appear in wpctl |
|---|---|
| Firefox playing YouTube | `58. Firefox [RUNNING]` |
| Spotify streaming music | `59. Spotify [RUNNING]` |
| OBS recording | `60. obs [RUNNING]` |
| Paused video player | `61. VLC Media Player [IDLE]` |

---

#### 🎛️ Filters
*Audio processing modules - typically empty in standard setups*

This section shows active filter chains and processing modules. In most standard desktop setups, this remains empty:

```text
├─ Filters:
│
```

**Important**: PipeWire filter-chains are designed for **automatic insertion by session managers** like WirePlumber, not for per-application manual routing. For per-application audio processing, use [virtual devices](/resources/pipewire-virtual-devices/) with [VST processing chains](/resources/pipewire-vst-carla/) instead.

### Common Status Indicators

| Symbol | Meaning |
|--------|---------|
| `*` | Default device |
| `[RUNNING]` | Active audio stream |
| `[IDLE]` | Stream exists but not playing |
| `[SUSPENDED]` | Stream paused/suspended |
| `[vol: X.XX]` | Volume level (1.00 = 100%) |
| `MUTED` | Device is muted |

### Interpreting Device States

**Available devices** appear in the list with their current volume and properties.

**Unavailable devices** may appear grayed out or missing if disconnected.

**Default devices** are marked with `*` and will be used by new applications unless specifically configured otherwise.

```bash
# Confirm upgraded versions
wireplumber --version
```

## Essential PipeWire Client Libraries

While PipeWire serves as the core audio routing engine, additional compatibility libraries are required to ensure seamless operation with existing audio applications. These libraries act as translation layers, allowing applications designed for older audio systems to work transparently with PipeWire.

### Installing Audio Client Libraries

```bash
# Install the complete audio compatibility package
sudo apt install pipewire-audio-client-libraries
```

This transitional package automatically installs two crucial components:

### pipewire-alsa: ALSA Compatibility Layer

**Purpose**: Enables applications that use the ALSA (Advanced Linux Sound Architecture) API to route their audio through PipeWire instead of directly to ALSA hardware.

**What it provides**:
- ALSA plugin that redirects ALSA calls to PipeWire
- Seamless compatibility for applications built with ALSA libraries
- Automatic audio routing without application modifications

**Applications that benefit**:
- Many Linux games and older audio applications
- Command-line audio tools (`aplay`, `arecord`, etc.)
- Applications that directly use ALSA for low-level audio access
- Legacy multimedia software

**Configuration**: Creates `/etc/alsa/conf.d/99-pipewire-default.conf` which redirects ALSA's default PCM device to PipeWire.

### pipewire-jack: JACK Compatibility Layer

**Purpose**: Provides ABI-compatible JACK libraries, allowing professional audio applications designed for JACK to work seamlessly with PipeWire.

**What it provides**:
- Drop-in replacement for JACK client libraries
- Low-latency audio processing capabilities
- Connection management for professional audio workflows
- Session management integration

**Applications that benefit**:
- Digital Audio Workstations (DAWs) like Ardour, Reaper
- Audio plugins and VST hosts
- Live performance software
- Professional audio processing tools like JACK-based effects

**Key advantage**: Unlike traditional JACK, you don't need to manually start a JACK server - PipeWire handles this automatically while maintaining JACK compatibility.

### Why These Libraries Matter

**Unified Audio Ecosystem**: These compatibility layers allow PipeWire to serve as a universal audio server that can handle:

1. **Consumer applications** (web browsers, media players) via PulseAudio compatibility
2. **System applications** (ALSA-based tools) via ALSA compatibility
3. **Professional applications** (DAWs, audio production) via JACK compatibility

**Seamless Migration**: Applications don't need to be rewritten or reconfigured - they continue using their original APIs while PipeWire handles the routing behind the scenes.

### Verification

After installation, verify the compatibility layers are working:

```bash
# Check ALSA routing to PipeWire
aplay -l
# Should show PipeWire devices

# Verify PipeWire JACK compatibility is active
pw-cli info all | grep -i jack
# Should show JACK-related nodes if working

# Check all active nodes and clients
pw-cli list-objects
# Shows all PipeWire objects including JACK compatibility layer

# Check that applications can see PipeWire through different APIs
pactl info  # PulseAudio API
wpctl status # Native PipeWire API

# Monitor real-time PipeWire activity (optional)
pw-top
# Shows live node activity and performance stats
```

**Note**: You don't need separate JACK tools like `jack_lsp` - PipeWire provides native commands that show JACK compatibility status. If you have JACK applications, they should appear in `wpctl status` when running, and you can start them with `pw-jack <application>` if needed.

## Understanding Verification Command Output

Each verification command provides specific information about different aspects of your PipeWire audio system. Understanding their output helps confirm proper installation and diagnose issues.

### `aplay -l` - ALSA Hardware Device List

This command shows ALSA's view of available audio hardware. On a system with PipeWire working correctly, you'll see all physical audio devices:

```bash
aplay -l
```

**Example output:**
```text
**** List of PLAYBACK Hardware Devices ****
card 0: NVidia [HDA NVidia], device 3: HDMI 0 [ASUS PG43U]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 1: iD4 [Audient iD4], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
card 2: S3 [Schiit Modi 3+], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```

**What this means:**
- **Card numbers** (0, 1, 2): Each physical audio device gets a card number
- **Device names**: Human-readable names for your audio hardware
- **Subdevices**: Available channels/streams for each device
- **Subdevices 0/1**: Shows 0 available of 1 total (device is in use by PipeWire)

**Key indicator**: When `pipewire-alsa` is working, subdevices often show `0/1` (in use) because PipeWire has claimed the devices for routing.

### `pw-cli info all | grep -i jack` - JACK Compatibility Status

This command searches PipeWire's internal information for JACK-related components:

```bash
pw-cli info all | grep -i jack
```

**Example output:**
```text
*		module.jackdbus-detect = "true"
	name: "libpipewire-module-jackdbus-detect"
	filename: "/usr/lib/x86_64-linux-gnu/pipewire-0.3/libpipewire-module-jackdbus-detect.so"
            #jack.library     = libjack.so.0
            #jack.server      = null
            #jack.client-name = PipeWire
*		client.api = "jack"
*		config.name = "jack.conf"
```

**What this means:**
- **module.jackdbus-detect**: JACK detection module is loaded
- **client.api = "jack"**: JACK API clients are connected
- **jack.conf**: JACK configuration is active
- **Multiple entries**: Indicates JACK applications or components are running

**Key indicator**: If you see multiple `client.api = "jack"` entries, JACK compatibility is working and applications are using it.

### `pactl info` - PulseAudio Compatibility Status

This command shows PipeWire's PulseAudio compatibility layer status:

```bash
pactl info
```

**Example output on fresh Ubuntu 24.04:**
```text
Server String: /run/user/1000/pulse/native
Library Protocol Version: 35
Server Protocol Version: 35
Is Local: yes
Client Index: 12
Tile Size: 65472
User Name: username
Host Name: hostname
Server Name: PulseAudio (on PipeWire 1.0.5)
Server Version: 15.0.0
Default Sample Specification: float32le 2ch 48000Hz
Default Channel Map: front-left,front-right
Default Sink: alsa_output.pci-0000_00_1b.0.analog-stereo
Default Source: alsa_input.pci-0000_00_1b.0.analog-stereo
```

**What this means:**
- **Server Name**: `PulseAudio (on PipeWire X.X.X)` confirms PipeWire is running with PulseAudio compatibility
- **Default Sample Specification**: Audio format (32-bit float, 2 channels, 48kHz sample rate)
- **Default Sink/Source**: Currently active output and input devices
- **Client Index**: Lower numbers indicate fewer applications connected (fresh system)

**Key indicator**: The server name must show "PulseAudio (on PipeWire)" to confirm PipeWire is providing PulseAudio compatibility.

### `wpctl status` - Native PipeWire Status

This shows PipeWire's complete view of the audio system. On a fresh Ubuntu 24.04 system, you'd see:

```bash
wpctl status
```

**Example output (fresh system):**
```text
PipeWire 'pipewire-0' [1.0.5, username@hostname, cookie:123456789]
 └─ Clients:
        32. WirePlumber                         [1.0.5, username@hostname, pid:1234]
        33. WirePlumber [export]                [1.0.5, username@hostname, pid:1234]

Audio
 ├─ Devices:
 │      43. Built-in Audio                     [alsa]
 │
 ├─ Sinks:
 │  *   44. Built-in Audio Analog Stereo       [vol: 0.65]
 │
 ├─ Sources:
 │  *   45. Built-in Audio Analog Stereo       [vol: 1.00]
 │
 ├─ Filters:
 │
 └─ Streams:

Video
 ├─ Devices:
 │      46. Integrated Camera                  [v4l2]
 │
 ├─ Sources:
 │  *   47. Integrated Camera (V4L2)
 │
 ├─ Filters:
 │
 └─ Streams:
```

**What this means:**
- **PipeWire version**: Shows running version and session info
- **Clients**: WirePlumber session manager is running
- **Devices**: Physical hardware detected by PipeWire
- **Sinks/Sources**: Available outputs and inputs
- **`*` symbol**: Indicates default devices
- **Empty Filters/Streams**: Normal on idle system

**Key indicator**: A healthy fresh system shows WirePlumber running, detected audio hardware, and clear default devices marked with `*`.

## ✅ Progress Checkpoint

**What we've accomplished:**

✅ **Upgraded to latest stable versions**
- PipeWire 1.0.7+ (from upstream PPA)
- WirePlumber 0.5.2+ (from upstream PPA)

✅ **Installed essential compatibility layers**
- `pipewire-alsa` - ALSA applications → PipeWire routing
- `pipewire-jack` - JACK applications → PipeWire compatibility
- `pipewire-pulse` - PulseAudio applications → PipeWire (built-in)

✅ **Verified system functionality**
- ALSA hardware detection working (`aplay -l`)
- JACK compatibility active (`pw-cli info all | grep -i jack`)
- PulseAudio compatibility confirmed (`pactl info`)
- Native PipeWire status healthy (`wpctl status`)

**Your system now has:**
- Universal audio compatibility (ALSA, JACK, PulseAudio applications all work)
- Modern low-latency audio routing via PipeWire
- Professional audio capabilities without complex JACK setup
- Solid foundation for advanced audio configurations

---

## Next Steps: Advanced PipeWire Features

With the fundamentals in place, you're ready to explore PipeWire's advanced capabilities:

**Continue with:**
- [PipeWire Virtual Devices](/resources/pipewire-virtual-devices/) - Learn to create null sinks, loopbacks, and virtual microphones for advanced audio routing workflows
- [PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/) - Configure PulseAudio compatibility and application-specific routing
- [PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/) - Professional audio processing with VST plugins and effect chains

---
