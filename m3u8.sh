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
    
    echo ">>> $name için Header üzerinden link alınıyor..."

    # ÖNEMLİ: -L (yönlendirme) KULLANMIYORUZ. Sadece -I (Header) alıyoruz.
    # grep ile Location satırını bulup temizliyoruz.
    raw_manifest=$(curl -sI --max-time 20 "$target_url" | grep -i "^location:" | awk '{print $2}' | tr -d '\r' | xargs)

    if [ ! -z "$raw_manifest" ] && [[ "$raw_manifest" == http* ]]; then
        echo "#EXTM3U" > "playlist/${name}.m3u8"
        echo "#EXT-X-VERSION:3" >> "playlist/${name}.m3u8"
        echo "$raw_manifest" >> "playlist/${name}.m3u8"
        echo " [OK] $name başarıyla yakalandı."
    else
        echo " [!] HATA: $name için Header linki boş döndü!"
        # Alternatif deneme (Bazen küçük-büyük harf fark eder)
        raw_manifest=$(curl -sI "$target_url" | grep -i "Location:" | cut -d' ' -f2- | tr -d '\r' | xargs)
        if [ ! -z "$raw_manifest" ]; then
             echo "#EXTM3U" > "playlist/${name}.m3u8"
             echo "$raw_manifest" >> "playlist/${name}.m3u8"
             echo " [OK] $name (Alternatif) yakalandı."
        fi
    fi
    # Sunucuya aşırı yüklenmemek için küçük bir es
    sleep 1
done

# Ana Playlist Oluştur
echo ">>> Ana playlist oluşturuluyor..."
echo "#EXTM3U" > playlist/playlist.m3u
for file in playlist/*.m3u8; do
    [ -e "$file" ] || continue
    fname=$(basename "$file" .m3u8)
    echo "#EXTINF:-1,$fname" >> playlist/playlist.m3u
    echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/playlist/${fname}.m3u8" >> playlist/playlist.m3u
done

# GitHub Push
git add .
if ! git diff-index --quiet HEAD --; then
    git commit -m "Fixed Header Fetch: $(date +'%H:%M')"
    git push origin HEAD:main --force
    echo ">>> GitHub'a başarıyla gönderildi."
else
    echo ">>> Değişiklik yok, push atlanıyor."
fi
