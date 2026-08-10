function gitignore -d "Generate .gitignore for given language(s)"
    if test (count $argv) -eq 0
        echo "用法: gitignore <language1,language2,...>"
        echo "示例: gitignore python,node,macos"
        echo "查看可用模板: gitignore list"
        return 1
    end

    if test "$argv[1]" = list
        curl -sL https://www.toptal.com/developers/gitignore/api/list | tr ',' '\n' | column
        return 0
    end

    set -l lang (string join , $argv)
    curl -sL "https://www.toptal.com/developers/gitignore/api/$lang"
end
