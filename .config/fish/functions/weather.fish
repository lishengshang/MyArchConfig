function weather -d "Show current weather (default: Wuhan)"
    set -l loc Wuhan
    if test (count $argv) -gt 0
        set loc $argv[1]
    end
    curl -s "wttr.in/$loc?F&lang=zh" | head -30
end
