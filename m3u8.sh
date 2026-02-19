#!/bin/bash

PROJE_DIR="/root/tecotv"
cd $PROJE_DIR || exit 1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Playlist Klasör Hazırlığı
mkdir -p playlist
rm -f playlist/*.m3u8

# Kanalları işle
cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    target_url=$(echo "$i" | jq -r '.url')
    
    echo ">>> $name güncelleniyor..."

    # 1. Başlığı (Header) çek
    # 2. İçinde 'https://manifest.googlevideo.com' geçen satırı bul
    # 3. Sadece linki temizle (başına/sonuna gelen görünmez karakterleri at)
    raw_manifest=$(curl -sI --max-time 25 "$target_url" | grep -o "https://manifest.googlevideo.com[^[:space:]]*" | head -n 1 | tr -d '\r\n')

    if [ ! -z "$raw_manifest" ] && [[ "$raw_manifest" == http* ]]; then
        # Dosyayı yaz
        echo "#EXTM3U" > "playlist/${name}.m3u8"
        echo "#EXT-X-VERSION:3" >> "playlist/${name}.m3u8"
        echo "$raw_manifest" >> "playlist/${name}.m3u8"
        echo " [OK] $name dosyaya yazıldı."
    else
        echo " [!] HATA: $name için Google Manifest linki bulunamadı!"
        # Debug için sunucunun tam başlığını görelim:
        # curl -sI "$target_url"
    fi
    
    sleep 1
done

# Ana Playlist Oluştur
echo ">>> Ana playlist birleştiriliyor..."
echo "#EXTM3U" > playlist/playlist.m3u
for file in playlist/*.m3u8; do
    [ -s "$file" ] || continue
    fname=$(basename "$file" .m3u8)
    
    # Sadece link içeren dosyaları ana listeye ekle
    if grep -q "googlevideo" "$file"; then
        echo "#EXTINF:-1,$fname" >> playlist/playlist.m3u
        echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/playlist/${fname}.m3u8" >> playlist/playlist.m3u
    fi
done

# GitHub Push
git add .
if ! git diff-index --quiet HEAD --; then
    git commit -m "Final Regex Fix: $(date +'%H:%M')"
    git push origin HEAD:main --force
    echo ">>> GitHub'a başarıyla gönderildi."
else
    echo ">>> Yeni veri yok."
fi
