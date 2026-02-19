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
    
    echo ">>> $name güncelleniyor..."

    # 1. Yöntem: Direkt yönlendirme başlığını (Location) çekmeyi dene
    # --max-time ekledik çünkü YouTube bazen geç yanıt verir
    raw_manifest=$(curl -sI --max-time 15 "$target_url" | grep -i "location:" | sed 's/[Ll]ocation: //g' | tr -d '\r' | xargs)

    # 2. Yöntem: Eğer Location boşsa, içeriği indirip içinden linki ayıkla (Fallback)
    if [ -z "$raw_manifest" ]; then
        echo "    [!] Başlık alınamadı, içerik taranıyor..."
        raw_manifest=$(curl -sL --max-time 20 "$target_url" | grep -oE "https://manifest.googlevideo.com/[^ ]+" | head -n 1 | tr -d '\r' | xargs)
    fi

    if [ ! -z "$raw_manifest" ] && [[ "$raw_manifest" == http* ]]; then
        echo "#EXTM3U" > "playlist/${name}.m3u8"
        echo "#EXT-X-VERSION:3" >> "playlist/${name}.m3u8"
        echo "$raw_manifest" >> "playlist/${name}.m3u8"
        echo "    [OK] $name başarıyla alındı."
    else
        echo "    [!!] HATA: $name linki hiçbir yöntemle çekilemedi!"
    fi
done

# Ana Playlist Oluştur
echo ">>> Ana liste hazırlanıyor..."
echo "#EXTM3U" > playlist/playlist.m3u
for file in playlist/*.m3u8; do
    [ -e "$file" ] || continue
    fname=$(basename "$file" .m3u8)
    echo "#EXTINF:-1,$fname" >> playlist/playlist.m3u
    echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/playlist/${fname}.m3u8" >> playlist/playlist.m3u
done

# GitHub
git add .
if ! git diff-index --quiet HEAD --; then
    git commit -m "Hibrit Güncelleme: $(date +'%H:%M')"
    git push origin HEAD:main --force
fi
