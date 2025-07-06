---
layout: page
title: PipeWire Virtual Devices
description: Complete guide to creating and managing virtual audio devices in PipeWire - null sinks, loopbacks, and virtual microphones
permalink: /resources/pipewire-virtual-devices/
---

## 📋 PipeWire Audio Guide Series

**🔹 You are here: Part 2 of 4** - Create virtual sinks, sources, and loopbacks

### Complete Series:
1. **[PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)** - *Foundation setup and verification*
2. **PipeWire Virtual Devices** ← *Create virtual sinks, sources, and loopbacks*
3. **[PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)** - *PulseAudio compatibility and application routing*
4. **[PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/)** - *Professional audio processing with plugins*

### Navigation:
- **Previous:** [Setup and Fundamentals](/resources/pipewire-setup-fundamentals/) - Required foundation
- **Next:** [PulseAudio Integration](/resources/pipewire-pulseaudio-integration/) - Application routing and compatibility
- **Advanced:** [VST/Carla](/resources/pipewire-vst-carla/) - Professional audio processing

---

## Prerequisites

This guide assumes you have completed the [PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/) guide. You should have:

- PipeWire 1.0.7+ and WirePlumber 0.5.2+ installed
- All compatibility layers working (ALSA, JACK, PulseAudio)
- Verified system functionality with the commands from the fundamentals guide

## Introduction to Virtual Devices

Virtual devices in PipeWire allow you to create software-based audio endpoints that don't correspond to physical hardware. These are essential for advanced audio workflows like:

- **Content creation**: Routing application audio to streaming software
- **System audio recording**: Capturing desktop audio alongside microphone input
- **Audio processing chains**: Creating complex routing between applications
- **Multi-application mixing**: Combining multiple audio sources
- **Monitoring and feedback prevention**: Creating isolated audio paths

## Types of Virtual Devices

For **VST processing workflows** and **pre-routed audio chains**, PipeWire offers two approaches with different strengths:

### 1. Null Sinks (Recommended for VST Workflows)

**Implementation**: `support.null-audio-sink` factory

**Why best for VST processing**:
- **Manual routing control**: Perfect for pre-routed VST chains that require precise signal flow
- **Carla integration**: Carla's patchbay handles connections automatically once configured
- **Static endpoints**: Don't change automatically, ideal for fixed VST routing
- **Monitor ports**: Direct access to audio stream for VST input

| Device Type | `media.class` | Function |
|-------------|---------------|----------|
| Virtual Sink | `Audio/Sink` | Has playback_* input ports and monitor_* output ports for VST routing |
| Virtual Source | `Audio/Source/Virtual` | Has input_* input ports and capture_* output ports |
| Virtual Duplex | `Audio/Duplex` | Combined sink and source functionality |

**Primary use cases:**
- **VST processing chains**: Building blocks for Carla-based audio processing
- **Pre-routed audio workflows**: Fixed routing for streaming, recording, content creation
- **Manual control**: When you need precise control over signal flow

### 2. Loopback Devices (For Automatic Integration)

**Implementation**: `libpipewire-module-loopback`

**When to use instead**:
- User-selectable devices in desktop audio controls
- Automatic routing with WirePlumber session management
- Dynamic device switching and fallback behavior

**Note**: For VST workflows, null sinks provide better manual control and work more reliably with Carla's patchbay routing.

## Creating Virtual Devices for VST Processing

Virtual devices in PipeWire are created through configuration files that survive system restarts, making them ideal for permanent VST processing workflows.

### Create Null Sink for VST Chains (Primary Method)

**Recommended for**: VST processing, Carla workflows, pre-routed audio chains

Create the configuration directory:
```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
```

Create configuration file optimized for VST workflows:
```bash
# ~/.config/pipewire/pipewire.conf.d/10-vst-null-sink.conf
context.objects = [
    {
        factory = adapter
        args = {
            factory.name = support.null-audio-sink
            node.name = "music-vst-sink"
            node.description = "Music VST Processing Sink"
            media.class = Audio/Sink
            audio.position = [ FL FR ]
            # Desktop integration properties for user selection
            device.description = "Music VST Processing Sink"
            device.class = "sound"
            device.icon-name = "audio-card"
            node.virtual = false
            # Monitor configuration optimized for VST routing
            monitor.channel-volumes = true
            monitor.passthrough = true
            adapter.auto-port-config = {
                mode = dsp
                monitor = true
                position = preserve
            }
        }
    }
]
```

Apply configuration:
```bash
# Restart PipeWire to apply changes
systemctl --user restart pipewire
```

**What this creates**:
- **User-selectable sink**: Appears in desktop audio controls for easy application routing
- **Monitor ports**: `music-vst-sink:monitor_FL` and `music-vst-sink:monitor_FR` for connecting to VST processing
- **Optimized for Carla**: Carla's patchbay can automatically manage connections to/from this sink

**Key advantage**: Carla's patchbay interface handles all routing automatically once configured - no manual `pw-link` commands needed.

#### Complete Null Sink Configuration Reference

Based on [`null-audio-sink.c`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c) source code analysis:

**Core Audio Properties**:

| Property | Description | Default Value | Example Values | Source Reference |
|----------|-------------|---------------|----------------|------------------|
| [`audio.format`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:943-944) | Audio sample format | `F32P` (32-bit float planar) | `F32P`, `F32`, `S16`, `S24`, `S32` | [Line 943-944](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L943-944) |
| [`audio.channels`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:945-946) | Number of audio channels | `2` | `1`, `2`, `6`, `8` | [Line 59, 945-946](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L59) |
| [`audio.rate`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:947-948) | Sample rate in Hz | `48000` | `44100`, `48000`, `96000`, `192000` | [Line 60, 947-948](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L60) |
| [`audio.position`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:951-952) | Channel position layout | `[ FL FR ]` | `[ FL FR ]`, `[ MONO ]`, `[ FL FR FC LFE RL RR ]` | [Line 951-952](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L951-952) |

**Node Behavior Properties**:

| Property | Description | Default Value | Example Values | Source Reference |
|----------|-------------|---------------|----------------|------------------|
| [`node.driver`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:949-950) | Acts as timing driver for graph | `true` | `true`, `false` | [Line 56, 949-950](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L56) |
| `node.name` | Internal node identifier | *auto-generated* | `"music-vst-sink"`, `"desktop-capture"` | PipeWire core |
| `node.description` | User-visible description | *matches node.name* | `"Music VST Processing Sink"` | PipeWire core |
| `media.class` | Device class for routing | *required* | `Audio/Sink`, `Audio/Source` | PipeWire core |

**Desktop Integration Properties**:

| Property | Description | Default Value | Example Values | Purpose |
|----------|-------------|---------------|----------------|---------|
| `device.description` | Name in audio controls | *none* | `"Music VST Processing Sink"` | Makes device selectable in KDE/GNOME |
| `device.class` | Device category | *none* | `"sound"` | Proper categorization in audio settings |
| `device.icon-name` | Icon for audio controls | *none* | `"audio-card"`, `"audio-headphones"` | Visual identification |
| `node.virtual` | Override virtual classification | *auto-detected* | `false` | Set to `false` to appear as regular device |

**Monitor Configuration** (for VST routing):

| Property | Description | Default Value | Example Values | Purpose |
|----------|-------------|---------------|----------------|---------|
| `monitor.channel-volumes` | Enable per-channel volume control | `false` | `true`, `false` | Volume control on monitor ports |
| `monitor.passthrough` | Direct audio passthrough | `false` | `true`, `false` | Low-latency monitoring |

**Advanced Properties**:

| Property | Description | Default Value | Example Values | Source Reference |
|----------|-------------|---------------|----------------|------------------|
| [`clock.quantum-limit`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:941-942) | Maximum quantum size | *system default* | `8192`, `4096`, `2048` | [Line 941-942](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L941-942) |
| [`clock.name`](/home/bashby/projects/misc/pipewire/spa/plugins/support/null-audio-sink.c:953-957) | Clock source identifier | `"clock.system.monotonic"` | `"clock.system.monotonic"`, custom clock names | [Line 37, 953-957](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/spa/plugins/support/null-audio-sink.c#L37) |

**Adapter Configuration**:

| Property | Description | Values | Purpose |
|----------|-------------|--------|---------|
| `adapter.auto-port-config.mode` | Port configuration mode | `dsp`, `convert`, `passthrough` | Controls audio processing behavior |
| `adapter.auto-port-config.monitor` | Enable monitor ports | `true`, `false` | Creates monitor outputs for VST routing |
| `adapter.auto-port-config.position` | Position handling | `preserve`, `unknown`, `aux` | How to handle channel positions |

#### Advanced Audio Processing Properties

**Note**: The following `channelmix.*` properties are **not available for null sinks**. These are specific to [`libpipewire-module-loopback`](/home/bashby/projects/misc/pipewire/src/modules/module-loopback.c) devices only. They are included here for reference when comparing with loopback devices.

| Property | Description | Values | Applies To |
|----------|-------------|---------|------------|
| `channelmix.upmix` | Enable stereo to surround upmixing | `true`, `false` | **Loopback devices only** |
| `channelmix.upmix-method` | Upmixing algorithm | `"psd"`, `"simple"`, `"none"` | **Loopback devices only** |
| `channelmix.lfe-cutoff` | Low frequency cutoff (Hz) | `150`, `80`, `120` | **Loopback devices only** |
| `channelmix.fc-cutoff` | Front center cutoff (Hz) | `12000`, `8000` | **Loopback devices only** |
| `channelmix.rear-delay` | Rear channel delay (ms) | `12.0`, `15.0` | **Loopback devices only** |
| `channelmix.stereo-widen` | Stereo field widening | `0.0` (none) to `1.0` (max) | **Loopback devices only** |
| `channelmix.hilbert-taps` | Rear channel phase shift | `0` (off), `63`, `127` | **Loopback devices only** |

**For VST processing workflows**: Use null sinks (above) for routing to external VST processors like Carla. For built-in audio processing, use loopback devices (below) with the channelmix properties.

### Alternative: Loopback Devices (For Automatic Integration)

**Note**: For VST processing workflows, null sinks (above) are recommended. Loopback devices are better for automatic desktop integration scenarios.

The `libpipewire-module-loopback` creates two internally-connected streams that are automatically managed by [WirePlumber](/resources/wireplumber-session-manager/).

**When to use loopback instead of null sinks**:
- User-selectable devices in desktop audio controls without manual Carla routing
- Automatic routing with fallback when devices disconnect
- Dynamic device switching managed by WirePlumber

#### Basic Loopback Configuration

```bash
# ~/.config/pipewire/pipewire.conf.d/11-loopback-devices.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            audio.position = [ FL FR ]
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "loopback-sink"
                node.description = "Loopback Virtual Sink"
                # Make it selectable in desktop audio controls
                device.description = "Loopback Virtual Sink"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "loopback-sink.output"
                node.passive = true
            }
        }
    }
]
```

**Key difference from null sinks**: Loopback devices rely on WirePlumber for automatic routing, while null sinks provide static endpoints that work better with Carla's manual patchbay routing.

### Finding Device Names for target.object

To find the correct device name for [`target.object`](file:///home/bashby/projects/misc/pipewire.wiki/Virtual-devices.md:236), use [`wpctl status`](/resources/pipewire-setup-fundamentals/#understanding-wpctl-status-output):

```bash
# List all audio devices with their node.name values
wpctl status

# Example output shows device names to use:
Audio
 ├─ Sinks:
 │  *   50. Built-in Audio Analog Stereo    [vol: 0.65]
 │      51. USB Headphones                  [vol: 1.00]
 │
 ├─ Sources:
 │  *   52. Built-in Microphone             [vol: 1.00]
 │      53. USB Microphone                  [vol: 0.90]
```

**Get exact [`node.name`](file:///home/bashby/projects/misc/pipewire.wiki/Virtual-devices.md:230) values**:
```bash
# Show detailed device properties including node.name
wpctl inspect 51  # Replace with device ID from wpctl status

# Look for the "node.name" property in output:
# * node.name = "alsa_output.usb-headphones.analog-stereo"
```

**Common device name patterns**:
- **Built-in audio**: `alsa_output.pci-0000_00_1b.0.analog-stereo`
- **USB devices**: `alsa_output.usb-device-name.analog-stereo`
- **Bluetooth**: `bluez_output.XX_XX_XX_XX_XX_XX.a2dp-sink`
- **HDMI**: `alsa_output.pci-0000_01_00.1.hdmi-stereo`

See [Understanding wpctl status Output](/resources/pipewire-setup-fundamentals/#understanding-wpctl-status-output) for complete device identification guide.

### Applying Configuration Changes

After creating or modifying virtual device configuration files in `~/.config/pipewire/pipewire.conf.d/`, you need to restart PipeWire to load the changes:

```bash
# Apply all configuration changes
systemctl --user restart pipewire

# Verify your virtual devices appear
wpctl status

# Optional: Monitor PipeWire for any errors during startup
journalctl --user -u pipewire -f
```

**Important notes:**
- **Restart required**: PipeWire only reads `.conf` files at startup, not dynamically
- **All streams affected**: Restarting PipeWire will briefly interrupt all audio applications
- **WirePlumber auto-restart**: WirePlumber automatically restarts with PipeWire, so no separate restart needed
- **Persistent configuration**: Virtual devices will automatically recreate on system reboot

**Troubleshooting configuration issues:**
```bash
# Check for configuration syntax errors
pipewire --version  # If this hangs, there's likely a config syntax error

# View detailed startup logs
journalctl --user -u pipewire --since "1 minute ago"

# Test configuration without persistence (temporary)
pipewire -c /path/to/test-config.conf
```

**Advanced Audio Processing** (playback.props only):

| Property | Description | Values |
|----------|-------------|---------|
| `channelmix.upmix` | Enable stereo to surround upmixing | `true`, `false` |
| `channelmix.upmix-method` | Upmixing algorithm | `"psd"`, `"simple"`, `"none"` |
| `channelmix.lfe-cutoff` | Low frequency cutoff (Hz) | `150`, `80`, `120` |
| `channelmix.fc-cutoff` | Front center cutoff (Hz) | `12000`, `8000` |
| `channelmix.rear-delay` | Rear channel delay (ms) | `12.0`, `15.0` |
| `channelmix.stereo-widen` | Stereo field widening | `0.0` (none) to `1.0` (max) |
| `channelmix.hilbert-taps` | Rear channel phase shift | `0` (off), `63`, `127` |

#### How WirePlumber Manages Loopback Devices

When loopback devices are created, [WirePlumber's session and policy management](/resources/wireplumber-session-manager/#core-responsibilities) handles:

**Automatic Connection**:
- **No target.object**: Playback stream connects to default device
- **With target.object**: Connects to specified device if available
- **Fallback behavior**: Moves to available device if target disappears

**Stream Management**:
- Treats both streams as normal audio connections
- Allows moving with wpctl commands like any other stream
- Handles priority and routing policy decisions
- Manages suspend/resume with `node.passive`

**Dynamic Behavior**:
- Device changes trigger automatic reconnection
- New device availability can redirect streams
- User device selection overrides automatic routing

This sophisticated behavior makes loopback devices much more user-friendly than [single nodes](#create-persistent-null-sink), which require manual `pw-link` management.

## Real-World Usage Scenarios

### Scenario 1: Streaming Setup with OBS

**Goal**: Capture desktop audio and microphone separately in OBS for better control.

Create persistent desktop audio capture device:

```bash
# ~/.config/pipewire/pipewire.conf.d/streaming-setup.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Desktop Audio Capture"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "desktop-audio-sink"
                media.class = "Audio/Sink"
                node.description = "Desktop Audio Capture"
                # Make it selectable in desktop audio controls
                device.description = "Desktop Audio Capture"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "desktop-audio-monitor"
                node.description = "Desktop Audio Capture Monitor"
                node.passive = true
            }
        }
    }
]
```

Apply configuration:
```bash
systemctl --user restart pipewire
```

Set as default system output:
```bash
wpctl set-default $(wpctl status | grep "desktop-audio-sink" | awk '{print $1}' | sed 's/\.//')
```

**In OBS:**
- Add "Audio Input Capture" source
- Select "Desktop Audio Capture Monitor" as device
- Add another "Audio Input Capture" for your physical microphone

**Result**: Separate audio tracks for desktop and microphone, independent volume control. Configuration persists across reboots.

### Scenario 2: Gaming Audio Separation

**Goal**: Create separate virtual sinks for game audio and voice chat, allowing independent volume control and routing to different outputs.

```bash
# ~/.config/pipewire/pipewire.conf.d/gaming-audio.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Game Audio"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "game-audio-sink"
                media.class = "Audio/Sink"
                node.description = "Game Audio"
                # Make it selectable in desktop audio controls
                device.description = "Game Audio"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "game-audio-output"
                target.object = "alsa_output.usb-SteelSeries_Arctis_7-00.analog-stereo"
                node.passive = true
            }
        }
    }
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Voice Chat Audio"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "voice-chat-sink"
                media.class = "Audio/Sink"
                node.description = "Voice Chat Audio"
                # Make it selectable in desktop audio controls
                device.description = "Voice Chat Audio"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "voice-chat-output"
                target.object = "alsa_output.pci-0000_00_1b.0.analog-stereo"
                node.passive = true
            }
        }
    }
]
```

**Usage**: Route games to "Game Audio" sink (goes to headphones), route Discord/TeamSpeak to "Voice Chat Audio" sink (goes to speakers). Based on the [PipeWire module-loopback documentation](https://docs.pipewire.org/page_module_loopback.html) for virtual sink creation with specific target devices.

### Scenario 3: Multi-Channel Audio Interface Setup

**Goal**: Split a professional audio interface into separate mono sources for microphone and instrument inputs.

```bash
# ~/.config/pipewire/pipewire.conf.d/audio-interface-split.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Studio Microphone"
            capture.props = {
                node.name = "capture.studio-mic"
                audio.position = [ AUX0 ]
                stream.dont-remix = true
                target.object = "alsa_input.usb-BEHRINGER_UMC404HD_192k-00.pro-input-0"
                node.passive = true
            }
            playback.props = {
                node.name = "studio-microphone"
                media.class = "Audio/Source"
                audio.position = [ MONO ]
            }
        }
    }
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Guitar Direct Input"
            capture.props = {
                node.name = "capture.guitar-di"
                audio.position = [ AUX1 ]
                stream.dont-remix = true
                target.object = "alsa_input.usb-BEHRINGER_UMC404HD_192k-00.pro-input-0"
                node.passive = true
            }
            playback.props = {
                node.name = "guitar-di"
                media.class = "Audio/Source"
                audio.position = [ MONO ]
            }
        }
    }
]
```

**Usage**: Creates separate mono sources from multichannel pro audio interface. Based on the [PipeWire Virtual-devices wiki examples](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#behringer-umc404hd-microphoneguitar-virtual-sources) for Behringer UMC404HD channel splitting.

### Scenario 4: Home Theater Upmixing

**Goal**: Create an intelligent upmixing sink that converts stereo music to 5.1 surround sound with proper frequency separation.

```bash
# ~/.config/pipewire/pipewire.conf.d/home-theater-upmix.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Home Theater Upmix"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "home-theater-sink"
                media.class = "Audio/Sink"
                node.description = "Home Theater 5.1 Upmix"
                # Make it selectable in desktop audio controls
                device.description = "Home Theater 5.1 Upmix"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "home-theater-output"
                audio.position = [ FL FR FC LFE RL RR ]
                target.object = "alsa_output.usb-home-theater-device.analog-surround-51"
                stream.dont-remix = true
                node.passive = true
                
                # Upmixing configuration from module-loopback source
                channelmix.upmix = true
                channelmix.upmix-method = "psd"
                channelmix.lfe-cutoff = 150
                channelmix.fc-cutoff = 12000
                channelmix.rear-delay = 12.0
                channelmix.stereo-widen = 0.1
            }
        }
    }
]
```

**Usage**: Send stereo music/movies to this sink for intelligent 5.1 upmixing with proper bass management and surround effects. Configuration based on [PipeWire module-loopback upmixing example](https://docs.pipewire.org/page_module_loopback.html) and [channelmix properties](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#stereo-to-51-upmixing-sink).

### Scenario 5: Content Creator Setup

**Goal**: Create virtual microphone and desktop audio capture for streaming/recording with exclusive hardware access and independent processing chains.

```bash
# ~/.config/pipewire/pipewire.conf.d/content-creator.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Stream Microphone"
            capture.props = {
                node.name = "capture.stream-mic"
                audio.position = [ MONO ]
                stream.dont-remix = true
                target.object = "alsa_input.usb-your-microphone-device.analog-stereo"
                node.exclusive = true
                node.dont-reconnect = true
                node.passive = true
            }
            playback.props = {
                node.name = "stream-microphone"
                media.class = "Audio/Source"
                node.description = "Stream Microphone"
                audio.position = [ MONO ]
            }
        }
    }
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Desktop Audio Capture"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "desktop-capture-sink"
                media.class = "Audio/Sink"
                node.description = "Desktop Audio for Streaming"
                # Make it selectable in desktop audio controls
                device.description = "Desktop Audio for Streaming"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "desktop-audio-monitor"
                media.class = "Audio/Source"
                node.description = "Desktop Audio Monitor"
                node.passive = true
            }
        }
    }
]
```

**Setup Steps**:
1. Find your microphone device name: `wpctl status | grep -A 10 Sources`
2. Replace `"alsa_input.usb-your-microphone-device.analog-stereo"` with your actual microphone's `node.name`
3. Apply configuration: `systemctl --user restart pipewire`

**Usage**: Physical microphone has **exclusive access** through "Stream Microphone" source - no other applications can access the hardware mic while this is active. Raw audio bytes flow directly from hardware to virtual device without additional mixing or processing. System audio → "Desktop Audio for Streaming" → OBS gets "Desktop Audio Monitor". Based on [PipeWire Virtual-devices wiki Virtual Mono Source example](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#virtual-mono-source) for permanent hardware routing with [exclusive access properties](https://docs.pipewire.org/group__pw__keys.html).

### Scenario 6: Multi-Room Audio

**Goal**: Route different audio sources to specific rooms while maintaining central control.

```bash
# ~/.config/pipewire/pipewire.conf.d/multi-room-audio.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Living Room Audio"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "living-room-sink"
                media.class = "Audio/Sink"
                node.description = "Living Room Speakers"
                # Make it selectable in desktop audio controls
                device.description = "Living Room Speakers"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "living-room-output"
                target.object = "alsa_output.usb-living-room-amp.analog-stereo"
                node.passive = true
            }
        }
    }
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Kitchen Audio"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "kitchen-sink"
                media.class = "Audio/Sink"
                node.description = "Kitchen Speakers"
                # Make it selectable in desktop audio controls
                device.description = "Kitchen Speakers"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "kitchen-output"
                target.object = "alsa_output.usb-kitchen-device.analog-stereo"
                node.passive = true
            }
        }
    }
]
```

**Usage**: Applications can select specific room outputs. Based on [dedicated output routing](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#dedicated-output-routing) patterns where WirePlumber automatically manages connections to `target.object` devices.

### Scenario 7: Music Processing Sink {#scenario-7-music-processing-sink}

**Goal**: Create a virtual sink with audio processing capabilities that can automatically receive application audio via WirePlumber routing rules for enhancement and effects.

```bash
# ~/.config/pipewire/pipewire.conf.d/music-processing.conf
context.modules = [
    {
        name = libpipewire-module-loopback
        args = {
            node.description = "Music Processing Sink"
            audio.position = [ FL FR ]
            capture.props = {
                node.name = "music-processing-sink"
                media.class = "Audio/Sink"
                node.description = "Music Processing & Effects"
                # Make it selectable in desktop audio controls
                device.description = "Music Processing & Effects"
                device.class = "sound"
                device.icon-name = "audio-card"
                node.virtual = false
            }
            playback.props = {
                node.name = "music-processing-output"
                node.passive = true
                # Advanced audio processing capabilities
                channelmix.upmix = true
                channelmix.upmix-method = "psd"
                channelmix.stereo-widen = 0.2
                # Will route to default device unless target.object specified
            }
        }
    }
]
```

**Usage**: This virtual sink provides audio enhancement for any application routed to it. The processing includes stereo field widening and intelligent upmixing. Applications can be automatically routed here using [WirePlumber custom routing policies](/resources/wireplumber-session-manager/#advanced-custom-routing-policies) for transparent audio enhancement.

**References**:
- [PipeWire module-loopback channelmix properties](https://docs.pipewire.org/page_module_loopback.html) - Complete audio processing options
- [WirePlumber Session Manager routing rules](/resources/wireplumber-session-manager/#advanced-custom-routing-policies) - How to automatically route applications to this sink

## Managing Virtual Devices

### List All Virtual Devices

```bash
# Show all PipeWire objects including virtual devices
wpctl status

# Filter for virtual devices
pw-cli list-objects | grep -E "(node\.name|node\.description)" | grep -i virtual
```

### Volume Control for Virtual Devices

```bash
# List all sinks/sources with IDs
wpctl status

# Set volume (replace ID with actual device ID)
wpctl set-volume ID 0.5    # 50% volume
wpctl set-volume ID 1.2    # 120% volume (boost)

# Mute/unmute
wpctl set-mute ID toggle
```

## Troubleshooting Virtual Devices

### Common Issues and Solutions

**Virtual device not appearing in applications:**
- Verify configuration syntax: `journalctl --user -u pipewire --since "1 minute ago"`
- Restart PipeWire: `systemctl --user restart pipewire`
- Check device properties: `wpctl status`

**Audio not flowing through virtual device:**
- Verify connections: `wpctl status` and look for stream routing
- Check target.object paths: `wpctl inspect DEVICE_ID`
- Ensure target devices exist and are available

**Virtual device disappears after system restart:**
- Configuration files must be in `~/.config/pipewire/pipewire.conf.d/`
- Check file permissions and syntax
- Monitor startup: `journalctl --user -u pipewire -f`

**Loopback device appears as filter instead of selectable device:**
- Add `device.description`, `device.class = "sound"`, and `node.virtual = false` properties
- See [User-Selectable Virtual Sink Configuration](#user-selectable-virtual-sink-configuration) section

**Exclusive access not working:**
- Verify `node.exclusive = true` and `node.dont-reconnect = true` are both set
- Check that target.object points to the correct hardware device
- Other applications may need to be closed to release hardware access

### Advanced Routing Configuration

For automatic application routing to virtual devices, see the [WirePlumber Session Manager](/resources/wireplumber-session-manager/) guide, which covers:

- **PulseAudio applications** (like Spotify): Require [`pulse.rules`](/resources/wireplumber-session-manager/#pulseaudio-applications-like-spotify) in `~/.config/pipewire/pipewire-pulse.conf.d/`
- **Native PipeWire applications**: Use WirePlumber `stream.rules` in `~/.config/wireplumber/wireplumber.conf.d/`

### Choosing Virtual Device Types

**Primary recommendation for VST processing workflows**: Use **null sinks** ([`support.null-audio-sink`](#create-null-sink-for-vst-chains-primary-method)) for better manual control over processing chains.

**Why null sinks are optimal for VST workflows**:
- **Carla integration**: Carla's patchbay automatically manages all routing once configured
- **Static endpoints**: Perfect for fixed VST processing chains that don't need dynamic routing
- **Manual control**: Precise signal flow control for professional audio processing
- **Monitor ports**: Direct access for VST input without additional complexity

**When to consider loopback devices instead**:
- Simple desktop audio scenarios without VST processing
- When you want WirePlumber to handle all routing automatically
- Dynamic device switching and fallback behavior requirements

**For complete VST processing implementation**: See [PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/) for detailed examples using null sinks with Carla's automatic patchbay routing.

**Important**: While PipeWire supports filter-chains, they are designed for **automatic session manager insertion**, not per-application manual routing. For VST processing workflows, null sinks + Carla patchbay provide the most reliable approach.

---

**Next in this series:** [PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/) - PulseAudio compatibility and application routing

**Related guides:**
- [PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)
- [PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)
- [PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/)