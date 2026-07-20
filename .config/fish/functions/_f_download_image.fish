function _f_download_image -a cache_dir -d "Download a random anime girl image to cache_dir"
    if test -z "$cache_dir"
        return 1
    end
    set -l URL (_f_get_random_url)
    if string match -qr "^http" -- "$URL"
        set -l FILENAME "waifu_"(date +%s%N)"_"(random)".jpg"
        set -l TARGET_PATH "$cache_dir/$FILENAME"
        curl -s -L --connect-timeout 5 --max-time 15 -o "$TARGET_PATH" "$URL"
        if test -s "$TARGET_PATH"
            if command -q file
                if not file --mime-type "$TARGET_PATH" | grep -q "image/"
                    rm -f "$TARGET_PATH"
                end
            end
        else
            rm -f "$TARGET_PATH"
        end
    end
end
