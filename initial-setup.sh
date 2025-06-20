#!/bin/bash

# Reboot flag file (ensures reboot happens only once)
REBOOT_FLAG="/tmp/system_setup_reboot_done"

# Check if reboot was already done
if [ -f "$REBOOT_FLAG" ]; then
    echo "Reboot was already done. Skipping further reboots."
    exit 0
fi

# 1. System Updates
echo "Updating system packages..."
yum check-update -y
yum update -y
yum -y install epel-release
yum update -y

# 2. Install Development Tools & Dependencies
echo "Installing Development Tools, Git, and Nano..."
yum groupinstall 'Development Tools' -y
yum install git nano -y
yum install kernel* -y

# 3. Set Nano as Default Editor (for all users)
echo "Setting Nano as default editor..."
echo 'export EDITOR="nano"' >> /etc/bashrc
source /etc/bashrc  # Apply changes for current session

# 4. Configure Timezone (Europe/London)
echo "Setting timezone to Europe/London..."
timedatectl set-timezone Europe/London
timedatectl status  # Verify

# 5. Disable SELinux (requires reboot)
echo "Disabling SELinux..."
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 6. Disable Firewalld
echo "Disabling firewalld..."
systemctl disable firewalld --now

# 7. Mark for reboot (only if not already done)
touch "$REBOOT_FLAG"
echo "System setup complete. Rebooting..."

# 8. Reboot (only if this is the first run)
if [ ! -f "$REBOOT_FLAG" ]; then
    reboot
else
    echo "Reboot was already scheduled. Manual reboot may be needed."
fi