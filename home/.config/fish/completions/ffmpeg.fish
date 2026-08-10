# Completions for ffmpeg
complete -c ffmpeg -f

# 基本选项
complete -c ffmpeg -s i -l input -d "Input file" -r
complete -c ffmpeg -s o -l output -d "Output file" -r
complete -c ffmpeg -s f -l format -d "Force format" -r
complete -c ffmpeg -s c -l codec -d "Codec" -r
complete -c ffmpeg -s b -l bitrate -d "Bitrate" -r
complete -c ffmpeg -s r -l framerate -d "Frame rate" -r
complete -c ffmpeg -s s -l size -d "Frame size" -r
complete -c ffmpeg -s ar -l audio-rate -d "Audio sample rate" -r
complete -c ffmpeg -s ac -l audio-channels -d "Audio channels" -r
complete -c ffmpeg -s af -l audio-filter -d "Audio filter" -r
complete -c ffmpeg -s vf -l video-filter -d "Video filter" -r
complete -c ffmpeg -s t -l duration -d "Duration" -r
complete -c ffmpeg -ss -l seek -d "Start position" -r
complete -c ffmpeg -s y -l overwrite -d "Overwrite output"
complete -c ffmpeg -s n -l no-overwrite -d "Never overwrite"
complete -c ffmpeg -l hardwareaccel -d "Hardware acceleration" -r
complete -c ffmpeg -l threads -d "Thread count" -r
complete -c ffmpeg -l preset -d "Encoding preset" -r
complete -c ffmpeg -l crf -d "Constant rate factor" -r
complete -c ffmpeg -s v -l loglevel -d "Log level" -r
complete -c ffmpeg -l hide_banner -d "Hide banner"
complete -c ffmpeg -s h -l help -d "Show help"
complete -c ffmpeg -l version -d "Show version"

# 常用编码器
complete -c ffmpeg -n "__fish_seen_subcommand_from -c:v -c:a" -a "libx264 libx265 libvpx libvpx-vp9 libaom-av1 h264_nvenc hevc_nvenc" -d "Video codec"
complete -c ffmpeg -n "__fish_seen_subcommand_from -c:v -c:a" -a "aac libmp3lame libopus libvorbis flac" -d "Audio codec"

# 常用格式
complete -c ffmpeg -n "__fish_seen_subcommand_from -f" -a "mp4 mkv avi mov flac mp3 aac wav webm" -d "Format"

# 常用滤镜
complete -c ffmpeg -n "__fish_seen_subcommand_from -vf -af" -a "scale crop rotate transpose fade overlay" -d "Video filter"
complete -c ffmpeg -n "__fish_seen_subcommand_from -af" -a "volume fade atrimiter aecho chorus" -d "Audio filter"
