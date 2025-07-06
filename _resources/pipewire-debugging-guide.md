---
layout: page
title: "Part 5: PipeWire Debugging and Diagnostics"
permalink: /resources/pipewire-debugging-guide/
---

# Part 5: PipeWire Debugging and Diagnostics

## Navigation
- **[← Part 4: PipeWire VST Stacks using Carla](../pipewire-vst-carla/)**
- **[Part 1: PipeWire Setup and Fundamentals →](../pipewire-setup-fundamentals/)**

---

## Prerequisites

**Required Reading:**
- [Part 1: PipeWire Setup and Fundamentals](../pipewire-setup-fundamentals/) - Essential understanding of PipeWire architecture
- [Part 2: PipeWire Virtual Devices](../pipewire-virtual-devices/) - Virtual device concepts for debugging scenarios  
- [Part 3: WirePlumber Session Manager](../wireplumber-session-manager/) - Session manager configuration for policy debugging

**System Requirements:**
- Ubuntu 24.04 LTS with PipeWire 1.0.7+
- WirePlumber 0.5.2+ session manager
- Access to PipeWire source repositories for understanding tool implementations

---

## Overview

This guide provides comprehensive debugging and diagnostic techniques for PipeWire audio systems. All debugging utilities referenced include their actual source code locations and implementation details for accurate command usage and understanding of underlying functionality.

**Source Code References:**
- **PipeWire Tools**: [`/home/bashby/projects/misc/pipewire/src/tools/`](https://gitlab.freedesktop.org/pipewire/pipewire/-/tree/master/src/tools)
- **WirePlumber Tools**: [`/home/bashby/projects/misc/wireplumber/src/tools/`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/tree/master/src/tools)

---

## Core Debugging Utilities

### 1. wpctl - WirePlumber Control Interface

**Source Location**: [`/home/bashby/projects/misc/wireplumber/src/tools/wpctl.c`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c)

[`wpctl`](../wireplumber-session-manager/#wpctl-status-commands) is the primary tool for PipeWire system state inspection and control.

#### System Status Overview
```bash
# Complete system status with device hierarchy
wpctl status

# Display device names instead of descriptions  
wpctl status --name

# Display device nicknames (shorter identifiers)
wpctl status --nick
```

**Source Implementation**: [`wpctl.c:403-543`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L403-543) - The [`status_run()`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L403) function demonstrates how WirePlumber queries object managers for complete system state.

#### Object Inspection
```bash
# Detailed object inspection with properties
wpctl inspect 42

# Show referenced objects (linked entities)
wpctl inspect 42 --referenced

# Show associated objects (related entities)  
wpctl inspect 42 --associated
```

**Source Implementation**: [`wpctl.c:787-817`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L787-817) - The [`inspect_run()`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L787) function shows how properties are recursively displayed with association mapping.

#### Volume and Audio State Debugging
```bash
# Get detailed volume information
wpctl get-volume 42

# Volume setting with limits (debugging audio scaling)
wpctl set-volume 42 0.8 --limit 1.0

# Mute state debugging
wpctl set-mute 42 toggle
```

**Source Implementation**: [`wpctl.c:568-615`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L568-615) - The [`get_volume_run()`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L590) function demonstrates mixer API integration for volume state inspection.

### 2. pw-cli - Interactive PipeWire Shell

**Source Location**: [`/home/bashby/projects/misc/pipewire/src/tools/pw-cli.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c)

[`pw-cli`](https://docs.pipewire.org/page_man_pw-cli_1.html) provides low-level PipeWire debugging through an interactive shell interface.

#### Basic Object Inspection
```bash
# Launch interactive shell
pw-cli

# List all objects by type
pw-cli> ls
pw-cli> list-objects

# Get detailed info about specific object
pw-cli> info 42
pw-cli> i 42

# Get info about all objects
pw-cli> info all
```

**Source Implementation**: [`pw-cli.c:271-293`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L271-293) - The [`command_list`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L271) array shows all available debugging commands.

#### Advanced Parameter Debugging
```bash
# Enumerate object parameters
pw-cli> enum-params 42 Props
pw-cli> enum-params 42 Format  
pw-cli> enum-params 42 ProcessLatency

# Set parameters for testing
pw-cli> set-param 42 Props { "node.latency": 1024 }

# Monitor parameter changes in real-time
pw-cli> (monitoring automatically enabled)
```

**Source Implementation**: [`pw-cli.c:1824-1874`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1824-1874) - The [`do_enum_params()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1824) function shows parameter enumeration for detailed debugging.

#### Link Creation and Debugging
```bash
# Create manual links for testing routing
pw-cli> create-link 42 0 43 0

# Create links between all matching ports
pw-cli> create-link 42 "*" 43 "*"

# Destroy objects for testing
pw-cli> destroy 44
```

**Source Implementation**: [`pw-cli.c:1695-1777`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1695-1777) - The [`do_create_link()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1695) function demonstrates complex link creation including wildcard port matching.

### 3. pw-mon - Real-Time Object Monitoring

**Source Location**: [`/home/bashby/projects/misc/pipewire/src/tools/pw-mon.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-mon.c)

[`pw-mon`](https://docs.pipewire.org/page_man_pw-mon_1.html) monitors PipeWire graph changes in real-time, essential for debugging dynamic behavior.

#### Basic Change Monitoring
```bash
# Monitor all object changes
pw-mon

# Monitor with color output for better visibility
pw-mon --color=always

# Hide properties for cleaner output
pw-mon --hide-props

# Hide parameters to focus on structural changes
pw-mon --hide-params
```

**Source Implementation**: [`pw-mon.c:633-686`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-mon.c#L633-686) - The [`registry_event_global()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-mon.c#L633) function shows how objects are tracked and monitored for changes.

#### Focused Debugging Output
```bash
# Monitor specific object types during debugging sessions
pw-mon | grep -E "(Node|Link|Port)"

# Monitor only property changes
pw-mon --hide-params | grep "changed:"

# Monitor node state changes for debugging audio issues
pw-mon | grep -E "(state|error)"
```

**Source Implementation**: [`pw-mon.c:261-308`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-mon.c#L261-308) - The [`print_node()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-mon.c#L261) function demonstrates real-time state monitoring.

### 4. pw-top - Performance Monitoring

**Source Location**: [`/home/bashby/projects/misc/pipewire/src/tools/pw-top.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c)

[`pw-top`](https://docs.pipewire.org/page_man_pw-top_1.html) provides real-time performance monitoring for debugging latency and timing issues.

#### Real-Time Performance Analysis
```bash
# Interactive performance monitoring
pw-top

# Batch mode for logging (5 iterations)
pw-top --batch-mode --iterations=5

# Monitor specific remote PipeWire instance
pw-top --remote=pipewire-1
```

**Source Implementation**: [`pw-top.c:556-610`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L556-610) - The [`do_refresh()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L556) function shows performance data collection and display.

#### Performance Debugging Workflow
```bash
# Reset xrun counters for clean measurements
# (Press 'c' in interactive mode)

# Monitor quantum timing and xruns during audio operations
pw-top
```

**Source Implementation**: [`pw-top.c:619-627`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L619-627) - The [`reset_xruns()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L619) function demonstrates xrun counter management for debugging.

#### Performance Metrics Interpretation
- **WAIT**: Time waiting for signal (should be low)
- **BUSY**: Processing time (should be within quantum)
- **W/Q**: Wait time as percentage of quantum
- **B/Q**: Busy time as percentage of quantum  
- **ERR**: Xrun count (should remain stable)

### 5. pw-dump - System State Export

**Source Location**: [`/home/bashby/projects/misc/pipewire/src/tools/pw-dump.c`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-dump.c)

[`pw-dump`](https://docs.pipewire.org/page_man_pw-dump_1.html) exports complete PipeWire state to JSON for analysis and archival.

#### Complete State Capture
```bash
# Dump all objects to JSON
pw-dump

# Dump specific object by ID
pw-dump 42

# Dump with monitoring for change tracking
pw-dump --monitor

# Raw output without formatting
pw-dump --raw
```

**Source Implementation**: [`pw-dump.c:1444-1479`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-dump.c#L1444-1479) - The [`dump_objects()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-dump.c#L1444) function demonstrates comprehensive state serialization.

#### Filtered Debugging Exports
```bash
# Export only nodes and their properties
pw-dump | jq '.[] | select(.type=="PipeWire:Interface:Node")'

# Export device configurations
pw-dump | jq '.[] | select(.type=="PipeWire:Interface:Device")'

# Monitor mode with specific object filtering
pw-dump --monitor 42
```

---

## Common Debugging Scenarios

### Audio Routing Issues

**Problem**: Audio not reaching intended destination

**Diagnostic Steps:**
```bash
# 1. Verify system status and default devices
wpctl status

# 2. Check object existence and properties
wpctl inspect <source-id>
wpctl inspect <sink-id>

# 3. Monitor routing changes in real-time
pw-mon | grep -E "(Link|Port)"

# 4. Manual link testing
pw-cli
pw-cli> create-link <source-node> <source-port> <sink-node> <sink-port>
```

**Source Reference**: Link creation debugging is implemented in [`pw-cli.c:1695-1777`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1695-1777).

### Performance and Latency Debugging

**Problem**: Audio dropouts, clicks, or high latency

**Diagnostic Steps:**
```bash
# 1. Monitor real-time performance
pw-top

# 2. Check for xruns and timing issues
pw-top --batch-mode --iterations=10 > performance.log

# 3. Verify quantum and rate settings
pw-cli
pw-cli> info all | grep -E "(quantum|rate)"

# 4. Check device buffer configurations
wpctl inspect <device-id> | grep -E "(latency|quantum|rate)"
```

**Source Reference**: Performance monitoring is implemented in [`pw-top.c:629-667`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L629-667) in the [`profiler_profile()`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-top.c#L629) function.

### Device Detection Problems

**Problem**: Audio devices not appearing or functioning

**Diagnostic Steps:**
```bash
# 1. Verify WirePlumber device discovery
wpctl status

# 2. Check device-specific properties
pw-dump | jq '.[] | select(.type=="PipeWire:Interface:Device")'

# 3. Monitor device events
pw-mon | grep -E "(Device|added|removed)"

# 4. Check ALSA/device backend status
pw-cli
pw-cli> info all | grep -E "(alsa|device\.api)"
```

### Virtual Device Configuration Issues

**Problem**: Virtual devices from [Part 2](../pipewire-virtual-devices/) not working properly

**Diagnostic Steps:**
```bash
# 1. Verify loopback module configuration
pw-cli
pw-cli> ls | grep -i loopback

# 2. Check null-audio-sink configuration
wpctl status | grep -i null

# 3. Monitor virtual device parameter changes
pw-mon | grep -E "(loopback|null-audio-sink)"

# 4. Test virtual device routing manually
pw-cli
pw-cli> create-link <virtual-source> 0 <target-sink> 0
```

**Reference**: Virtual device concepts from [Part 2: PipeWire Virtual Devices](../pipewire-virtual-devices/).

### WirePlumber Policy Debugging

**Problem**: Session management or routing policies not working as expected

**Diagnostic Steps:**
```bash
# 1. Check WirePlumber settings and configuration
wpctl settings

# 2. Verify default device assignments
wpctl status | grep "\*"

# 3. Monitor policy decisions
pw-mon | grep -E "(default|policy)"

# 4. Check metadata for policy information
pw-dump | jq '.[] | select(.type=="PipeWire:Interface:Metadata")'
```

**Reference**: WirePlumber configuration from [Part 3: WirePlumber Session Manager](../wireplumber-session-manager/).

---

## Advanced Debugging Techniques

### Parameter Debugging with pw-cli

**Use Case**: Understanding and modifying object parameters

```bash
pw-cli
# Enumerate all available parameters for a node
pw-cli> enum-params 42 Props
pw-cli> enum-params 42 Format
pw-cli> enum-params 42 ProcessLatency

# Modify parameters for testing
pw-cli> set-param 42 Props { "node.pause-on-idle": false }
pw-cli> set-param 42 ProcessLatency { "ns": 10000000 }
```

**Source Reference**: Parameter enumeration is implemented in [`pw-cli.c:1824-1874`](https://gitlab.freedesktop.org/pipewire/pipewire/-/blob/master/src/tools/pw-cli.c#L1824-1874).

### Real-Time Monitoring Workflows

**Use Case**: Debugging dynamic audio routing issues

```bash
# Terminal 1: Monitor object changes
pw-mon --color=always | grep -E "(added|removed|changed)"

# Terminal 2: Monitor performance impact  
pw-top

# Terminal 3: Interactive debugging
pw-cli

# Terminal 4: System status verification
watch -n 1 wpctl status
```

### JSON Analysis for Complex Debugging

**Use Case**: Analyzing complete system state for complex issues

```bash
# Export complete state
pw-dump > system-state.json

# Analyze node relationships
jq '.[] | select(.type=="PipeWire:Interface:Node") | {id, name: .info.props."node.name", state: .info.state}' system-state.json

# Find all links and their endpoints
jq '.[] | select(.type=="PipeWire:Interface:Link") | {id, output_node: .info."output-node-id", input_node: .info."input-node-id", state: .info.state}' system-state.json

# Check device-to-node relationships
jq '.[] | select(.type=="PipeWire:Interface:Node") | {id, device: .info.props."device.id", name: .info.props."node.name"}' system-state.json
```

---

## Configuration Debugging

### PipeWire Configuration Verification

**Check active configuration:**
```bash
# Verify main configuration loading
pw-cli
pw-cli> info 0 | grep -E "(version|name)"

# Check module loading status
pw-cli> ls | grep Module

# Verify configuration directories
ls -la ~/.config/pipewire/
ls -la /etc/pipewire/
```

### WirePlumber Configuration Debugging

**Verify WirePlumber session management:**
```bash
# Check WirePlumber settings
wpctl settings

# Verify default device configuration
wpctl status | grep "Default Configured"

# Check WirePlumber plugin status
pw-cli
pw-cli> ls | grep -i wireplumber
```

**Reference**: WirePlumber configuration details from [Part 3: WirePlumber Session Manager](../wireplumber-session-manager/).

---

## Logging and Diagnostics

### PipeWire Logging Configuration

**Enable debug logging:**
```bash
# Set PipeWire log level
PIPEWIRE_DEBUG=3 pipewire

# Set specific module debug levels
PIPEWIRE_DEBUG=pw.module.*:5 pipewire

# Log to file for analysis
PIPEWIRE_DEBUG=3 pipewire 2> pipewire-debug.log
```

### WirePlumber Logging

**Control WirePlumber logging:**
```bash
# Set WirePlumber log level
wpctl set-log-level 0 4  # Debug level for PipeWire server
wpctl set-log-level 2    # Debug level for WirePlumber

# Reset logging
wpctl set-log-level -    # Reset to default
```

**Source Reference**: Log level control is implemented in [`wpctl.c:1634-1671`](https://gitlab.freedesktop.org/pipewire/wireplumber/-/blob/master/src/tools/wpctl.c#L1634-1671).

---

## Documentation and Further Reading

**Official Documentation:**
- [PipeWire Documentation](https://docs.pipewire.org/)
- [WirePlumber Documentation](https://pipewire.pages.freedesktop.org/wireplumber/)

**Source Code:**
- [PipeWire Source Repository](https://gitlab.freedesktop.org/pipewire/pipewire)
- [WirePlumber Source Repository](https://gitlab.freedesktop.org/pipewire/wireplumber)

**Tool-Specific Man Pages:**
- [`pw-cli(1)`](https://docs.pipewire.org/page_man_pw-cli_1.html)
- [`pw-mon(1)`](https://docs.pipewire.org/page_man_pw-mon_1.html)  
- [`pw-top(1)`](https://docs.pipewire.org/page_man_pw-top_1.html)
- [`pw-dump(1)`](https://docs.pipewire.org/page_man_pw-dump_1.html)
- [`wpctl(1)`](https://pipewire.pages.freedesktop.org/wireplumber/daemon/man/wpctl.1.html)

---

## Navigation
- **[← Part 4: PipeWire VST Stacks using Carla](../pipewire-vst-carla/)**
- **[Part 1: PipeWire Setup and Fundamentals →](../pipewire-setup-fundamentals/)**

---

*This guide provides comprehensive debugging techniques for PipeWire audio systems. All command examples reference actual source code implementations for accurate usage and deeper understanding of the underlying functionality.*