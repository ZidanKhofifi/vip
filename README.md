# ZIDAN TUNNELING

## Install Ubuntu 22 / Ubuntu 24

Login sebagai **root** lalu jalankan:

```bash
apt update -y && apt upgrade -y
apt install -y wget curl git unzip
wget -q https://raw.githubusercontent.com/ZidanKhofifi/vip/main/main.sh
chmod +x main.sh
bash main.sh
```

---

## Install Cepat (1 Baris)

```bash
apt update -y && apt install -y wget curl git unzip && wget -q https://raw.githubusercontent.com/ZidanKhofifi/vip/main/main.sh && chmod +x main.sh && bash main.sh
```

---

## Persiapan Sebelum Install

Pastikan:

- VPS Ubuntu 22.04 atau Ubuntu 24.04
- Akses Root
- Domain sudah mengarah ke IP VPS (jika menggunakan domain sendiri)
- Port 80 dan 443 tidak dipakai aplikasi lain
- IP VPS sudah terdaftar di `izin-ip-sandz`

---

## Setelah Install

Cek service:

```bash
systemctl status nginx
systemctl status xray
systemctl status haproxy
systemctl status dropbear
systemctl status ws
```

Atau:

```bash
systemctl --type=service --state=running
```

---

## Menu

Masuk menu:

```bash
menu
```

atau

```bash
m
```

(sesuai isi menu.zip)

---

## Update Script

```bash
cd /root
wget -q https://raw.githubusercontent.com/ZidanKhofifi/vip/main/main.sh -O main.sh
chmod +x main.sh
bash main.sh
```

---

## Repository

https://github.com/ZidanKhofifi/vip

---

## Support

ZIDAN TUNNELING
