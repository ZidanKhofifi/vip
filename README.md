### ⚠️ INSTALL SCRIPT ⚠️
<pre><code>apt update -y && \
apt install -y wget curl ruby lolcat && \
gem install lolcat && \
wget -q https://raw.githubusercontent.com/ZidanKhofifi/vip/main/main.sh && \
chmod +x main.sh && \
bash main.sh</code></pre>

### ⚠️ UPDATE SCRIPT ⚠️
<pre><code>wget -q https://raw.githubusercontent.com/ZidanKhofifi/vip/main/update.sh && \
chmod +x update.sh && \
bash update.sh</code></pre>

### ZIDAN VPN HTTP API DOCUMENTATION

Base URL:

http://IP-VPS:5888

atau

http://DOMAIN:5888

Authentication Header:

x-api-key: TOKEN_API_KAMU

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ROOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GET /

Cek status API.

Response:

{
  "status": "online",
  "service": "Zidan VPN API"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /ssh/create

Headers:
Content-Type: application/json
x-api-key: TOKEN_API_KAMU

Body:

{
  "username": "zidan",
  "password": "12345",
  "ip_limit": 2,
  "expired_days": 30
}

Response:

{
  "status": "success",
  "username": "zidan",
  "password": "12345",
  "domain": "vpn.domain.com",
  "ip_limit": "2",
  "expired_date": "2026-06-25",
  "ssh_ws": "vpn.domain.com:80@zidan:12345",
  "ssh_ssl": "vpn.domain.com:443@zidan:12345",
  "udp_custom": "vpn.domain.com:1-65535@zidan:12345",
  "account_url": "https://vpn.domain.com:81/ssh-zidan.txt"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RENEW SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /ssh/renew

Body:

{
  "username": "zidan",
  "days": 30
}

Response:

{
  "status": "success",
  "username": "zidan",
  "days_added": "30",
  "expired_date": "24 Jun 2026"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DELETE SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /ssh/delete

Body:

{
  "username": "zidan"
}

Response:

{
  "status": "success",
  "username": "zidan",
  "message": "User deleted successfully"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UNLOCK SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /ssh/unlock

Body:

{
  "username": "zidan"
}

Response:

{
  "status": "success",
  "username": "zidan",
  "account_status": "UNLOCKED"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TRIAL SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /ssh/trial

Body:

{
  "minutes": 10
}

Response:

{
  "status": "success",
  "type": "trial",
  "username": "Trial-ABCD",
  "password": "1",
  "expired_minutes": "10",
  "ssh_ws": "vpn.domain.com:80@Trial-ABCD:1",
  "ssh_ssl": "vpn.domain.com:443@Trial-ABCD:1"
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MEMBER SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GET /ssh/member

Response:

{
  "status": "success",
  "total_users": 2,
  "users": [
    {
      "username": "zidan",
      "expired": "Jun 25, 2026",
      "status": "UNLOCKED"
    }
  ]
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ONLINE SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GET /ssh/online

Response:

{
  "status": "success",
  "dropbear": [
    {
      "pid": "1234",
      "username": "zidan",
      "ip": "1.1.1.1"
    }
  ],
  "openssh": []
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DELETE EXPIRED SSH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DELETE /ssh/expired

Response:

{
  "status": "success",
  "deleted_count": 1,
  "deleted_users": [
    {
      "username": "expireduser",
      "expired": "20 May 2026"
    }
  ]
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SWAGGER DOCS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

http://IP-VPS:5888/docs

atau

http://DOMAIN:5888/docs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ERROR RESPONSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unauthorized:

{
  "detail": "Unauthorized"
}

User Not Found:

{
  "status": "error",
  "message": "User not found"
}

Invalid Request:

{
  "status": "error",
  "message": "Usage error"
}