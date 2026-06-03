#!/bin/bash
set -o pipefail

# =========================================================
# ZIDAN TUNNELING - MAIN INSTALLER UBUNTU 22/24 FRIENDLY
# =========================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# Colors
Green="\e[92;1m"
RED="\033[1;31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
NC='\e[0m'
green='\e[0;32m'

REPO="https://raw.githubusercontent.com/ZidanKhofifi/vip/main/"
LICENSE_URL="https://raw.githubusercontent.com/ZidanKhofifi/vip/main/izin-ip-sandz"
TIME=$(date '+%d %b %Y')
MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com 2>/dev/null)
start=$(date +%s)

print_ok() { echo -e "${OK} ${BLUE}$1${FONT}"; }
print_error() { echo -e "${ERROR} ${REDBG} $1 ${FONT}"; }
print_install() { echo -e "${green} =============================== ${FONT}"; echo -e "${YELLOW} # $1 ${FONT}"; echo -e "${green} =============================== ${FONT}"; sleep 1; }
print_success() { echo -e "${green} =============================== ${FONT}"; echo -e "${Green} # $1 berhasil dipasang${FONT}"; echo -e "${green} =============================== ${FONT}"; sleep 1; }

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

safe_wget() {
  local url="$1"
  local out="$2"
  mkdir -p "$(dirname "$out")"
  wget -q -O "$out" "$url"
  [[ -s "$out" ]]
}

check_system() {
  clear
  if [[ "$(uname -m)" != "x86_64" ]]; then
    print_error "Architecture tidak didukung: $(uname -m)"
    exit 1
  fi
  print_ok "Architecture supported: $(uname -m)"

  OS_ID=$(awk -F= '$1=="ID"{gsub(/"/,"",$2);print $2}' /etc/os-release)
  OS_PRETTY=$(awk -F= '$1=="PRETTY_NAME"{gsub(/"/,"",$2);print $2}' /etc/os-release)

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

  if [[ "$EUID" -ne 0 ]]; then
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

  MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com 2>/dev/null)
  DATA=$(curl -sS "$LICENSE_URL" | awk -v ip="$MYIP" '$1=="###" && $4==ip {print $0; exit}')

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
  certificate=$(((d1 - d2) / 86400))

  echo -e "${OK} IP Terdaftar : ${green}$MYIP${NC}"
  echo -e "${OK} User         : ${green}$username${NC}"
  echo -e "${OK} Expired      : ${green}$exp${NC}"
  echo -e "${OK} Sisa Hari    : ${green}$certificate Hari${NC}"
  sleep 2
}

prepare_dirs() {
  print_install "Membuat direktori"

  mkdir -p /etc/xray /run/xray /var/log/xray /var/lib/kyt /var/www/html
  mkdir -p /etc/vmess /etc/vless /etc/trojan /etc/shadowsocks /etc/ssh /etc/bot
  mkdir -p /etc/kyt/limit/vmess/ip /etc/kyt/limit/vless/ip /etc/kyt/limit/trojan/ip /etc/kyt/limit/shadowsocks/ip /etc/kyt/limit/ssh/ip
  mkdir -p /etc/nginx/conf.d /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/haproxy
  mkdir -p /usr/local/share/xray /usr/local/kyt

  touch /etc/xray/domain
  curl -sS ifconfig.me > /etc/xray/ipvps 2>/dev/null || true

  touch /var/log/xray/access.log /var/log/xray/error.log
  chown -R www-data:www-data /var/log/xray /run/xray 2>/dev/null || true
  chmod +x /var/log/xray

  touch /etc/vmess/.vmess.db /etc/vless/.vless.db /etc/trojan/.trojan.db /etc/shadowsocks/.shadowsocks.db /etc/ssh/.ssh.db /etc/bot/.bot.db

  grep -q "plughin Account" /etc/vmess/.vmess.db || echo "& plughin Account" >> /etc/vmess/.vmess.db
  grep -q "plughin Account" /etc/vless/.vless.db || echo "& plughin Account" >> /etc/vless/.vless.db
  grep -q "plughin Account" /etc/trojan/.trojan.db || echo "& plughin Account" >> /etc/trojan/.trojan.db
  grep -q "plughin Account" /etc/shadowsocks/.shadowsocks.db || echo "& plughin Account" >> /etc/shadowsocks/.shadowsocks.db
  grep -q "plughin Account" /etc/ssh/.ssh.db || echo "& plughin Account" >> /etc/ssh/.ssh.db

  print_success "Directory"
}

first_setup() {
  print_install "Setup awal Ubuntu/Debian"

  timedatectl set-timezone Asia/Jakarta || true
  rm -f /etc/apt/sources.list.d/*haproxy* /etc/apt/sources.list.d/*vbernat* 2>/dev/null || true

  apt update -y
  apt upgrade -y
  apt install -y curl wget sudo gnupg2 ca-certificates lsb-release software-properties-common apt-transport-https
  apt install -y haproxy

  print_success "Setup awal"
}

base_package() {
  print_install "Menginstall paket yang dibutuhkan"

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
    fail2ban dropbear nginx haproxy at

  systemctl enable --now atd 2>/dev/null || true
  systemctl enable chrony 2>/dev/null || true
  systemctl restart chrony 2>/dev/null || true
  chronyc sourcestats -v 2>/dev/null || true
  chronyc tracking -v 2>/dev/null || true

  apt install -y ntpsec-ntpdate || true
  /usr/sbin/ntpdate pool.ntp.org 2>/dev/null || true

  apt-get remove --purge exim4 -y || true
  apt-get remove --purge ufw firewalld -y || true
  apt-get clean all || true
  apt-get autoremove -y || true

  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

  if ! command -v nginx >/dev/null 2>&1; then
    apt install -y nginx
  fi

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

  if [[ "$host" == "1" ]]; then
    clear
    read -rp "   INPUT YOUR DOMAIN :   " host1
    echo "IP=" > /var/lib/kyt/ipvps.conf
    echo "$host1" > /etc/xray/domain
    echo "$host1" > /root/domain
  elif [[ "$host" == "2" ]]; then
    wget -q "${REPO}Fls/cf.sh" -O /root/cf.sh && chmod +x /root/cf.sh && bash /root/cf.sh || true
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

  chmod 600 /etc/xray/xray.key 2>/dev/null || true

  print_success "SSL Certificate"
}

install_banner() {
  mkdir -p /etc
  wget -q -O /etc/banner.txt "${REPO}Bnr/banner.txt" || true

  if [[ ! -s /etc/banner.txt ]]; then
    cat >/etc/banner.txt <<'EOF'
ZIDAN TUNNELING
EOF
  fi

  chmod 644 /etc/banner.txt
}

install_xray() {
  print_install "Install Xray Core"

  mkdir -p /run/xray /usr/local/share/xray /etc/xray
  chown www-data:www-data /run/xray 2>/dev/null || true

  latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version "$latest_version"

  safe_wget "${REPO}Cfg/config.json" /etc/xray/config.json || { echo "Gagal download config Xray"; exit 1; }

  xray run -test -config /etc/xray/config.json >/dev/null 2>&1 || {
    echo "Config Xray error"
    exit 1
  }

  safe_wget "${REPO}Fls/runn.service" /etc/systemd/system/runn.service || true
  chmod +x /etc/systemd/system/runn.service 2>/dev/null || true

  curl -s ipinfo.io/city > /etc/xray/city 2>/dev/null || true
  curl -s ipinfo.io/org | cut -d " " -f 2-10 > /etc/xray/isp 2>/dev/null || true

  print_install "Memasang konfigurasi Nginx/HAProxy/Xray"

  domain=$(cat /etc/xray/domain)

  mkdir -p /etc/nginx/conf.d /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/haproxy

  if ! command -v nginx >/dev/null 2>&1; then
    apt install -y nginx
  fi

  safe_wget "${REPO}Cfg/haproxy.cfg" /etc/haproxy/haproxy.cfg || { echo "Gagal download haproxy.cfg"; exit 1; }
  safe_wget "${REPO}Cfg/xray.conf" /etc/nginx/conf.d/xray.conf || { echo "Gagal download xray.conf"; exit 1; }
  safe_wget "${REPO}Cfg/nginx.conf" /etc/nginx/nginx.conf || { echo "Gagal download nginx.conf"; exit 1; }

  sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg /etc/nginx/conf.d/xray.conf 2>/dev/null || true

  if [[ -s /etc/xray/xray.crt && -s /etc/xray/xray.key ]]; then
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    chmod 600 /etc/haproxy/hap.pem
  fi

  rm -rf /etc/systemd/system/xray.service.d
  cat >/etc/systemd/system/xray.service <<'EOF'
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

  safe_wget "${REPO}Fls/password" /etc/pam.d/common-password || true
  chmod 644 /etc/pam.d/common-password 2>/dev/null || true

  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration || true
  sed -i 's/^AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config 2>/dev/null || true
  ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

  cat >/etc/systemd/system/rc-local.service <<'EOF'
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=oneshot
ExecStart=/etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  cat >/etc/rc.local <<'EOF'
#!/bin/bash
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || true
exit 0
EOF

  chmod +x /etc/rc.local
  systemctl daemon-reload
  systemctl enable rc-local 2>/dev/null || true
  systemctl start rc-local.service 2>/dev/null || true

  echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || true

  print_success "Password SSH"
}

ins_SSHD() {
  print_install "Memasang SSHD"

  safe_wget "${REPO}Fls/sshd" /etc/ssh/sshd_config || true
  chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
  systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || /etc/init.d/ssh restart 2>/dev/null || true

  print_success "SSHD"
}

ins_dropbear() {
  clear
  print_install "Menginstall Dropbear 2019"

  apt install -y dropbear >/dev/null 2>&1 || true

  systemctl stop dropbear 2>/dev/null || true
  pkill -9 dropbear 2>/dev/null || true
  rm -f /run/dropbear.pid /var/run/dropbear.pid

  wget -O /usr/sbin/dropbear "${REPO}Fls/dropbear2019"

  if [[ ! -s /usr/sbin/dropbear ]]; then
    print_error "Gagal download dropbear2019"
    exit 1
  fi

  chmod 755 /usr/sbin/dropbear
  chown root:root /usr/sbin/dropbear

  /usr/sbin/dropbear -V >/dev/null 2>&1 || {
    print_error "Binary dropbear rusak"
    exit 1
  }

  safe_wget "${REPO}Cfg/dropbear.conf" /etc/default/dropbear || true
  safe_wget "${REPO}Fls/dropbear.service" /etc/systemd/system/dropbear.service || true

  chmod 644 /etc/default/dropbear 2>/dev/null || true
  chmod 644 /etc/systemd/system/dropbear.service 2>/dev/null || true

  install_banner

  systemctl daemon-reload
  systemctl enable dropbear 2>/dev/null || true
  systemctl reset-failed dropbear 2>/dev/null || true
  systemctl restart dropbear

  sleep 1

  if systemctl is-active dropbear >/dev/null 2>&1; then
    print_success "Dropbear 2019"
  else
    print_error "Dropbear gagal berjalan"
    journalctl -u dropbear --no-pager -n 20
    exit 1
  fi
}

udp_mini() {
  print_install "Memasang Service Limit dan UDP Mini"

  safe_wget "${REPO}Fls/limit.sh" /root/limit.sh && chmod +x /root/limit.sh && bash /root/limit.sh || true

  safe_wget "${REPO}Fls/limit-ip" /usr/bin/limit-ip || true
  safe_wget "${REPO}Fls/limit-ip-ssh" /usr/bin/limit-ip-ssh || true

  chmod +x /usr/bin/limit-ip /usr/bin/limit-ip-ssh 2>/dev/null || true
  sed -i 's/\r//' /usr/bin/limit-ip /usr/bin/limit-ip-ssh 2>/dev/null || true

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

  systemctl stop udp-mini-1 udp-mini-2 udp-mini-3 2>/dev/null || true
  pkill -f udp-mini 2>/dev/null || true
  sleep 1

  safe_wget "${REPO}Fls/udp-mini" /usr/local/kyt/udp-mini || true
  chmod +x /usr/local/kyt/udp-mini 2>/dev/null || true

  safe_wget "${REPO}Fls/udp-mini-1.service" /etc/systemd/system/udp-mini-1.service || true
  safe_wget "${REPO}Fls/udp-mini-2.service" /etc/systemd/system/udp-mini-2.service || true
  safe_wget "${REPO}Fls/udp-mini-3.service" /etc/systemd/system/udp-mini-3.service || true

  systemctl unmask limitvmess limitvless limittrojan limitshadowsocks 2>/dev/null || true
  systemctl daemon-reload

  for svc in sship vmip vlip trip udp-mini-1 udp-mini-2 udp-mini-3; do
    systemctl enable --now "$svc" 2>/dev/null || true
  done

  print_success "Limit dan UDP Mini"
}

ssh_slow() {
  print_install "Memasang modul SlowDNS Server"

  safe_wget "${REPO}Fls/nameserver" /tmp/nameserver || true
  chmod +x /tmp/nameserver 2>/dev/null || true
  bash /tmp/nameserver 2>/dev/null | tee /root/install.log || true

  print_success "SlowDNS"
}

ins_vnstat() {
  print_install "Menginstall Vnstat"

  apt install -y vnstat libsqlite3-dev
  systemctl enable vnstat 2>/dev/null || true
  systemctl restart vnstat 2>/dev/null || true

  print_success "Vnstat"
}

ins_openvpn() {
  print_install "Menginstall OpenVPN"

  safe_wget "${REPO}Vpn/openvpn" /root/openvpn || true
  chmod +x /root/openvpn 2>/dev/null || true
  bash /root/openvpn || true
  systemctl restart openvpn 2>/dev/null || /etc/init.d/openvpn restart 2>/dev/null || true

  print_success "OpenVPN"
}

ins_backup() {
  print_install "Memasang Backup Server"

  apt install -y rclone wondershaper msmtp-mta ca-certificates bsd-mailx || true
  mkdir -p /root/.config/rclone

  safe_wget "${REPO}Cfg/rclone.conf" /root/.config/rclone/rclone.conf || true
  safe_wget "${REPO}Fls/ipserver" /etc/ipserver && bash /etc/ipserver || true

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

  safe_wget "${REPO}Fls/bbr.sh" /root/bbr.sh && chmod +x /root/bbr.sh && bash /root/bbr.sh || true

  print_success "Swap 1G dan BBR"
}

ins_Fail2ban() {
  print_install "Menginstall Fail2ban"

  apt install -y fail2ban
  systemctl enable fail2ban 2>/dev/null || true
  systemctl restart fail2ban 2>/dev/null || true

  install_banner

  grep -q "Banner /etc/banner.txt" /etc/ssh/sshd_config 2>/dev/null || echo "Banner /etc/banner.txt" >> /etc/ssh/sshd_config
  sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/banner.txt"@g' /etc/default/dropbear 2>/dev/null || true

  print_success "Fail2ban"
}

ins_epro() {
  print_install "Menginstall ePro WebSocket Proxy"

  systemctl stop ws 2>/dev/null || true
  pkill -f "/usr/bin/ws" 2>/dev/null || true
  sleep 1

  safe_wget "${REPO}Fls/ws" /usr/bin/ws || true
  safe_wget "${REPO}Cfg/tun.conf" /usr/bin/tun.conf || true
  safe_wget "${REPO}Fls/ws.service" /etc/systemd/system/ws.service || true

  chmod +x /usr/bin/ws 2>/dev/null || true
  chmod 644 /usr/bin/tun.conf /etc/systemd/system/ws.service 2>/dev/null || true

  systemctl daemon-reload
  systemctl enable ws 2>/dev/null || true
  systemctl restart ws 2>/dev/null || true

  safe_wget "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" /usr/local/share/xray/geosite.dat || true
  safe_wget "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" /usr/local/share/xray/geoip.dat || true
  safe_wget "${REPO}Fls/ftvpn" /usr/sbin/ftvpn || true
  chmod +x /usr/sbin/ftvpn 2>/dev/null || true

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

  safe_wget "${REPO}Fls/zidan-api.py" /usr/local/sbin/zidan-api.py || true
  safe_wget "${REPO}Fls/zidan-api.service" /etc/systemd/system/zidan-api.service || true

 chmod +x /usr/local/sbin/zidan-api.py 2>/dev/null || true
  dos2unix /usr/local/sbin/zidan-api.py 2>/dev/null || true

  systemctl daemon-reload
  systemctl enable zidan-api 2>/dev/null || true
  systemctl restart zidan-api 2>/dev/null || true

  print_success "HTTP API"
}

menu_install() {
  print_install "Memasang Menu Packet"

  cd /root || exit 1
  rm -rf menu menu.zip

  wget -q -O menu.zip "${REPO}Cdy/menu.zip"

  if [[ ! -s menu.zip ]]; then
    print_error "Gagal download menu.zip"
    exit 1
  fi

  unzip -o menu.zip >/dev/null 2>&1
  chmod +x menu/* 2>/dev/null || true
  mkdir -p /usr/local/sbin
  cp -rf menu/* /usr/local/sbin/
  chmod +x /usr/local/sbin/* 2>/dev/null || true
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
* * * * * root /usr/bin/limit-ip-ssh
EOF

  cat >/etc/cron.d/limxry <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/local/sbin/lock-xray-ip
EOF

  cat >/etc/cron.d/log.nginx <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/1 * * * * root [ -f /var/log/nginx/access.log ] && echo -n > /var/log/nginx/access.log
EOF

  cat >/etc/cron.d/log.xray <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/1 * * * * root [ -f /var/log/xray/access.log ] && echo -n > /var/log/xray/access.log
EOF

  echo "5" > /home/daily_reboot

  chmod 644 /root/.profile /etc/cron.d/* 2>/dev/null || true

  grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
  grep -q "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

  cat >/etc/rc.local <<'EOF'
#!/bin/bash
iptables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
systemctl restart netfilter-persistent 2>/dev/null || true
exit 0
EOF

  chmod +x /etc/rc.local
  systemctl restart cron 2>/dev/null || true

  print_success "Profile dan cron"
}

enable_services() {
  print_install "Enable Service"

  systemctl daemon-reload

  for svc in rc-local cron netfilter-persistent nginx xray dropbear openvpn haproxy ws fail2ban atd sship vmip vlip trip udp-mini-1 udp-mini-2 udp-mini-3; do
    systemctl enable --now "$svc" 2>/dev/null || true
  done

  nginx -t >/dev/null 2>&1 && systemctl restart nginx 2>/dev/null || true
  xray run -test -config /etc/xray/config.json >/dev/null 2>&1 && systemctl restart xray 2>/dev/null || true
  haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1 && systemctl restart haproxy 2>/dev/null || true

  systemctl restart ws 2>/dev/null || true
  systemctl restart dropbear 2>/dev/null || true

  print_success "Enable Service"
}

restart_all() {
  print_install "Restarting All Packet"

  systemctl daemon-reload

  nginx -t >/dev/null 2>&1 && systemctl restart nginx 2>/dev/null || true
  xray run -test -config /etc/xray/config.json >/dev/null 2>&1 && systemctl restart xray 2>/dev/null || true
  haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1 && systemctl restart haproxy 2>/dev/null || true

  systemctl restart openvpn 2>/dev/null || true
  systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
  systemctl restart dropbear 2>/dev/null || true
  systemctl restart fail2ban 2>/dev/null || true
  systemctl restart vnstat 2>/dev/null || true
  systemctl restart cron 2>/dev/null || true
  systemctl restart netfilter-persistent 2>/dev/null || true
  systemctl restart ws 2>/dev/null || true

  rm -f /root/openvpn /root/key.pem /root/cert.pem

  print_success "All Packet"
}

restart_system_notify() {
  return 0
}

final_check() {
  echo ""
  echo -e "${YELLOW}STATUS SERVICE:${NC}"

  for svc in nginx xray haproxy dropbear ws ssh cron atd zidan-api; do
    printf " %-10s : " "$svc"
    systemctl is-active "$svc" 2>/dev/null || echo "inactive"
  done

  echo ""
  echo -e "${YELLOW}PORT CHECK:${NC}"
  ss -tulpn | grep -E ':80|:443|:143|:109|:10015|:5888' || true
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
  install_banner
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
  final_check
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