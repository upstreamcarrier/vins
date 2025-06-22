#!/bin/bash

set -e
trap 'echo -e "\033[0;31m⚠️  ERROR at line $LINENO. Continuing...\033[0m"' ERR

# === VICIdial Installation Script for CentOS 7 with WebRTC Support ===
# --- Color Definitions ---
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}==> $1${NC}"
}

# --- Arguments ---
REBUILD=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --rebuild)
      REBUILD=true
      shift
      ;;
    *)
      echo "Unknown option: $1" && exit 1
      ;;
  esac
done

# --- Configurable Variables ---
AST_VERSION="13.29.2"
MYSQL_ROOT_PASS=""
SERVER_IP="$(hostname -I | awk '{print $1}')"

# --- URLs ---
ASTERISK_PERL_URL="https://github.com/upstreamcarrier/vins/raw/main/dependancies/asterisk-perl-0.08.tar.gz"
SIPSAK_URL="http://download.vicidial.com/required-apps/sipsak-0.9.6-1.tar.gz"
LAME_URL="http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"
JANSSON_URL="http://www.digip.org/jansson/releases/jansson-2.5.tar.gz"
PHP_INI_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/main/php.ini"
HTTPD_CONF_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/main/httpd.conf"
# DAHDI_URL="https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-3.1.0%2B3.1.0.tar.gz"
LIBPRI_URL="https://downloads.asterisk.org/pub/telephony/libpri/libpri-1.6.1.tar.gz"
ASTERISK_URL="http://download.vicidial.com/required-apps/asterisk-${AST_VERSION}-vici.tar.gz"
MY_CNF_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/heads/main/my.cnf"
AGC_CONF_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/main/astguiclient.conf"
CRONTAB_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/main/crontab"
RC_LOCAL_URL="https://raw.githubusercontent.com/upstreamcarrier/vins/main/rc.local"
DAHDI_VERSION="3.1.0"
DAHDI_TARBALL="dahdi-linux-complete-3.1.0+3.1.0.tar.gz"
DAHDI_URL="https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-3.1.0%2B3.1.0.tar.gz"
DAHDI_DIR="dahdi-linux-complete-${DAHDI_VERSION}+${DAHDI_VERSION}"


install_perl_module_if_missing() {
  local module="$1"
  if ! perl -M"$module" -e1 2>/dev/null; then
    echo "Installing missing Perl module: $module"
    cpanm --notest "$module" || cpanm --force "$module"
  else
    echo "✅ Perl module $module already installed"
  fi
}

# --- System Preparation ---
log "Starting system update and installing prerequisites"
yum check-update
yum -y install epel-release
yum update -y
yum groupinstall "Development Tools" -y

# PHP Related Modules
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
yum -y install yum-utils
dnf module enable php:remi-7.4

# --- Install Base Packages ---
yum -y install mariadb-server php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo \
  php-opcache wget unzip make patch gcc gcc-c++ subversion readline-devel gd-devel php-mbstring php-imap \
  php-odbc php-pear php-xml php-xmlrpc curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel \
  httpd libpcap libpcap-devel libnet ncurses ncurses-devel screen kernel* mutt glibc.i686 certbot \
  python3-certbot-apache mod_ssl openssl-devel newt-devel libuuid-devel sox sendmail lame-devel htop iftop \
  perl-File-Which php-opcache libss7 mariadb-devel libss7* libopen* jansson-devel sqlite-devel

## PHP Version Check
log "PHP Version Check"
PHP_VERSION=$(php -v 2>/dev/null | grep -m 1 "^PHP")
echo "Detected PHP Version: $PHP_VERSION"
log "PHP Version Check $PHP_VERSION"

log "Securing MariaDB"
# --- Start and Configure MariaDB ---
systemctl start mariadb

#mysql_secure_installation

# Start of Automating mysql_secure_installation
# Set root password and secure installation (non-interactive)
MYSQL_ROOT_PASSWORD=""

mysql -u root <<EOF
-- Set root password if it's not already set
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

### End of mysql_secure_installation
cp /etc/my.cnf /etc/my.cnf.bak
wget -O /etc/my.cnf "$MY_CNF_URL"
mkdir -p /var/log/mysqld
touch /var/log/mysqld/slow-queries.log
chown -R mysql:mysql /var/log/mysqld
systemctl enable mariadb
systemctl restart mariadb

# --- Configure Apache ---
systemctl enable httpd
systemctl restart httpd

# --- Perl Modules ---
log "Installing Perl modules"
yum install -y perl-CPAN perl-YAML perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD
cd /usr/bin && curl -LOk http://xrl.us/cpanm && chmod +x cpanm

modules=(
  File::HomeDir File::Which CPAN::Meta::Requirements CPAN YAML MD5 Digest::MD5 Digest::SHA1
  DBI DBD::mysql Net::Telnet Time::HiRes Net::Server Switch Mail::Sendmail Unicode::Map Jcode
  Spreadsheet::WriteExcel OLE::Storage_Lite Proc::ProcessTable IO::Scalar Spreadsheet::ParseExcel
  Curses Getopt::Long Net::Domain Term::ReadKey Term::ANSIColor Spreadsheet::XLSX Spreadsheet::Read
  LWP::UserAgent HTML::Entities HTML::Strip HTML::FormatText HTML::TreeBuilder Time::Local
  MIME::Decoder Mail::POP3Client Mail::IMAPClient Mail::Message IO::Socket::SSL MIME::Base64
  MIME::QuotedPrint Crypt::Eksblowfish::Bcrypt Crypt::RC4 Text::CSV Text::CSV_XS
  Term::ReadLine::Perl
)

for mod in "${modules[@]}"; do
  install_perl_module_if_missing "$mod"
done

echo "✅ Perl modules installed"

# # --- Perl & CPAN Modules ---
# yum -y install perl-CPAN perl-YAML perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD
# cd /usr/bin && curl -LOk http://xrl.us/cpanm && chmod +x cpanm
# cpanm -f File::HomeDir File::Which CPAN::Meta::Requirements CPAN YAML MD5 Digest::MD5 Digest::SHA1 \
#   Bundle::CPAN DBI DBD::mysql Net::Telnet Time::HiRes Net::Server Switch Mail::Sendmail Unicode::Map Jcode \
#   Spreadsheet::WriteExcel OLE::Storage_Lite Proc::ProcessTable IO::Scalar Spreadsheet::ParseExcel Curses \
#   Getopt::Long Net::Domain Term::ReadKey Term::ANSIColor Spreadsheet::XLSX Spreadsheet::Read LWP::UserAgent \
#   HTML::Entities HTML::Strip HTML::FormatText HTML::TreeBuilder Time::Local MIME::Decoder Mail::POP3Client \
#   Mail::IMAPClient Mail::Message IO::Socket::SSL MIME::Base64 MIME::QuotedPrint Crypt::Eksblowfish::Bcrypt \
#   Crypt::RC4 Text::CSV Text::CSV_XS

# Install Term::ReadLine::Perl safely
cpanm --notest Term::ReadLine::Perl || cpanm --force Term::ReadLine::Perl

echo "✅ INFO: Perl modules installed"

# --- Install Asterisk Perl ---
log "Installing Asterisk Perl bindings"
cd /usr/src
curl -LO "$ASTERISK_PERL_URL"
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08
perl Makefile.PL && make all && make install

# --- Install Sipsak ---
log "Installing Sipsak"
cd /usr/src
curl -LO "$SIPSAK_URL"
tar -zxf sipsak-0.9.6-1.tar.gz
cd sipsak-0.9.6
./configure && make && make install

# --- Install Lame ---
log "Installing Lame encoder"
cd /usr/src
curl -LO "$LAME_URL"
tar -zxf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure && make && make install

# --- Install Jansson ---
log "Installing Jansson JSON Library"
cd /usr/src
curl -LO "$JANSSON_URL"
tar -zxf jansson-2.5.tar.gz
cd jansson-2.5
./configure && make && make install && ldconfig

# --- PHP Config ---
log "Configuring PHP and Apache"
wget -O /etc/php.ini "$PHP_INI_URL"
mkdir -p /tmp/eaccelerator && chmod 0777 /tmp/eaccelerator

# --- Apache Config ---
wget -O /etc/httpd/conf/httpd.conf "$HTTPD_CONF_URL"
systemctl restart httpd

# log "Installing dahdi"
# #new one
# cd /usr/src/
# wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-3.1.0%2B3.1.0.tar.gz
# tar xzf dahdi-linux-complete-3.1.0+3.1.0.tar.gz
# cd /usr/src/dahdi-linux-complete-3.1.0+3.1.0/
# sed -i '/#include <linux\/pci-aspm.h>/d' /usr/src/dahdi-linux-complete-3.1.0+3.1.0/linux/include/dahdi/kernel.h
# sed -i 's/netif_napi_add(netdev, \&wc->napi, \&wctc4xxp_poll, 64);/netif_napi_add(netdev, \&wc->napi, wctc4xxp_poll);/' linux/drivers/dahdi/wctc4xxp/base.c
# make all
# make install
# make install-config

# yum -y install dahdi-tools-libs

# cd tools
# make clean
# make
# make install
# make install-config

# modprobe dahdi
# modprobe dahdi_dummy
# make config
# cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf # or download from Repo https://raw.githubusercontent.com/upstreamcarrier/vins/main/system.conf
# systemctl restart dahdi
# systemctl status dahdi
# /usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

# log "Check dahdi status above "

# idemp

cd /usr/src/

if [ ! -f "$DAHDI_TARBALL" ]; then
  log "Downloading DAHDI source..."
  wget "$DAHDI_URL"
else
  log "DAHDI tarball already exists, skipping download"
fi

if [ ! -d "$DAHDI_DIR" ]; then
  log "Extracting DAHDI..."
  tar xzf "$DAHDI_TARBALL"
else
  log "DAHDI source already extracted, skipping"
fi

# if ! modinfo dahdi_dummy &>/dev/null || ! command -v dahdi_cfg &>/dev/null; then
#   log "Compiling and installing DAHDI ${DAHDI_VERSION}..."

#   cd "/usr/src/${DAHDI_DIR}"
#   sed -i '/#include <linux\/pci-aspm.h>/d' linux/include/dahdi/kernel.h
#   sed -i 's/netif_napi_add(netdev, \&wc->napi, \&wctc4xxp_poll, 64);/netif_napi_add(netdev, \&wc->napi, wctc4xxp_poll);/' linux/drivers/dahdi/wctc4xxp/base.c

#   make all
#   make install
#   make install-config

#   yum -y install dahdi-tools-libs

#   cd tools
#   make clean
#   make
#   make install
#   make install-config

#   modprobe dahdi
#   modprobe dahdi_dummy
#   make config

#   if [ ! -f /etc/dahdi/system.conf ]; then
#     cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf
#   fi

#   systemctl restart dahdi
#   log "✅ DAHDI ${DAHDI_VERSION} installed and running"
# else
#   log "DAHDI appears to already be installed and configured — skipping rebuild"
# fi

if $REBUILD || ! modinfo dahdi_dummy &>/dev/null || ! command -v dahdi_cfg &>/dev/null; then
  log "Building and installing DAHDI ${DAHDI_VERSION}..."
  cd "$DAHDI_DIR"
  sed -i '/#include <linux\/pci-aspm.h>/d' linux/include/dahdi/kernel.h
  sed -i 's/netif_napi_add(netdev, \&wc->napi, \&wctc4xxp_poll, 64);/netif_napi_add(netdev, \&wc->napi, wctc4xxp_poll);/' linux/drivers/dahdi/wctc4xxp/base.c
  make all && make install && make install-config
  cd tools && make clean && make && make install && make install-config
  modprobe dahdi && modprobe dahdi_dummy
  make config
  [ -f /etc/dahdi/system.conf ] || cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf
  systemctl restart dahdi
  log "✅ DAHDI ${DAHDI_VERSION} installed"
else
  log "DAHDI already installed and configured, skipping"
fi

log "Checking DAHDI status:"
/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv


log "Checking DAHDI status:"
/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

# --- Install LibPRI ---
log "Compiling LibPRI & installing dahdi-tools-libs "
yum install dahdi-tools-libs
cd /usr/src
curl -LO "$LIBPRI_URL"
tar -xvzf libpri-1.6.1.tar.gz
cd libpri-1.6.1
make clean && make && make install

# --- Install Asterisk ---
log "Checking for existing Asterisk v${AST_VERSION} source"
cd /usr/src

if [ ! -f "asterisk-${AST_VERSION}-vici.tar.gz" ]; then
  log "Downloading Asterisk source tarball..."
  curl -LO "$ASTERISK_URL"
else
  log "Asterisk tarball already exists, skipping download"
fi

if [ ! -d "asterisk-${AST_VERSION}" ]; then
  log "Extracting Asterisk source..."
  tar xzf "asterisk-${AST_VERSION}-vici.tar.gz"
else
  log "Asterisk source already extracted, skipping extraction"
fi

if $REBUILD || ! command -v asterisk >/dev/null || ! asterisk -V | grep -q "$AST_VERSION"; then
  log "Compiling Asterisk v${AST_VERSION}..."
  cd "asterisk-${AST_VERSION}"
  ./configure --libdir=/usr/lib --with-gsm=internal --enable-opus --enable-srtp --with-ssl --enable-asteriskssl \
    --with-pjproject-bundled --with-jansson-bundled
  make menuselect/menuselect menuselect-tree menuselect.makeopts
  menuselect/menuselect --enable app_meetme --enable res_http_websocket --enable res_srtp menuselect.makeopts
  make -j $(nproc)
  make install
  make samples
  make config
  log "✅ Asterisk ${AST_VERSION} compiled and installed"
else
  log "Asterisk ${AST_VERSION} already installed, skipping"
fi

# --- Install astguiclient ---
log "Installing astguiclient"
mkdir -p /usr/src/astguiclient && cd /usr/src/astguiclient
svn checkout svn://svn.eflo.net/agc_2-X/trunk
cd trunk

# --- Configure MySQL ---
log "Configuring MySQL"
mysql -u root -p"$MYSQL_ROOT_PASS" << EOF
CREATE DATABASE asterisk DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES ON asterisk.* TO 'cron'@'localhost';
CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES ON asterisk.* TO 'custom'@'localhost';
GRANT RELOAD ON *.* TO 'cron'@'localhost';
GRANT RELOAD ON *.* TO 'custom'@'localhost';
FLUSH PRIVILEGES;
USE asterisk;
SOURCE /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql;
SOURCE /usr/src/astguiclient/trunk/extras/first_server_install.sql;
UPDATE servers SET asterisk_version='${AST_VERSION}';
EOF

log "MYSQL Configured"

# --- Configure Vicidial ---
log "Configure Vicidial"
wget -O /etc/astguiclient.conf "$AGC_CONF_URL"
sed -i "s/SERVERIP/$SERVER_IP/g" /etc/astguiclient.conf
perl install.pl
sed -i "s/0.0.0.0/127.0.0.1/g" /etc/asterisk/manager.conf
/usr/share/astguiclient/ADMIN_area_code_populate.pl
/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15

# --- Crontab ---
wget -O /root/crontab-file "$CRONTAB_URL"
grep -Ev '^\s*#|^\s*$' /root/crontab-file > /tmp/clean-crontab && crontab /tmp/clean-crontab
#crontab /root/crontab-file

# --- rc.local ---
log "Installing rc.local"
wget -O /etc/rc.d/rc.local "$RC_LOCAL_URL"
chmod +x /etc/rc.d/rc.local
systemctl enable rc-local
systemctl start rc-local

# --- Final Step ---
echo "✅ INFO: VICIdial installation complete. Rebooting..."
reboot
