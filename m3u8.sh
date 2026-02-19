#!/bin/bash

PROJE_DIR="/root/tecotv"
cd $PROJE_DIR || exit 1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Playlist Hazırlığı
mkdir -p playlist
rm -f playlist/*.m3u8

# Kanalları işle
cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    target_url=$(echo "$i" | jq -r '.url')
    
    echo ">>> $name için Yönlendirme Linki alınıyor..."

    # -I: Sadece başlıkları (headers) çek
    # grep -i "location:": Location satırını bul
    # sed: 'location:' kelimesini sil ve temiz linki bırak
    raw_manifest=$(curl -sI "$target_url" | grep -i "location:" | sed 's/[Ll]ocation: //g' | tr -d '\r' | xargs)

    if [ ! -z "$raw_manifest" ] && [[ "$raw_manifest" == http* ]]; then
        echo "#EXTM3U" > "playlist/${name}.m3u8"
        echo "#EXT-X-VERSION:3" >> "playlist/${name}.m3u8"
        echo "$raw_manifest" >> "playlist/${name}.m3u8"
        echo " [OK] $name güncellendi."
    else
        echo " [!] HATA: $name için yönlendirme adresi alınamadı!"
        echo " Denenen URL: $target_url"
    fi
done

# Ana Playlist Oluştur (GitHub Raw Linkleri ile)
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
    git commit -m "Manifest Redirect Update: $(date +'%H:%M')"
    git push origin HEAD:main --force
    echo ">>> GitHub'a gönderildi."
else
    echo ">>> Değişiklik yok."
fi
