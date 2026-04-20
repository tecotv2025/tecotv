#!/bin/bash
# Proje dizinine git
cd /root/tecotv/
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Git Güvenlik Ayarı: "Detached HEAD" hatalarını önlemek için
git checkout main || git checkout -b main

# Gereken paketleri kur (Zaten yüklüyse hızlı geçer)
sudo apt update -qq
sudo apt install -y jq curl git > /dev/null

# Playlist klasörünü oluştur ve temizle
mkdir -p playlist
rm -f playlist/*.m3u8

# M3U8 dosyalarını indir
cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    url=$(echo "$i" | jq -r '.url')
    echo "📥 $name indiriliyor..."
    curl -sSL "$url" \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
        -H "Referer: https://live.artofknot.com/" \
        -o "playlist/${name}.m3u8"
done

# Ana playlist.m3u dosyasını oluştur
echo "#EXTM3U" > playlist.m3u
for file in playlist/*.m3u8; do
    [ -e "$file" ] || continue
    name=$(basename "$file" .m3u8)
    echo "#EXTINF:-1,$name" >> playlist.m3u
    echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/$file" >> playlist.m3u
done

# Dosyayı taşı
mv playlist.m3u playlist/playlist.m3u

# --- GİT İŞLEMLERİ ---
git add .
# Eğer değişiklik varsa commit et
if ! git diff-index --quiet HEAD --; then
    git commit -m "✅ Playlist dosyaları güncellendi: $(date)"
    # GitHub'a her zaman ana dal üzerinden zorla gönder
    git push origin HEAD:main --force
else
    echo "Değişiklik yok, push atlanıyor."
fi
