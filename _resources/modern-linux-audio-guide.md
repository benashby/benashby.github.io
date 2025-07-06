---
layout: page
title: Modern Linux Audio Guide
description: A comprehensive guide to understanding and configuring audio on modern Linux systems
permalink: /resources/modern-linux-audio-guide/
---

# Modern Linux Audio Guide

*Last updated: {{ page.last_modified_at | date: "%B %d, %Y" }}*

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
*Audio processing modules - usually empty until configured*

We'll cover this extensively later when setting up **Carla** for VST plugin support, so for now just note that this section is typically empty:

```text
├─ Filters:
│
```

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
wireplumber --version
```


---

*This guide is a work in progress. Check back regularly for updates.*
