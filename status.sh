#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}==> $1${NC}"
}

log "======== VICIdial System Health Check ========"
log "Date: $(date '+%Y-%m-%d %H:%M:%S')"
log "Hostname: $(hostname)"
log "=============================================="
echo

# Function to section output
print_section() {
    log
    log "---- $1 ----"
}

# Expected VICIdial screen sessions
EXPECTED_SCREENS=(
    "ASTfastlog"
    "ASTVDauto"
    "ASTVDremote"
    "ASTlisten"
    "ASTsend"
    "ASTupdate"
    "ASTVDadapt"
    "ASTconf3way"
    "asterisk"
)

# Check existing screen sessions
print_section "Existing Screen Sessions"
screen -ls || log "Screen not installed or running."

# Extract running screen session names
CURRENT_SCREENS=$(screen -ls | grep -oP '\.\K[^[:space:]]+')

# Compare and show missing/present screen sessions
echo
echo "Screen Session Check:"
for screen in "${EXPECTED_SCREENS[@]}"; do
    if echo "$CURRENT_SCREENS" | grep -q "^$screen$"; then
        echo -e "${GREEN}[OK]     $screen${NC}"
    else
        echo -e "${RED}[MISSING] $screen${NC}"
    fi
done

# Check Fail2Ban status for Asterisk jail
print_section "Fail2Ban: asterisk-iptables Jail Status"
if command -v fail2ban-client >/dev/null 2>&1; then
    fail2ban-client status asterisk-iptables || log "Fail2Ban asterisk-iptables jail not found."
else
    log "Fail2Ban not installed."
fi

# Check DNS / Nameservers
print_section "DNS Configuration (/etc/resolv.conf)"
cat /etc/resolv.conf

# Asterisk active channels
print_section "Asterisk: Active Channels"
asterisk -rx 'core show channels concise' | wc -l | awk '{print $1 " active channel(s)"}'

print_section "Asterisk: Active Calls"
asterisk -rx 'core show calls' 2>/dev/null

# Apache/HTTPD service
print_section "Apache (httpd) Service Status"
if systemctl list-units --type=service | grep -q httpd; then
    systemctl status httpd --no-pager | grep -E 'Active:|Loaded:'
else
    log "Apache httpd not installed or not using systemd."
fi

## Mariadb/Mysql service Status
# systemctl list-units --type=service | grep mariadb.service
print_section "MariaDB Service Status"
if systemctl list-units --type=service | grep -q mariadb; then
    systemctl status mariadb --no-pager | grep -E 'Active:|Loaded:'
elif systemctl list-units --type=service | grep -q mysql; then
    systemctl status mysql --no-pager | grep -E 'Active:|Loaded:'
else
    log "MariaDB or MySQL not installed or not using systemd."
fi

print_section "MariaDB Process Count"
pgrep -c mysqld | awk '{print $1 " MariaDB process(es) running"}'

print_section "MariaDB Connection Count"
if command -v mysql >/dev/null 2>&1; then
    mysql -e "SHOW STATUS WHERE variable_name = 'Threads_connected'" 2>/dev/null || \
    error_log "Could not connect to MariaDB"
else
    error_log "mysql client not found"
fi

# Asterisk service
print_section "Asterisk Service Status"
if systemctl list-units --type=service | grep -q asterisk; then
    systemctl status asterisk --no-pager | grep -E 'Active:|Loaded:'
else
    log "Asterisk service not found or not using systemd."
fi

echo
log "======== Health Check Complete ========"

