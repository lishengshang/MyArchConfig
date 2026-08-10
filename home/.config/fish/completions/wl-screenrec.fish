complete -c wl-screenrec -s f -l filename -d 'filename to write to. container type is detected from extension' -r
complete -c wl-screenrec -s g -l geometry -d 'geometry to capture, format x,y WxH. Compatible with the output of `slurp`. Mutually exclusive with --output' -r
complete -c wl-screenrec -s o -l output -d 'Which output (display) to record. Mutually exclusive with --geometry. Defaults to your only display if you only have one' -r
complete -c wl-screenrec -s m -l max-fps -d 'limit maximum framerate into the encoder. Note that by default, wl-screenrec only copies frames when the contents have changed, so it can drop below this' -r
complete -c wl-screenrec -l dri-device -d 'which dri device to use for vaapi. by default, this is obtained from the linux-dmabuf-v1 protocol when using wlr-screencopy, and from ext-image-copy-capture-session if using ext-image-copy-capture, if present. if not present, /dev/dri/renderD128 is guessed' -r
complete -c wl-screenrec -l low-power -r -f -a "auto\t''
on\t''
off\t''"
complete -c wl-screenrec -l codec -d 'which video codec to use. Ignored if `--ffmpeg-encoder` is supplied' -r -f -a "auto\t''
avc\t''
hevc\t''
vp8\t''
vp9\t''
av1\t''"
complete -c wl-screenrec -l ffmpeg-muxer -d 'Which ffmpeg muxer to use. Guessed from output filename by default' -r
complete -c wl-screenrec -l ffmpeg-muxer-options -d 'Options to pass to the muxer. Format looks like key=val,key2=val2' -r
complete -c wl-screenrec -l ffmpeg-encoder -d 'Use this to force a particular ffmpeg encoder. Generally, this is not necessary and the combo of --codec and --hw can get you to where you need to be' -r
complete -c wl-screenrec -l ffmpeg-encoder-options -d 'Options to pass to the encoder. Format looks like key=val,key2=val2' -r
complete -c wl-screenrec -l audio-codec -d 'Which audio codec to use. Ignored if `--ffmpeg-audio-encoder` is supplied' -r -f -a "auto\t''
aac\t''
mp3\t''
flac\t''
opus\t''"
complete -c wl-screenrec -l audio-bitrate -d 'audio bitrate to encode at. Unit is bytes per second, 16 kB is 128 kbps' -r
complete -c wl-screenrec -l ffmpeg-audio-encoder -d 'Use this to force a particular audio ffmpeg encoder. By default, this is guessed from the muxer (which is guess by the file extension if --ffmpeg-muxer isn\'t passed)' -r
complete -c wl-screenrec -l encode-pixfmt -d 'which pixel format to encode with. not all codecs will support all pixel formats. This should be a ffmpeg pixel format string, like nv12 or x2rgb10. If the encoder supports vaapi memory, it will use this pixel format type but in vaapi memory' -r
complete -c wl-screenrec -l encode-resolution -d 'what resolution to encode at. example: 1920x1080. Default is the resolution of the captured region. If your goal is reducing filesize, it\'s suggested to try --bitrate/-b first' -r
complete -c wl-screenrec -s b -l bitrate -d 'bitrate to encode at. Unit is bytes per second, so 5 MB is 40 Mbps' -r
complete -c wl-screenrec -l history -d 'run in a mode where the screen is recorded, but nothing is written to the output file until SIGUSR1 is sent to the process. Then, it writes the most recent N seconds to a file and continues recording' -r
complete -c wl-screenrec -l audio-device -d 'which audio device to record from. list devices with `pactl list short sources`' -r
complete -c wl-screenrec -l audio-backend -d 'which ffmpeg audio capture backend (see https://ffmpeg.org/ffmpeg-devices.html`) to use. you almost certainally want to specify --audio-device if you use this, as the values depend on the backend used' -r
complete -c wl-screenrec -l gop-size -d 'GOP (group of pictures) size' -r
complete -c wl-screenrec -l generate-completions -d 'print completions for the specified shell to stdout' -r -f -a "bash\t''
elvish\t''
fish\t''
powershell\t''
zsh\t''"
complete -c wl-screenrec -l capture-backend -d 'which capture backend to use' -r -f -a "auto\t''
wlr-screencopy\t''
ext-image-copy-capture\t''"
complete -c wl-screenrec -l no-hw -d 'don\'t use the GPU encoder, download the frames onto the CPU and use a software encoder. Ignored if `encoder` is supplied'
complete -c wl-screenrec -l no-cursor -d 'don\'t capture the cursor'
complete -c wl-screenrec -s v -l verbose -d 'add very loud logging. can be specified multiple times'
complete -c wl-screenrec -l audio -d 'record audio with the stream. Defaults to the default audio capture device'
complete -c wl-screenrec -l no-damage -d 'copy every frame, not just unique frames. This can be helpful to get a non-variable framerate video, but is generally discouraged as it uses much more resources. Useful for testing'
complete -c wl-screenrec -l experimental-vulkan -d 'use vulkan allocator & encode'
complete -c wl-screenrec -s h -l help -d 'Print help'
complete -c wl-screenrec -s V -l version -d 'Print version'
