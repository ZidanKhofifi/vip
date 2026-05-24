#!/bin/bash
set -o pipefail

# =========================================================
# ZIDAN TUNNELING - MAIN INSTALLER UBUNTU 22+
# Cleaned installer: Ubuntu 22/24 friendly
# =========================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Colors
Green="\e[92;1m"
RED="\033[1;31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'

REPO="https://raw.githubusercontent.com/ZidanKhofifi/vip/main/"
TIME=$(date '+%d %b %Y')
MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com)
LICENSE_URL="https://raw.githubusercontent.com/ZidanKhofifi/vip/main/izin-ip-sandz"
start=$(date +%s)

print_ok() {
  echo -e "${OK} ${BLUE}$1${FONT}"
}

print_install() {
  echo -e "${green} =============================== ${FONT}"
  echo -e "${YELLOW} # $1 ${FONT}"
  echo -e "${green} =============================== ${FONT}"
  sleep 1
}

print_error() {
  echo -e "${ERROR} ${REDBG} $1 ${FONT}"
}

print_success() {
  echo -e "${green} =============================== ${FONT}"
  echo -e "${Green} # $1 berhasil dipasang${FONT}"
  echo -e "${green} =============================== ${FONT}"
  sleep 1
}

run() {
  "$@"
  return $?
}

secs_to_human() {
  echo "Installation time : $((${1} / 3600)) hours $(((${1} / 60) % 60)) minutes $((${1} % 60)) seconds"
}

banner() {
  clear
  echo -e "${YELLOW}----------------------------------------------------------${NC}"
  echo -e "\033[96;1m                         ZIDAN TUNNELING             \033[0m"
  echo -e "${YELLOW}----------------------------------------------------------${NC}"
  echo ""
  sleep 2
}

check_system() {
  clear
  if [[ $(uname -m) != "x86_64" ]]; then
    print_error "Architecture tidak didukung: $(uname -m)"
    exit 1
  fi
  print_ok "Architecture supported: $(uname -m)"

  OS_ID=$(grep -w ID /etc/os-release | head -n1 | sed 's/=//g;s/"//g;s/ID//g')
  OS_PRETTY=$(grep -w PRETTY_NAME /etc/os-release | head -n1 | sed 's/PRETTY_NAME//g;s/=//g;s/"//g')
  if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
    print_error "OS tidak didukung: $OS_PRETTY"
    exit 1
  fi
  print_ok "OS supported: $OS_PRETTY"

  if [[ -z "$MYIP" ]]; then
    print_error "IP VPS tidak terdeteksi"
    exit 1
  fi
  print_ok "IP VPS: $MYIP"

  if [[ "${EUID}" -ne 0 ]]; then
    print_error "Jalankan sebagai root"
    exit 1
  fi

  if [[ "$(systemd-detect-virt 2>/dev/null)" == "openvz" ]]; then
    print_error "OpenVZ tidak didukung"
    exit 1
  fi
}

check_license() {
  clear
  print_install "Checking VPS License"

  MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com)
  DATA=$(curl -sS "$LICENSE_URL" | awk -v ip="$MYIP" '$1 == "###" && $4 == ip {print $0; exit}')

  if [[ -z "$DATA" ]]; then
    echo -e "${RED}IP VPS tidak terdaftar di izin-ip-sandz!${NC}"
    echo -e "${YELLOW}IP VPS kamu: $MYIP${NC}"
    echo -e "${RED}Install dibatalkan.${NC}"
    exit 1
  fi

  username=$(echo "$DATA" | awk '{print $2}')
  exp=$(echo "$DATA" | awk '{print $3}')

  echo "$username" > /usr/bin/user
  echo "$exp" > /usr/bin/e

  today=$(date +"%Y-%m-%d")

  if [[ "$today" > "$exp" ]]; then
    echo -e "${RED}License expired!${NC}"
    echo -e "${YELLOW}User    : $username${NC}"
    echo -e "${YELLOW}Expired : $exp${NC}"
    echo -e "${RED}Install dibatalkan.${NC}"
    exit 1
  fi

  d1=$(date -d "$exp" +%s)
  d2=$(date -d "$today" +%s)
  certifacate=$(((d1 - d2) / 86400))

  Info="(${green}Active${NC})"
  sts="${Info}"

  echo -e "${OK} IP Terdaftar : ${green}$MYIP${NC}"
  echo -e "${OK} User         : ${green}$username${NC}"
  echo -e "${OK} Expired      : ${green}$exp${NC}"
  echo -e "${OK} Sisa Hari    : ${green}$certifacate Hari${NC}"
  sleep 2
}

prepare_dirs() {
  print_install "Membuat direktori xray"
  mkdir -p /etc/xray /var/log/xray /var/lib/kyt /var/www/html
  mkdir -p /etc/vmess /etc/vless /etc/trojan /etc/shadowsocks /etc/ssh /etc/bot
  mkdir -p /etc/kyt/limit/vmess/ip /etc/kyt/limit/vless/ip /etc/kyt/limit/trojan/ip /etc/kyt/limit/ssh/ip
  touch /etc/xray/domain
  curl -sS ifconfig.me > /etc/xray/ipvps || true
  touch /var/log/xray/access.log /var/log/xray/error.log
  chown -R www-data:www-data /var/log/xray 2>/dev/null || true
  chmod +x /var/log/xray
  touch /etc/vmess/.vmess.db /etc/vless/.vless.db /etc/trojan/.trojan.db /etc/shadowsocks/.shadowsocks.db /etc/ssh/.ssh.db /etc/bot/.bot.db
  grep -q "plughin Account" /etc/vmess/.vmess.db || echo "& plughin Account" >> /etc/vmess/.vmess.db
  grep -q "plughin Account" /etc/vless/.vless.db || echo "& plughin Account" >> /etc/vless/.vless.db
  grep -q "plughin Account" /etc/trojan/.trojan.db || echo "& plughin Account" >> /etc/trojan/.trojan.db
  grep -q "plughin Account" /etc/shadowsocks/.shadowsocks.db || echo "& plughin Account" >> /etc/shadowsocks/.shadowsocks.db
  grep -q "plughin Account" /etc/ssh/.ssh.db || echo "& plughin Account" >> /etc/ssh/.ssh.db
  print_success "Directory Xray"
}

first_setup() {
  print_install "Setup awal Ubuntu/Debian"
  timedatectl set-timezone Asia/Jakarta || true

  # remove broken old HAProxy PPA
  rm -f /etc/apt/sources.list.d/*haproxy* /etc/apt/sources.list.d/*vbernat* 2>/dev/null || true

  apt update -y
  DEBIAN_FRONTEND=noninteractive apt upgrade -y
  apt install -y curl wget sudo gnupg2 ca-certificates lsb-release software-properties-common apt-transport-https

  # HAProxy official Ubuntu repo version, works on Ubuntu 22+
  apt install -y haproxy
  print_success "Setup awal"
}

base_package() {
  print_install "Menginstall paket yang dibutuhkan"
  export DEBIAN_FRONTEND=noninteractive

  apt update -y
  apt install -y \
    zip unzip pwgen openssl netcat-openbsd socat cron bash-completion figlet \
    sudo debconf-utils speedtest-cli vnstat libnss3-dev libnspr4-dev pkg-config \
    libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev libcurl4-nss-dev \
    flex bison make libnss3-tools libevent-dev bc rsyslog dos2unix zlib1g-dev \
    libssl-dev libsqlite3-dev sed dirmngr libxml-parser-perl build-essential gcc g++ \
    python3 python3-pip htop lsof tar wget curl ruby p7zip-full libc6 util-linux \
    msmtp-mta ca-certificates bsd-mailx iptables iptables-persistent netfilter-persistent \
    net-tools gnupg gnupg1 dnsutils screen xz-utils chrony jq openvpn easy-rsa \
    fail2ban dropbear nginx haproxy

  systemctl enable chrony || true
  systemctl restart chrony || true
  chronyc sourcestats -v || true
  chronyc tracking -v || true

  apt install -y ntpsec-ntpdate || true
  /usr/sbin/ntpdate pool.ntp.org || true

  apt-get remove --purge exim4 -y || true
  apt-get remove --purge ufw firewalld -y || true
  apt-get clean all || true
  apt-get autoremove -y || true

  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
  print_success "Paket yang dibutuhkan"
}

pasang_domain() {
  clear
  echo -e "    ----------------------------------"
  echo -e "   |\e[1;32mPlease Select a Domain Type Below \e[0m|"
  echo -e "    ----------------------------------"
  echo -e "     \e[1;32m1)\e[0m Your Domain"
  echo -e "     \e[1;32m2)\e[0m Random Domain"
  echo -e "   ------------------------------------"
  read -rp "   Please select numbers 1-2 or Any Button(Random) : " host
  echo ""

  if [[ $host == "1" ]]; then
    clear
    read -rp "   INPUT YOUR DOMAIN :   " host1
    echo "IP=" > /var/lib/kyt/ipvps.conf
    echo "$host1" > /etc/xray/domain
    echo "$host1" > /root/domain
  elif [[ $host == "2" ]]; then
    wget -q ${REPO}Fls/cf.sh -O /root/cf.sh && chmod +x /root/cf.sh && bash /root/cf.sh || true
    rm -f /root/cf.sh
  else
    print_install "Random Subdomain/Domain is Used"
  fi

  if [[ ! -s /etc/xray/domain ]]; then
    read -rp "Domain belum ada, input domain manual: " manual_domain
    echo "$manual_domain" > /etc/xray/domain
    echo "$manual_domain" > /root/domain
  fi
}

pasang_ssl() {
  print_install "Memasang SSL Pada Domain"
  domain=$(cat /etc/xray/domain)
  rm -rf /etc/xray/xray.key /etc/xray/xray.crt
  systemctl stop nginx haproxy 2>/dev/null || true
  rm -rf /root/.acme.sh
  mkdir -p /root/.acme.sh
  curl -sS https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
  chmod +x /root/.acme.sh/acme.sh
  /root/.acme.sh/acme.sh --upgrade --auto-upgrade || true
  /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt || true
  /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
  /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
  chmod 600 /etc/xray/xray.key
  print_success "SSL Certificate"
}

install_xray() {
  print_install "Install Xray Core"
  mkdir -p /run/xray /usr/local/share/xray
  chown www-data:www-data /run/xray 2>/dev/null || true

  latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version "$latest_version"

  wget -q -O /etc/xray/config.json "${REPO}Cfg/config.json"
  wget -q -O /etc/systemd/system/runn.service "${REPO}Fls/runn.service"
  chmod +x /etc/systemd/system/runn.service

  curl -s ipinfo.io/city > /etc/xray/city || true
  curl -s ipinfo.io/org | cut -d " " -f 2-10 > /etc/xray/isp || true

  print_install "Memasang konfigurasi Nginx/HAProxy/Xray"
  domain=$(cat /etc/xray/domain)
  wget -q -O /etc/haproxy/haproxy.cfg "${REPO}Cfg/haproxy.cfg"
  wget -q -O /etc/nginx/conf.d/xray.conf "${REPO}Cfg/xray.conf"
  wget -q -O /etc/nginx/nginx.conf "${REPO}Cfg/nginx.conf"
  sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg /etc/nginx/conf.d/xray.conf 2>/dev/null || true
  mkdir -p /etc/haproxy
  cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
  chmod 600 /etc/haproxy/hap.pem

  rm -rf /etc/systemd/system/xray.service.d
  cat >/etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  print_success "Xray dan konfigurasi"
}

ssh_config() {
  print_install "Memasang Password SSH"
  wget -q -O /etc/pam.d/common-password "${REPO}Fls/password"
  chmod 644 /etc/pam.d/common-password

  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration || true
  sed -i 's/^AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config || true
  ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

  cat >/etc/systemd/system/rc-local.service <<'EOF'
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

  cat >/etc/rc.local <<'EOF'
exit 0
EOF
  chmod +x /etc/rc.local
  systemctl enable rc-local || true
  systemctl start rc-local.service || true
  echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 || true
  grep -q "disable_ipv6" /etc/rc.local || sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
  print_success "Password SSH"
}

ins_SSHD() {
  print_install "Memasang SSHD"
  wget -q -O /etc/ssh/sshd_config "${REPO}Fls/sshd"
  chmod 600 /etc/ssh/sshd_config
  systemctl restart ssh || /etc/init.d/ssh restart || true
  print_success "SSHD"
}

ins_dropbear() {
  clear
  print_install "Menginstall Dropbear 2019"

  apt install -y dropbear > /dev/null 2>&1

  systemctl stop dropbear || true

  rm -f /usr/sbin/dropbear

  wget -q -O /usr/sbin/dropbear "${REPO}Fls/dropbear2019"

  chmod +x /usr/sbin/dropbear

  wget -q -O /etc/default/dropbear "${REPO}Cfg/dropbear.conf"

  chmod 644 /etc/default/dropbear

  pkill -9 dropbear 2>/dev/null || true

  systemctl daemon-reload
  systemctl reset-failed dropbear

  systemctl restart dropbear || /etc/init.d/dropbear restart || true

  print_success "Dropbear 2019"
}

udp_mini() {
  print_install "Memasang Service Limit dan UDP Mini"
  wget -q -O /root/limit.sh "${REPO}Fls/limit.sh" && chmod +x /root/limit.sh && bash /root/limit.sh || true

  wget -q -O /usr/bin/limit-ip "${REPO}Fls/limit-ip"
  wget -q -O /usr/bin/limit-ip-ssh "${REPO}Fls/limit-ip-ssh"
  chmod +x /usr/bin/limit-ip /usr/bin/limit-ip-ssh
  sed -i 's/\r//' /usr/bin/limit-ip /usr/bin/limit-ip-ssh

  cat >/etc/systemd/system/sship.service <<'EOF'
[Unit]
Description=Limit SSH IP
After=network.target

[Service]
ExecStart=/usr/bin/limit-ip-ssh
Restart=always
RestartSec=3
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  for svc in vmip vlip trip; do
    cat >/etc/systemd/system/${svc}.service <<EOF
[Unit]
Description=Limit ${svc}
After=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip ${svc}
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  done

  mkdir -p /usr/local/kyt
  wget -q -O /usr/local/kyt/udp-mini "${REPO}Fls/udp-mini"
  chmod +x /usr/local/kyt/udp-mini
  wget -q -O /etc/systemd/system/udp-mini-1.service "${REPO}Fls/udp-mini-1.service"
  wget -q -O /etc/systemd/system/udp-mini-2.service "${REPO}Fls/udp-mini-2.service"
  wget -q -O /etc/systemd/system/udp-mini-3.service "${REPO}Fls/udp-mini-3.service"

  systemctl daemon-reload
  for svc in sship vmip vlip trip udp-mini-1 udp-mini-2 udp-mini-3; do
    systemctl enable --now "$svc" 2>/dev/null || true
  done
  print_success "Limit dan UDP Mini"
}

ssh_slow() {
  print_install "Memasang modul SlowDNS Server"
  wget -q -O /tmp/nameserver "${REPO}Fls/nameserver" || true
  chmod +x /tmp/nameserver 2>/dev/null || true
  bash /tmp/nameserver 2>/dev/null | tee /root/install.log || true
  print_success "SlowDNS"
}

ins_vnstat() {
  print_install "Menginstall Vnstat"
  apt install -y vnstat libsqlite3-dev
  systemctl enable vnstat || true
  systemctl restart vnstat || true
  print_success "Vnstat"
}

ins_openvpn() {
  print_install "Menginstall OpenVPN"
  wget -q -O /root/openvpn "${REPO}Vpn/openvpn"
  chmod +x /root/openvpn
  bash /root/openvpn || true
  systemctl restart openvpn || /etc/init.d/openvpn restart || true
  print_success "OpenVPN"
}

ins_backup() {
  print_install "Memasang Backup Server"
  apt install -y rclone wondershaper msmtp-mta ca-certificates bsd-mailx || true
  mkdir -p /root/.config/rclone
  # WARNING: do not store real token/password in public repo.
  wget -q -O /root/.config/rclone/rclone.conf "${REPO}Cfg/rclone.conf" || true
  wget -q -O /etc/ipserver "${REPO}Fls/ipserver" && bash /etc/ipserver || true
  print_success "Backup Server"
}

ins_swab() {
  print_install "Memasang Swap 1G dan BBR"
  if [[ ! -f /swapfile ]]; then
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile || true
    grep -q '/swapfile' /etc/fstab || echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
  fi
  wget -q -O /root/bbr.sh "${REPO}Fls/bbr.sh" && chmod +x /root/bbr.sh && bash /root/bbr.sh || true
  print_success "Swap 1G dan BBR"
}

ins_Fail2ban() {
  print_install "Menginstall Fail2ban"
  apt install -y fail2ban
  systemctl enable fail2ban || true
  systemctl restart fail2ban || true
  wget -q -O /etc/banner.txt "${REPO}Bnr/banner.txt" || true
  grep -q "Banner /etc/banner.txt" /etc/ssh/sshd_config || echo "Banner /etc/banner.txt" >> /etc/ssh/sshd_config
  sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/banner.txt"@g' /etc/default/dropbear 2>/dev/null || true
  print_success "Fail2ban"
}

ins_epro() {
  print_install "Menginstall ePro WebSocket Proxy"
  wget -q -O /usr/bin/ws "${REPO}Fls/ws"
  wget -q -O /usr/bin/tun.conf "${REPO}Cfg/tun.conf"
  wget -q -O /etc/systemd/system/ws.service "${REPO}Fls/ws.service"
  chmod +x /usr/bin/ws
  chmod 644 /usr/bin/tun.conf
  chmod 644 /etc/systemd/system/ws.service

  systemctl daemon-reload
  systemctl enable ws
  systemctl restart ws

  wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" || true
  wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" || true
  wget -q -O /usr/sbin/ftvpn "${REPO}Fls/ftvpn" || true
  chmod +x /usr/sbin/ftvpn 2>/dev/null || true

  # Torrent blocking rules, safe to fail.
  for word in get_peers announce_peer find_node BitTorrent "BitTorrent protocol" peer_id= .torrent announce.php?passkey= torrent announce info_hash; do
    iptables -A FORWARD -m string --string "$word" --algo bm -j DROP 2>/dev/null || true
  done
  iptables-save > /etc/iptables.up.rules 2>/dev/null || true
  netfilter-persistent save 2>/dev/null || true
  netfilter-persistent reload 2>/dev/null || true
  print_success "ePro WebSocket Proxy"
}

install_http_api() {
  print_install "Menginstall HTTP API"

  apt install -y python3-pip
  pip3 install fastapi uvicorn

  wget -q -O /usr/local/sbin/zidan-api.py "${REPO}Fls/zidan-api.py"
  wget -q -O /etc/systemd/system/zidan-api.service "${REPO}Fls/zidan-api.service"

  chmod +x /usr/local/sbin/zidan-api.py

  systemctl daemon-reload
  systemctl enable zidan-api
  systemctl restart zidan-api

  print_success "HTTP API"
}

menu_install() {
  print_install "Memasang Menu Packet"
  cd /root || exit 1
  rm -rf menu menu.zip
  wget -q -O menu.zip "${REPO}Cdy/menu.zip"
  unzip -o menu.zip
  chmod +x menu/*
  mkdir -p /usr/local/sbin
  cp -rf menu/* /usr/local/sbin/
  chmod +x /usr/local/sbin/*
  rm -rf menu menu.zip
  print_success "Menu Packet"
}

profile_setup() {
  print_install "Setup profile dan cron"
  cat >/root/.profile <<'EOF'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n 2>/dev/null || true
welcome
EOF

  cat >/etc/cron.d/xp_all <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
2 0 * * * root /usr/local/sbin/xp
EOF

  cat >/etc/cron.d/logclean <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root /usr/local/sbin/clearlog
EOF

  cat >/etc/cron.d/limssh <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/local/sbin/limitssh-ip
EOF

  cat >/etc/cron.d/limxry <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/local/sbin/lock-xray-ip
EOF

  cat >/etc/cron.d/log.nginx <<'EOF'
*/1 * * * * root echo -n > /var/log/nginx/access.log
EOF

  cat >/etc/cron.d/log.xray <<'EOF'
*/1 * * * * root echo -n > /var/log/xray/access.log
EOF

  echo "5" > /home/daily_reboot
  chmod 644 /root/.profile /etc/cron.d/* 2>/dev/null || true
  grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
  grep -q "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

  cat >/etc/rc.local <<'EOF'
iptables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
systemctl restart netfilter-persistent 2>/dev/null || true
exit 0
EOF
  chmod +x /etc/rc.local
  systemctl restart cron || true
  print_success "Profile dan cron"
}

enable_services() {
  print_install "Enable Service"
  systemctl daemon-reload
  for svc in rc-local cron netfilter-persistent nginx xray dropbear openvpn haproxy ws fail2ban; do
    systemctl enable --now "$svc" 2>/dev/null || true
  done
  systemctl restart nginx 2>/dev/null || true
  systemctl restart xray 2>/dev/null || true
  systemctl restart haproxy 2>/dev/null || true
  systemctl restart ws 2>/dev/null || true
  systemctl restart dropbear 2>/dev/null || true
  print_success "Enable Service"
}

restart_all() {
  print_install "Restarting All Packet"
  systemctl daemon-reload
  systemctl restart nginx 2>/dev/null || true
  systemctl restart openvpn 2>/dev/null || true
  systemctl restart ssh 2>/dev/null || true
  systemctl restart dropbear 2>/dev/null || true
  systemctl restart fail2ban 2>/dev/null || true
  systemctl restart vnstat 2>/dev/null || true
  systemctl restart haproxy 2>/dev/null || true
  systemctl restart cron 2>/dev/null || true
  systemctl restart netfilter-persistent 2>/dev/null || true
  systemctl restart ws 2>/dev/null || true
  rm -f /root/openvpn /root/key.pem /root/cert.pem
  print_success "All Packet"
}

restart_system_notify() {
  # Token Telegram jangan ditaruh di repo publik.
  return 0
}

install_all() {
  banner
  check_system
  check_license
  echo ""
  read -rp "Press [ Enter ] For Starting Installation"
  prepare_dirs
  first_setup
  base_package
  pasang_domain
  pasang_ssl
  install_xray
  ssh_config
  udp_mini
  ssh_slow
  ins_SSHD
  ins_dropbear
  ins_vnstat
  ins_openvpn
  ins_backup
  ins_swab
  ins_Fail2ban
  ins_epro
  restart_all
  menu_install
  install_http_api
  profile_setup
  enable_services
  restart_system_notify
}

install_all

history -c || true
rm -rf /root/menu /root/*.zip /root/*.sh /root/LICENSE /root/README.md /root/domain
secs_to_human "$(($(date +%s) - start))"

username=$(cat /usr/bin/user 2>/dev/null || echo zidan)
hostnamectl set-hostname "$username" || true

clear
echo -e ""
echo -e "\033[96m==========================\033[0m"
echo -e "\033[92m      INSTALL SUCCESS     \033[0m"
echo -e "\033[96m==========================\033[0m"
echo -e ""
sleep 2
echo -e "\033[93;1m Wait in 4 sec...\033[0m"
sleep 4
read -rp "Press [ Enter ] TO REBOOT"
/sbin/reboot
