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

Absolutely\! Here's a README-style guide in Markdown format based on the commands you provided, explaining how to set up the `vins` repository.

-----

# VINS Repository Setup Guide

This guide will walk you through the process of cloning the `vins` repository and preparing it for initial setup.

-----

## Prerequisites

Before you begin, ensure you have **Git** installed on your system. If not, you can usually install it using your distribution's package manager (e.g., `sudo yum install git` on CentOS/RHEL or `sudo apt install git` on Debian/Ubuntu).

-----

## Setup Steps

Follow these steps to get started with the `vins` repository:

### Step 1: Clone the Repository

First, you need to clone the `vins` repository from GitHub to your local machine.

```bash
git clone https://github.com/upstreamcarrier/vins.git
```

This command will create a new directory named `vins` in your current location, containing all the project files.

### Step 2: Navigate into the Repository Directory

Once the repository is cloned, change your current directory to the newly created `vins` directory:

```bash
cd vins/
```

### Step 3: Make the Setup Script Executable

The `initial-setup.sh` script needs executable permissions to run. Grant these permissions using the `chmod` command:

```bash
chmod +x initial-setup.sh
```

### Step 4: Run the Initial Setup Script

Finally, execute the `initial-setup.sh` script to perform the initial setup tasks for the `vins` project.

```bash
./initial-setup.sh
```

-----

## What's Next?

After running `initial-setup.sh`, you should refer to the other files in the repository (e.g., `README.md`, `system.conf`, `httpd.conf`, `my.cnf`) for further configuration and understanding of the project's requirements and functionalities. The `initial-setup.sh` script likely configures your system based on these files.

-----

Feel free to ask if you have any more questions or need further assistance with the `vins` repository\!

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
