function extract -d "Universal archive extractor"
    if test (count $argv) -eq 0
        echo "用法: extract <压缩文件>"
        return 1
    end

    for file in $argv
        if not test -f $file
            echo "错误: '$file' 不是有效文件"
            continue
        end

        switch $file
            case '*.tar.bz2' '*.tbz2'
                tar xjf $file
            case '*.tar.gz' '*.tgz'
                tar xzf $file
            case '*.tar.xz' '*.txz'
                tar xJf $file
            case '*.tar.zst'
                tar --use-compress-program=unzstd -xf $file
            case '*.tar'
                tar xf $file
            case '*.bz2'
                bunzip2 $file
            case '*.gz'
                gunzip $file
            case '*.xz'
                unxz $file
            case '*.zst'
                unzstd $file
            case '*.rar'
                unrar x $file
            case '*.zip'
                unzip $file
            case '*.7z'
                7z x $file
            case '*.Z'
                uncompress $file
            case '*'
                echo "错误: '$file' 无法被 extract 处理"
                return 1
        end
    end
end
