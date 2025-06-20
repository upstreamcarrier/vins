# System Setup Automation Script

## Overview
This script automates initial server configuration on Rocky Linux, handling system updates, package installations, and security configurations with a single execution.

## Features
- **System Updates**: Performs full system updates and installs EPEL repository
- **Development Tools**: Installs essential development packages and Git
- **Timezone Configuration**: Sets system timezone to Europe/London
- **Security Configuration**:
  - Disables SELinux (configures for next boot)
  - Disables and stops firewalld service
- **Smart Reboot Handling**: Ensures only one reboot occurs even if script runs multiple times

## Requirements
- Rocky Linux (RHEL/CentOS compatible)
- Root privileges

## Installation
```bash
Git clone: https://github.com/upstreamcarrier/vins.git
curl -O https://example.com/system_setup.sh
chmod +x system_setup.sh
```
## Usage
```
./system_setup.sh
```
### What It Does
Updates all system packages

Installs:

EPEL repository

Development Tools group

Git and kernel headers

Configures system defaults:

Sets timezone to Europe/London

Disables SELinux (persistent)

Disables firewalld

Manages reboot process:

Creates lock file in /tmp to prevent multiple reboots

Only reboots if needed for SELinux changes
