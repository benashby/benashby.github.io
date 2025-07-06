---
layout: page
title: PipeWire PulseAudio Integration
description: Complete guide to PipeWire's PulseAudio compatibility layer - configuration, routing, and application-specific optimizations
permalink: /resources/pipewire-pulseaudio-integration/
---

## 📋 PipeWire Audio Guide Series

**🔹 You are here: Part 3 of 4** - PulseAudio compatibility and application routing

### Complete Series:
1. **[PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)** - *Foundation setup and verification*
2. **[PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)** - *Create virtual sinks, sources, and loopbacks*
3. **PipeWire PulseAudio Integration** ← *PulseAudio compatibility and application routing*
4. **[PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/)** - *Professional audio processing with plugins*

### Navigation:
- **Previous:** [Virtual Devices](/resources/pipewire-virtual-devices/) - Creating virtual audio endpoints
- **Next:** [VST/Carla](/resources/pipewire-vst-carla/) - Professional audio processing

---

## Prerequisites

This guide assumes you have completed:
- [PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/) - PipeWire installation and verification
- [PipeWire Virtual Devices](/resources/pipewire-virtual-devices/) - Virtual device creation (recommended)

## PulseAudio Integration and Configuration

PipeWire includes a complete PulseAudio server implementation via [`libpipewire-module-protocol-pulse`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L21-28), providing high compatibility with existing PulseAudio applications. This section covers comprehensive configuration and routing for applications that use the PulseAudio API.

### How PulseAudio Integration Works

Based on the [`module-protocol-pulse.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L21-35) implementation:

**Server Implementation**:
- **Complete PulseAudio server**: Full PA protocol compatibility on top of PipeWire
- **Client library compatibility**: Existing applications use the original PulseAudio client library unchanged
- **Tool compatibility**: `pavucontrol`, `pactl`, `pamon`, `paplay` work normally
- **Sample cache**: Implements PA sample cache functionality not available in native PipeWire

**Process Architecture**:
- **Standalone process**: Usually runs as `pipewire-pulse` with `pipewire-pulse.conf` config
- **Protocol translation**: Converts PulseAudio API calls to PipeWire operations
- **Stream management**: PA streams become PipeWire streams with automatic routing

### Configuration File Structure

PulseAudio configuration uses a hierarchical file system based on [`pipewire-pulse.conf.5.md`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/doc/dox/config/pipewire-pulse.conf.5.md#L9-19):

**Configuration Locations** (in order of precedence):
```
$XDG_CONFIG_HOME/pipewire/pipewire-pulse.conf.d/     # User overrides (highest priority)
$XDG_CONFIG_HOME/pipewire/pipewire-pulse.conf        # User main config
$(PIPEWIRE_CONFIG_DIR)/pipewire-pulse.conf.d/        # System overrides  
$(PIPEWIRE_CONFIG_DIR)/pipewire-pulse.conf           # System main config
$(PIPEWIRE_CONFDATADIR)/pipewire-pulse.conf.d/       # Distribution overrides
$(PIPEWIRE_CONFDATADIR)/pipewire-pulse.conf          # Distribution defaults (lowest priority)
```

**Recommended approach**: Use drop-in files in `~/.config/pipewire/pipewire-pulse.conf.d/` for user customizations.

### Complete Configuration Sections Reference

Based on [`pipewire-pulse.conf.5.md`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/doc/dox/config/pipewire-pulse.conf.5.md#L30-56) source analysis:

#### stream.properties Section

**Purpose**: Configure streams created by the PipeWire PulseAudio server
**Required**: No - uses PipeWire defaults if not specified

Reference: [`pipewire-pulse.conf.5.md:59-63`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/doc/dox/config/pipewire-pulse.conf.5.md#L59-63)

**Available Properties** (from [`pipewire-pulse.conf.5.md:76-100`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/doc/dox/config/pipewire-pulse.conf.5.md#L76-100)):

| Property | Description | Default | Optional | Example Values |
|----------|-------------|---------|----------|----------------|
| `node.latency` | Target latency for streams, expressed as `samples/rate`. For playback, this is derived from buffer attributes (`tlength`, `minreq`). For capture, it's based on `fragsize`. **Note**: This property is deprecated; use `stream.latency` for new configurations. | Auto-calculated | ✅ | `1024/48000` (21ms), `512/48000` (10ms) |
| `node.autoconnect` | Auto-connect streams to devices | `true` | ✅ | `true`, `false` |
| `resample.disable` | Disable automatic resampling | `false` | ✅ | `true`, `false` |
| `resample.quality` | Resampling algorithm quality | `4` | ✅ | `0`-`10` (higher = better quality) |
| `channelmix.disable` | Disable channel mixing | `false` | ✅ | `true`, `false` |
| `channelmix.normalize` | Normalize volume during mixing | `false` | ✅ | `true`, `false` |
| `channelmix.mix-lfe` | Include LFE in channel mixing | `true` | ✅ | `true`, `false` |
| `channelmix.upmix` | Enable stereo to surround upmixing | `true` | ✅ | `true`, `false` |
| `channelmix.upmix-method` | Upmixing algorithm | `psd` | ✅ | `none`, `simple`, `psd` |
| `channelmix.lfe-cutoff` | LFE crossover frequency (Hz) | `150.0` | ✅ | `80.0`, `120.0`, `200.0` |
| `channelmix.fc-cutoff` | Front center cutoff (Hz) | `12000.0` | ✅ | `8000.0`, `15000.0` |
| `channelmix.rear-delay` | Rear channel delay (ms) | `12.0` | ✅ | `0.0`, `15.0`, `20.0` |
| `channelmix.stereo-widen` | Stereo field widening | `0.0` | ✅ | `0.0`-`1.0` (0=none, 1=max) |
| `channelmix.hilbert-taps` | Rear channel phase shift taps | `0` | ✅ | `0` (off), `63`, `127` |
| `dither.noise` | Dithering noise level | `0` | ✅ | `0` (off), `1` (triangular) |
| `dither.method` | Dithering algorithm | `none` | ✅ | `rectangular`, `triangular`, `shaped5` |

**PulseAudio Compatibility Mapping** (from [`pipewire-pulse.conf.5.md:65-72`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/doc/dox/config/pipewire-pulse.conf.5.md#L65-72)):

| PulseAudio Setting | PipeWire Property | Notes |
|-------------------|-------------------|-------|
| `remixing-use-all-sink-channels` | `channelmix.upmix` | Direct mapping |
| `remixing-produce-lfe` | `channelmix.lfe-cutoff` | Set > 0 to enable |
| `remixing-consume-lfe` | `channelmix.mix-lfe` | Direct mapping |
| `lfe-crossover-freq` | `channelmix.lfe-cutoff` | Frequency in Hz |

#### pulse.properties Section

**Purpose**: Configure the PulseAudio server behavior
**Required**: No - uses built-in defaults

Reference: [`module-protocol-pulse.c:46-91`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L46-91)

**Connection Properties**:

| Property | Description | Default | Optional | Example Values | Source Reference |
|----------|-------------|---------|----------|----------------|------------------|
| [`server.address`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L54-66) | Server listening addresses | `["unix:native"]` | ✅ | Array of connection strings | [Line 54-66](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L54-66) |
| [`server.dbus-name`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L68) | DBus service name | `"org.pulseaudio.Server"` | ✅ | Custom DBus name for multiple servers | [Line 68](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L68) |
| [`pulse.allow-module-loading`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L69) | Allow clients to load/unload modules | `true` | ✅ | `true`, `false` | [Line 69](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L69) |

**Connection Address Examples** (from [`module-protocol-pulse.c:54-66`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L54-66)):
```javascript
server.address = [
    "unix:native"                          # Default Unix socket
    "tcp:4713"                            # IPv4/IPv6 on all addresses  
    "tcp:[::]:9999"                       # IPv6 specific on all addresses
    "tcp:127.0.0.1:8888"                  # IPv4 on specific address
    # Extended syntax with additional options:
    { address = "tcp:4713"                # Connection address
      max-clients = 64                    # Maximum concurrent clients
      listen-backlog = 32                 # Server listen queue size  
      client.access = "restricted" }      # Client permission level
]
```

**Buffering Properties** (from [`module-protocol-pulse.c:70-87`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L70-87)):

| Property | Description | Default | Optional | Example Values | Source Reference |
|----------|-------------|---------|----------|----------------|------------------|
| [`pulse.min.req`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L70) | Minimum request size for playback | `128/48000` (2.7ms) | ✅ | `256/48000`, `512/48000` | [Line 70](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L70) |
| [`pulse.default.req`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L71) | Default request size | `960/48000` (20ms) | ✅ | `480/48000`, `1920/48000` | [Line 71](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L71) |
| [`pulse.min.frag`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L72) | Minimum fragment size for capture | `128/48000` (2.7ms) | ✅ | `256/48000`, `512/48000` | [Line 72](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L72) |
| [`pulse.default.frag`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L73) | Default fragment size | `96000/48000` (2s) | ✅ | `48000/48000`, `192000/48000` | [Line 73](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L73) |
| [`pulse.default.tlength`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L74) | Target buffer length | `96000/48000` (2s) | ✅ | `48000/48000`, `144000/48000` | [Line 74](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L74) |
| [`pulse.min.quantum`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L75) | Minimum quantum size | `128/48000` (2.7ms) | ✅ | `256/48000`, `1024/48000` | [Line 75](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L75) |

**Format Properties** (from [`module-protocol-pulse.c:76-78`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L76-78)):

| Property | Description | Default | Optional | Example Values | Source Reference |
|----------|-------------|---------|----------|----------------|------------------|
| [`pulse.default.format`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L76) | Default sample format | `F32` | ✅ | `F32`, `S16`, `S24`, `S32` | [Line 76](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L76) |
| [`pulse.default.position`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L77) | Default channel layout | `[ FL FR ]` | ✅ | `[ FL FR ]`, `[ FL FR FC LFE RL RR ]` | [Line 77](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L77) |

**Quirk Properties** (from [`module-protocol-pulse.c:217-242`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L217-242)):

| Property | Description | Default | Optional | Example Values | Source Reference |
|----------|-------------|---------|----------|----------------|------------------|
| [`pulse.fix.format`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L217) | Force format for FIX_FORMAT streams | None | ✅ | `"S16LE"`, `"F32LE"` | [Line 217-222](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L217-222) |
| [`pulse.fix.rate`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L225) | Force rate for FIX_RATE streams | None | ✅ | `48000`, `44100` | [Line 225-230](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L225-230) |
| [`pulse.fix.position`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L233) | Force channels for FIX_CHANNELS streams | None | ✅ | `"[ FL FR ]"`, `"[ MONO ]"` | [Line 233-238](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L233-238) |
| [`pulse.idle.timeout`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L241) | Auto-pause underrunning clients (seconds) | `0` (disabled) | ✅ | `5`, `10`, `0` (off) | [Line 241-248](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L241-248) |

#### pulse.rules Section

**Purpose**: Apply rules and quirks to specific PulseAudio applications
**Required**: No - no rules applied if not specified

Reference: [`module-protocol-pulse.c:300-329`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L300-329)

**Rule Structure**:
```javascript
pulse.rules = [
    {
        matches = [ { property.name = "value" } ]    # Application matching
        actions = { 
            quirks = [ "quirk-name" ]                # Apply behavior quirks
            update-props = { property = value }      # Override client properties
        }
    }
]
```

**Available Quirks** (from [`module-protocol-pulse.c:332-346`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L332-346)):

| Quirk | Description | Use Case | Source Reference |
|-------|-------------|----------|------------------|
| [`force-s16-info`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L335) | Pretend device uses S16 format | Apps that refuse non-S16 devices | [Line 335-337](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L335-337) |
| [`remove-capture-dont-move`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L338) | Remove DONT_MOVE flag from capture streams | Allow moving "locked" streams | [Line 338-340](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L338-340) |
| [`block-source-volume`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L341) | Block client from changing source volumes | Disable automatic gain control | [Line 341-342](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L341-342) |
| [`block-sink-volume`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L343) | Block client from changing sink volumes | Prevent volume override | [Line 343](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L343) |
| [`block-record-stream`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L344) | Block client from creating record streams | Disable recording capability | [Line 344](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L344) |
| [`block-playback-stream`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L345) | Block client from creating playback streams | Disable playback capability | [Line 345](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L345) |

#### pulse.cmd Section

**Purpose**: Execute commands during PulseAudio server startup
**Required**: No - no commands executed if not specified

Reference: [`module-protocol-pulse.c:251-267`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L251-267)

**Available Commands**:

| Command | Description | Arguments | Optional Flags | Source Reference |
|---------|-------------|-----------|----------------|------------------|
| [`load-module`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L176) | Load PulseAudio module | `"module-name module-args"` | `["nofail"]` | [Line 176-178](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c#L176-178) |

### Real-World PulseAudio Configuration Examples

#### Example 1: Desktop Content Creation Setup

Based on typical content creation configuration patterns:

```javascript
# ~/.config/pipewire/pipewire-pulse.conf.d/desktop-content-creation.conf

# Optimize stream properties for content creation
stream.properties = {
    # Lower latency for real-time work
    node.latency = 512/48000              # 10.7ms - good balance for content creation
    resample.disable = false              # Enable resampling - needed when mixing sources with different sample rates
    resample.quality = 6                  # Higher quality resampling (vs default 4)
    
    # Audio processing optimized for mixing multiple sources
    channelmix.disable = false            # Enable mixing capabilities
    channelmix.normalize = true           # Prevent clipping when mixing
    channelmix.mix-lfe = false           # Preserve LFE channel integrity
    monitor.channel-volumes = true        # Per-channel control for monitoring
}

# Route specific applications to virtual devices for processing
pulse.rules = [
    {
        # Route Spotify to music processing sink for EQ/effects
        matches = [ { application.process.binary = "spotify" } ]
        actions = {
            update-props = {
                target.object = "music-null-sink"    # References null sink node.name
            }
        }
    }
    {
        # Fix Teams audio format issues  
        matches = [
            { application.process.binary = "teams" }
            { application.process.binary = "teams-insiders" }
        ]
        actions = { 
            quirks = [ "force-s16-info" ]            # Teams requires S16 format reporting
        }
    }
    {
        # Give OBS exclusive microphone access for streaming
        matches = [ { application.process.binary = "obs" } ]
        actions = {
            update-props = {
                pulse.min.req = 256/48000            # 5.3ms - lower latency for streaming
                pulse.min.quantum = 256/48000
            }
        }
    }
]
```

#### Example 2: Gaming and Communication Setup

```javascript
# ~/.config/pipewire/pipewire-pulse.conf.d/gaming-communications.conf

# Optimized for low-latency gaming and voice chat
stream.properties = {
    node.latency = 256/48000              # 5.3ms - ultra-low latency for gaming
    resample.quality = 2                  # Lower quality but faster processing
    channelmix.upmix = true              # Games benefit from surround upmixing
    channelmix.upmix-method = "simple"   # Fast upmixing algorithm
    channelmix.rear-delay = 8.0          # Shorter delay for responsive gaming
}

pulse.rules = [
    {
        # Route games to dedicated gaming sink with surround processing
        matches = [
            { application.process.binary = "~.*game.*" }
            { application.process.binary = "steam" }
            { application.name = "~.*Counter-Strike.*" }
        ]
        actions = {
            update-props = {
                target.object = "game-audio-sink"
                pulse.min.quantum = 128/48000    # Ultra-low latency for competitive gaming
            }
        }
    }
    {
        # Route voice chat to separate device with echo cancellation
        matches = [
            { application.process.binary = "discord" }
            { application.process.binary = "teamspeak3" }
            { application.name = "~.*Voice.*" }
        ]
        actions = {
            update-props = {
                target.object = "voice-chat-sink"
                pulse.min.req = 512/48000        # Balanced latency for voice quality
            }
        }
    }
    {
        # Block microphone access from games (prevent accidental voice leaks)
        matches = [
            { application.process.binary = "~.*game.*" }
            { application.name = "~.*Steam.*" }
        ]
        actions = { 
            quirks = [ "block-record-stream" ]   # Disable microphone for games
        }
    }
]
```

#### Example 3: Professional Audio Production

```javascript
# ~/.config/pipewire/pipewire-pulse.conf.d/professional-audio.conf

pulse.properties = {
    # Pro audio interface usually requires specific settings
    pulse.min.req = 64/48000              # 1.3ms - professional low latency
    pulse.default.req = 128/48000         # 2.7ms default
    pulse.min.quantum = 64/48000          # Match JACK workflows
    pulse.default.format = F32            # 32-bit float for maximum quality
    pulse.idle.timeout = 0                # Never pause streams in pro environment
}

stream.properties = {
    node.latency = 64/48000               # Ultra-low latency
    resample.disable = true               # No resampling in pro workflows  
    resample.quality = 10                 # Maximum quality if resampling needed
    channelmix.disable = true             # Preserve exact channel routing
    dither.method = "triangular"          # Professional dithering
    monitor.channel-volumes = true        # Detailed monitoring control
}

pulse.rules = [
    {
        # DAW applications get ultra-low latency settings
        matches = [
            { application.process.binary = "ardour" }
            { application.process.binary = "reaper" }
            { application.process.binary = "bitwig-studio" }
        ]
        actions = {
            update-props = {
                pulse.min.req = 32/48000          # 0.67ms - extreme low latency
                pulse.min.quantum = 32/48000      # Match req for consistent timing
            }
        }
    }
    {
        # Prevent consumer apps from disrupting pro workflow
        matches = [
            { application.process.binary = "firefox" }
            { application.process.binary = "chrome" }
            { media.role = "Notification" }
        ]
        actions = {
            update-props = {
                target.object = "consumer-audio-sink"   # Route to separate device
                pulse.min.quantum = 1024/48000          # Higher latency for efficiency
            }
        }
    }
]
```

### PulseAudio Routing Behavior

#### Stream Routing Priority

Based on [`module-protocol-pulse.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c) implementation, PulseAudio applications route in this order:

1. **Explicit target.object**: If pulse.rules specifies `target.object = "device-name"`
2. **Application preference**: If app specifies a preferred device 
3. **WirePlumber default**: Session manager assigns based on policy
4. **System default**: Fallback to system default audio device

#### Integration with Virtual Devices

**Null Sinks**: PulseAudio applications can target null sinks created with [`support.null-audio-sink`](/resources/pipewire-virtual-devices/#create-null-sink-for-vst-chains-primary-method):
```javascript
# Route PulseAudio app to null sink for VST processing
pulse.rules = [
    {
        matches = [ { application.process.binary = "spotify" } ]
        actions = {
            update-props = {
                target.object = "music-vst-sink"    # References node.name from null sink config
            }
        }
    }
]
```

**Loopback Devices**: PulseAudio applications see loopback sinks as regular selectable devices when configured with proper [`device.description`](/resources/pipewire-virtual-devices/#alternative-loopback-devices-for-automatic-integration) properties.

### Configuration Validation and Troubleshooting

**Check configuration syntax**:
```bash
# Test configuration without applying
pipewire-pulse --version  # Should complete quickly if config is valid

# View PulseAudio server startup logs
journalctl --user -u pipewire-pulse --since "1 minute ago"
```

**Verify PulseAudio application routing**:
```bash
# List all PulseAudio streams and their routing
pactl list short sink-inputs
pactl list short source-outputs

# Monitor real-time stream changes
pactl subscribe
```

**Debug pulse.rules matching**:
```bash
# Show application properties that pulse.rules can match on
wpctl inspect STREAM_ID | grep -E "(application\.|media\.)"

# Example output shows matchable properties:
# * application.process.binary = "spotify"  
# * application.name = "Spotify"
# * media.role = "Music"
```

**Common Issues**:
- **Rules not applying**: Check application property matching with exact binary names
- **Device not found**: Verify `target.object` matches exact `node.name` from virtual device
- **Routing conflicts**: Higher priority rules override lower priority ones
- **Latency issues**: Balance `pulse.min.quantum` vs `pulse.min.req` for your workflow

**References**:
- [PipeWire PulseAudio Protocol Module](https://docs.pipewire.org/page_module_protocol_pulse.html) - Complete module documentation
- [pipewire-pulse.conf(5)](https://docs.pipewire.org/page_man_pipewire-pulse_conf_5.html) - Configuration file reference  
- [`module-protocol-pulse.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/modules/module-protocol-pulse.c) - Implementation source code

---

**Next in this series:** [PipeWire VST Stacks using Carla](/resources/pipewire-vst-carla/) - Professional audio processing with plugins

**Related guides:**
- [PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)
- [PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)