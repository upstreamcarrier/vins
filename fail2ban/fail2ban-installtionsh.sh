#!/bin/bash

# Color setup
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

log "Updating system packages..."
yum update -y || error "System update failed"

log "Installing Fail2Ban..."
yum install -y fail2ban || error "Fail2Ban installation failed"

log "Fetching custom jail.local configuration..."
wget -O /etc/fail2ban/jail.local https://raw.githubusercontent.com/upstreamcarrier/vins/main/fail2ban/jail.local || error "Failed to download jail.local"

log "Restarting Fail2Ban service..."
service fail2ban restart || error "Failed to restart Fail2Ban"

log "Checking Fail2Ban service status..."
service fail2ban status || error "Fail2Ban service is not running"

log "Getting Fail2Ban status for asterisk-iptables..."
fail2ban-client status asterisk-iptables || error "Could not get status for asterisk-iptables"

log "Script completed successfully."
