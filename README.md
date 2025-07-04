# SCRIPT TUNNEL X-RAY-WS

Berikut adalah panduan lengkap untuk membuat **script otomatis di VPS** yang bertujuan untuk:

- Menginstal Xray (implementasi resmi dari Xtls/Xray yang mendukung protokol VMess dan WebSocket).
- Membuat konfigurasi tunneling VMess over WebSocket.
- Menjalankan service sebagai daemon.

> ✅ **Catatan:**  
> - Pastikan kamu menggunakan VPS Linux (misalnya Ubuntu 20.04/22.04 atau Debian 11+).  
> - Script ini hanya untuk keperluan edukasi dan administrasi server pribadi.  
> - Jangan gunakan untuk aktivitas ilegal atau melanggar ketentuan penyedia layanan cloud.

---

## 🧰 Persyaratan Awal

Pastikan VPS sudah memiliki:
- Akses root atau sudo
- Port `80` & `443` bebas (tidak digunakan oleh Apache, Nginx, dll)
- Domain terarah ke IP VPS untuk SSL/TLS

---

## 📜 Script Instalasi Tunnel VMess WebSocket

Simpan script berikut dalam file, misalnya `install-xray-ws.sh`, lalu jalankan dengan perintah:  
```bash
chmod +x install-xray-ws.sh && ./install-xray-ws.sh
```

### 🔽 Script Install VMess WebSocket

```bash
#!/bin/bash

# Variabel Konfigurasi
UUID=$(cat /proc/sys/kernel/random/uuid)
DOMAIN="yourdomain.com"   # Ganti dengan domain Anda
WSPATH="/vmess"           # WebSocket Path
PORT=443                  # Port TLS

echo "🔧 Memulai instalasi Xray..."

# Update sistem
apt update && apt upgrade -y

# Instal dependensi
apt install curl wget unzip nginx certbot python3-certbot-nginx -y

# Hapus Nginx default
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

# Instalasi Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Generate Certificate
echo "🔐 Mendapatkan sertifikat SSL..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
systemctl stop nginx
sleep 5
systemctl start nginx

# Buat config Xray
cat << EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0,
            "alterId": 0
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WSPATH"
        },
        "security": "tls",
        "tlsSettings": {
          "serverName": "$DOMAIN",
          "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
          "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

# Restart Xray
systemctl restart xray

# Cek status Xray
systemctl enable xray
if systemctl is-active --quiet xray; then
  echo "✅ Xray berhasil diinstal dan diaktifkan."
else
  echo "❌ Terjadi kesalahan saat menjalankan Xray."
  exit 1
fi

# Tampilkan info koneksi
echo "🌐 Informasi Koneksi:"
echo "Domain     : $DOMAIN"
echo "Port       : $PORT"
echo "UUID       : $UUID"
echo "Path       : $WSPATH"
echo ""
echo "📋 Link VMess (Gunakan di client seperti V2RayN, NekoBox, dll):"
echo "vmess://$(echo -n "{\"add\":\"$DOMAIN\",\"aid\":\"0\",\"host\":\"$DOMAIN\",\"id\":\"$UUID\",\"net\":\"ws\",\"path\":\"$WSPATH\",\"port\":\"$PORT\",\"ps\":\"VMESS-WSS\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}" | base64 -w0)"

echo ""
echo "🎉 Instalasi selesai!"
```

---

## 💡 Cara Penggunaan

Setelah script di atas dijalankan:
1. Buka browser → kunjungi `https://DOMAIN_ANDA` → jika muncul halaman default Nginx, itu artinya SSL berhasil.
2. Salin link VMess dari output script dan impor ke aplikasi V2Ray client kamu.
3. Pastikan firewall/VPC rule mengizinkan port `80` dan `443`.

---

## 🔄 Auto-Renew SSL

Certbot akan secara otomatis memperbarui sertifikat setiap 90 hari. Untuk mengeceknya:

```bash
certbot renew --dry-run
```

---

## ❌ Catatan Penting

- Jika menggunakan CDN (seperti Cloudflare), pastikan mode proxy OFF agar bisa dapat sertifikat SSL langsung.
- Gunakan domain aktif yang point ke IP VPS.
- Jika ingin menambah pengguna atau UUID, edit file `/usr/local/etc/xray/config.json` dan tambahkan `"clients"` baru.

---

Jika kamu ingin versi dengan **multipath**, **multiuser**, atau **panel manajemen seperti XUI**, saya juga bisa bantu buatkan script tambahannya.

Mau lanjut ke bagian itu?
