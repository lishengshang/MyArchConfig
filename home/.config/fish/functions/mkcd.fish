function mkcd -d "Create directory and cd into it"
    if test (count $argv) -eq 0
        echo "用法: mkcd <目录>"
        return 1
    end
    mkdir -p $argv[1]; and cd $argv[1]
end
