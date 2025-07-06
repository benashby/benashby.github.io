---
layout: page
title: PipeWire VST Stacks using Carla
description: Complete guide to using VST plugins in PipeWire through Carla plugin host for professional audio processing
permalink: /resources/pipewire-vst-carla/
---

## 📋 PipeWire Audio Guide Series

**🔹 You are here: Part 4 of 4** - Professional audio processing with plugins

### Complete Series:
1. **[PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)** - *Foundation setup and verification*
2. **[PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)** - *Create virtual sinks, sources, and loopbacks*
3. **[PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)** - *PulseAudio compatibility and application routing*
4. **PipeWire VST Stacks using Carla** ← *Professional audio processing with plugins*

### Navigation:
- **Previous:** [PulseAudio Integration](/resources/pipewire-pulseaudio-integration/) - Application routing and compatibility
- **Foundation:** [Setup and Fundamentals](/resources/pipewire-setup-fundamentals/) - Start here if new
- **Virtual Devices:** [Virtual Devices](/resources/pipewire-virtual-devices/) - Required for advanced routing

---

## Prerequisites

Before working with VST plugins in PipeWire, you should complete these prerequisite guides:

1. **[PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)** - Essential foundation
2. **[PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)** - Virtual device concepts and implementation
3. **[PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)** - Application routing and configuration

You should have:

- PipeWire 1.0.7+ and WirePlumber 0.5.2+ installed and verified
- All compatibility layers working (ALSA, JACK, PulseAudio)
- Understanding of virtual devices and PulseAudio application routing
- Experience with audio processing concepts

## What is Carla?

[Carla](https://kx.studio/Applications:Carla) is a fully-featured audio plugin host that acts as a bridge between VST plugins and Linux audio systems. It provides:

- **VST2/VST3 Support**: Load Windows and Linux VST plugins
- **Multiple Plugin Formats**: VST, LV2, LADSPA, AU (on macOS), and internal plugins
- **JACK Integration**: Native JACK support for low-latency audio
- **PipeWire Compatibility**: Works seamlessly with PipeWire's JACK compatibility layer
- **Plugin Chains**: Create complex effect chains and instrument racks

## Installation

### Option 1: KXStudio Repository (Recommended)

The **KXStudio repository** by falktx (Carla's author) provides the most up-to-date packages with latest features and bug fixes:

```bash
# Add KXStudio repository
sudo apt update
sudo apt install gpgv wget

# Download package file
wget https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.2.0_all.deb

# Install it
sudo dpkg -i kxstudio-repos_11.2.0_all.deb

# Update package lists
sudo apt update

# Install latest Carla from KXStudio
sudo apt install carla carla-data carla-lv2 carla-vst

# Check installation
carla --version
```

**What you get:**
- **Latest stable Carla versions** (currently 2.5.9+, with development versions 2.6.0+)
- **Complete plugin format support** (VST2, VST3, LV2, LADSPA, AU)
- **KXStudio-optimized builds** with additional features
- **Regular updates** from the official Carla maintainer

### Option 2: Ubuntu Default Repositories

For basic functionality with older but stable versions:

```bash
# Ubuntu/Debian default repositories
sudo apt install carla carla-data

# Check installation
carla --version
```

### Verification

```bash
# Check installed version
carla --version

# Verify PipeWire compatibility
pw-jack carla --help

# Check available plugin formats
carla-discovery native
```

**References:**
- [KXStudio Official Site](https://kx.studio/)
- [Carla GitHub Repository](https://github.com/falkTX/Carla)
- [KXStudio Applications PPA](https://launchpad.net/~kxstudio-debian/+archive/ubuntu/apps)

### VST Plugin Support

*Content to be added: VST plugin installation and configuration*

## Basic Usage

Carla integrates with PipeWire through the [`pipewire-jack`](https://docs.pipewire.org/page_module_jack_tunnel.html) compatibility layer, appearing as JACK clients in the PipeWire audio graph.

### Core Workflow

1. **Launch Carla**: [`carla`](https://kx.studio/Applications:Carla) starts and connects to PipeWire via JACK compatibility
2. **Add VST Plugins**: Load VST2/VST3 plugins using the "Add Plugin" toolbar button
3. **Create Plugin Stacks**: Chain multiple effects/instruments in Rack mode for serial processing
4. **Audio Routing**: Carla appears in [`wpctl status`](/resources/pipewire-setup-fundamentals/#understanding-wpctl-status-output) as audio streams for manual or automatic routing

### PipeWire Integration

```bash
# Launch Carla with explicit JACK compatibility
pw-jack carla

# Monitor Carla's PipeWire presence
wpctl status | grep -i carla
```

**How it works:**
- **Carla as JACK client**: Uses PipeWire's [`libpipewire-module-jack-tunnel`](https://docs.pipewire.org/page_module_jack_tunnel.html) for audio routing
- **Manual patchbay control**: Best approach for VST processing chains with precise signal flow control
- **Virtual device integration**: Can route to/from [PipeWire virtual devices](/resources/pipewire-virtual-devices/) for complex audio workflows

### Plugin Stack Concept

VST plugins in Carla create **processing chains** where audio flows through multiple effects sequentially. The entire stack appears to PipeWire as a single audio processing node, allowing complex VST setups to integrate seamlessly with [virtual sinks and sources](/resources/pipewire-virtual-devices/#types-of-virtual-devices).

**References:**
- [PipeWire JACK compatibility documentation](https://docs.pipewire.org/page_module_jack_tunnel.html)
- [Carla official documentation](https://kx.studio/Applications:Carla)
- [PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)

## Creating VST Processing Chains

This section demonstrates how to create VST processing chains using Carla and integrate them into PipeWire's audio routing system. We'll use the practical example from our debugging session of routing Spotify audio through Carla VST processing before it reaches your Schiit Modi DAC.

### Architecture Overview

Based on our testing, the most effective approach for VST processing chains uses [`support.null-audio-sink`](https://docs.pipewire.org/page_module_adapter.html) for better manual control over VST processing connections. The audio flow looks like this:

```
Spotify → Virtual Null Sink → Monitor Ports → Carla (VST) → Hardware DAC (via patchbay)
```

**Why null sinks for VST workflows**: From our debugging session, null sinks provide **better fit for what you're trying to do** with cleaner manual routing control for VST processing chains. Unlike loopback devices which rely on WirePlumber's automatic routing, null sinks give you precise control over the signal flow through your VST stack.

### Step 1: Create a Null Sink Virtual Device

Create a [`support.null-audio-sink`](/home/bashby/projects/misc/pipewire/src/modules/module-adapter.c) device optimized for VST processing workflows:

```bash
# ~/.config/pipewire/pipewire.conf.d/11-music-null-sink.conf
context.objects = [
    {
        factory = adapter
        args = {
            factory.name = support.null-audio-sink
            node.name = "music-null-sink"
            node.description = "Music Virtual Sink"
            media.class = Audio/Sink
            audio.position = [ FL FR ]
            # Desktop integration properties for user selection
            device.description = "Music Virtual Sink"
            device.class = "sound"
            device.icon-name = "audio-card"
            node.virtual = false
            # Monitor configuration for VST routing
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

Apply the configuration:
```bash
systemctl --user restart pipewire
```

Verify the null sink appears:
```bash
wpctl status | grep -i music
# Should show the null sink and its monitor ports
```

**What this creates**:
- **`music-null-sink`**: Virtual sink that applications like Spotify connect to (appears in desktop audio controls)
- **Monitor ports**: `music-null-sink:monitor_FL` and `music-null-sink:monitor_FR` for routing to Carla

### Step 2: Configure Carla Engine

Launch [`carla`](https://kx.studio/Applications:Carla) and configure it for PipeWire integration:

1. **Set Audio Driver**: Go to *Settings > Configure Carla > Engine*
2. **Select JACK**: Set *Audio driver* to *JACK* (uses [`pipewire-jack`](https://docs.pipewire.org/page_module_jack_tunnel.html) compatibility layer)
3. **Choose Process Mode**: Select *Continuous Rack* for serial plugin processing

Alternatively, launch directly in Rack mode:
```bash
pw-jack carla-rack
```

**Engine Settings Reference**: Based on [Carla's process modes](https://kx.studio/ns/dev-docs/CarlaBackend/group__CarlaBackendAPI.html#gaec3a1d85b80c5211a443b7afb3306ea6):
- **Continuous Rack**: Plugins process in order, top to bottom (ideal for EQ chains)
- **Patchbay**: Full modular routing (for complex setups)

### Step 3: Build Your VST Chain

In Carla's *Rack* tab, add your VST plugins:

1. **Add Equalizer**: Click "Add Plugin" → Select your EQ VST (e.g., EQual, ReaEQ)
2. **Plugin Order**: Arrange plugins from top to bottom in processing order
3. **Configure Settings**: Adjust EQ bands, frequencies, and gain as desired

**Plugin Chain Example** (top to bottom processing order):
```
1. High-pass filter (remove low-end rumble)
2. Parametric EQ (shape frequency response)
3. Compressor (optional - dynamic control)
```

### Step 4: Audio Routing in Patchbay

Switch to Carla's *Patchbay* tab to create the manual connections for your VST processing chain:

#### Connect Null Sink Monitor to Carla Input
1. **Locate Monitor Ports**: Find `music-null-sink:monitor_FL` and `music-null-sink:monitor_FR` in the available connections
2. **Connect to Carla**: Route monitor outputs to Carla's audio inputs:
   ```
   music-null-sink:monitor_FL → Carla:input_FL
   music-null-sink:monitor_FR → Carla:input_FR
   ```
3. **Verify Signal Flow**: Audio flows: Spotify → Null Sink → Monitor → Carla VST processing

#### Connect Carla Output to Hardware DAC
1. **Locate Carla Outputs**: Find Carla's processed audio outputs
2. **Route to Hardware**: Connect directly to your Schiit Modi DAC outputs:
   ```
   Carla:output_FL → alsa_output.usb-Schiit_Modi_3-00.analog-stereo:playback_FL
   Carla:output_FR → alsa_output.usb-Schiit_Modi_3-00.analog-stereo:playback_FR
   ```
3. **Save Configuration**: Create config directory and save project:
   ```bash
   mkdir -p ~/.local/share/carla
   ```
   *File > Save As* → Save as `~/.local/share/carla/spotify_vst_chain.carxp`

**Connection Pattern** (manual VST processing control):
```
music-null-sink:monitor_FL → Carla:input_FL
music-null-sink:monitor_FR → Carla:input_FR
Carla:output_FL → Schiit_Modi:playback_FL
Carla:output_FR → Schiit_Modi:playback_FR
```

**Why This Approach Works**: From our debugging session, this null sink approach provides **"better fit for what you're trying to do"** with cleaner manual routing control for VST processing chains. You have precise control over the signal flow through your VST stack and directly to your preferred DAC.

### Step 5: Route Spotify to Processing Chain

**Critical**: Spotify connects via PulseAudio compatibility layer and requires [`pulse.rules`](/resources/pipewire-pulseaudio-integration/#pulse-rules-section) configuration, not WirePlumber stream rules.

#### Automatic Routing for PulseAudio Applications

Create a PulseAudio routing rule that automatically sends Spotify to your null sink:

```bash
# ~/.config/pipewire/pipewire-pulse.conf.d/custom.conf
pulse.rules = [
  {
    matches = [
      { application.name = "Spotify" }
    ]
    actions = {
      update-props = {
        target.object = "music-null-sink"
      }
    }
  }
]
```

Apply the configuration:
```bash
systemctl --user restart pipewire
```

**Why this approach is needed**: From our debugging session, applications that connect via `pipewire-pulse` (like Spotify) bypass WirePlumber's normal stream routing and require their own [`pulse.rules`](https://docs.pipewire.org/page_module_pulse_server.html) configuration.

**Audio Flow Verification**: The complete processing chain should be:
1. **Spotify** → `music-null-sink` (via pulse.rules)
2. **Null sink monitor** → **Carla VST processing** (manual patchbay connection)
3. **Carla output** → **Schiit Modi DAC** (manual patchbay connection)

**Testing the routing**: After restart, launch Spotify and verify:
```bash
wpctl status | grep -i spotify
# Should show Spotify connected to music-null-sink
```

### Step 6: Autostart Carla Processing

For persistent operation, create a systemd service to auto-load your VST chain:

```bash
# ~/.config/systemd/user/carla-vst-chain.service
[Unit]
Description=Carla VST Processing Chain
After=pipewire.service

[Service]
Environment=PIPEWIRE_LINK_PASSIVE=true
Type=exec
ExecStart=/usr/bin/pw-jack carla-rack --no-gui %h/.local/share/carla/spotify_vst_chain.carxp

[Install]
WantedBy=default.target
```

Enable the service:
```bash
systemctl --user enable --now carla-vst-chain.service
```

**Verify the service is working:**
```bash
# Check service status
systemctl --user status carla-vst-chain.service

# Monitor Carla's connection to PipeWire
wpctl status | grep -i carla
```

**Final Testing**: With everything configured, the complete audio chain should be:
1. Launch Spotify → automatically routes to `music-null-sink`
2. Carla loads VST processing chain → processes audio from null sink monitor
3. Processed audio → routed directly to Schiit Modi DAC
4. Enjoy enhanced audio with VST processing applied to Spotify


---

**Related guides**:
- [PipeWire Setup and Fundamentals](/resources/pipewire-setup-fundamentals/)
- [PipeWire Virtual Devices](/resources/pipewire-virtual-devices/)
- [PipeWire PulseAudio Integration](/resources/pipewire-pulseaudio-integration/)

---