function port -d "Check what process is using a port"
    if test (count $argv) -eq 0
        echo "用法: port <端口号>"
        return 1
    end
    sudo lsof -i :$argv[1]
end
