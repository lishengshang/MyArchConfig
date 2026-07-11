function _f_get_random_url -d "Get a random anime girl image URL"
    set -l RAND (math (random) % 3 + 1)
    switch $RAND
        case 1
            curl -s --connect-timeout 5 --max-time 15 "https://api.waifu.im/images?IncludedTags=waifu&IsNsfw=false" | jq -r '.images[0].url'
        case 2
            curl -s --connect-timeout 5 --max-time 15 "https://nekos.best/api/v2/waifu" | jq -r '.results[0].url'
        case 3
            curl -s --connect-timeout 5 --max-time 15 "https://api.waifu.pics/sfw/waifu" | jq -r '.url'
    end
end
