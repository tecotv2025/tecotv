#!/bin/bash
cd /home/tecotv/  # script hangi dizinden çalışıyorsa
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Gereken paketleri kur
sudo apt update
sudo apt install -y jq curl git

# Playlist klasörünü oluştur ve temizle
mkdir -p playlist
rm -f playlist/*

# M3U8 dosyalarını indir
cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    url=$(echo "$i" | jq -r '.url')
    echo "📥 $name indiriliyor..."
    curl -sSL "$url" \
        -H "User-Agent: Mozilla/5.0" \
        -H "Referer: https://live.artofknot.com/" \
        -o "playlist/${name}.m3u8"
done

# Ana playlist.m3u dosyasını oluştur
echo "#EXTM3U" > playlist.m3u
for file in playlist/*.m3u8; do
    name=$(basename "$file" .m3u8)
    echo "#EXTINF:-1,$name" >> playlist.m3u
    echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/$file" >> playlist.m3u
done

# playlist.m3u'yu da playlist klasörüne koy
mv playlist.m3u playlist/playlist.m3u

# Git işlemleri
git add playlist
git commit -m "✅ Playlist dosyaları güncellendi: $(date)"
git push origin main
