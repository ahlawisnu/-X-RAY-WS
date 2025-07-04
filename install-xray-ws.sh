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
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh )" @ install

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
