# ~/.config/zsh/translate.zsh
# translate-shell — 中英互译配置

if command -v trans &> /dev/null; then

    # ── 主函数：trans hello → 译成中文 ──────────────────────────
    # 必须显式传 -engine bing，因为 TRANS_OPTIONS 不存在（trans 不认这个变量）
    function trans() {
        command trans -brief -no-ansi -no-autocorrect -engine bing :zh "$@"
    }

    # ── Alt+t：翻译光标处单词 → 中文 ────────────────────────────
    function _translate_word() {
        if [[ -z "$BUFFER" ]]; then
            return
        fi
        # 提取光标所在单词
        local before="${BUFFER:0:$CURSOR}"
        local after="${BUFFER:$CURSOR}"
        local word="${before##*[^[:alnum:]_-]}${after%%[^[:alnum:]_-]*}"
        if [[ -n "$word" ]]; then
            local result
            result=$(command trans -brief -no-ansi -no-autocorrect -engine bing :zh "$word" 2>/dev/null)
            if [[ -n "$result" ]]; then
                zle -M "📖 $word → $result"
            fi
        fi
    }
    zle -N _translate_word
    bindkey '^[t' _translate_word

    # ── Alt+T：弹窗输入翻译 ─────────────────────────────────────
    function _translate_input() {
        local word=""
        vared -p "输入翻译内容: " word
        if [[ -n "$word" ]]; then
            local result
            result=$(command trans -brief -no-ansi -no-autocorrect -engine bing :zh "$word" 2>/dev/null)
            if [[ -n "$result" ]]; then
                zle -M "📖 $word → $result"
            else
                zle -M "翻译失败，请检查网络"
            fi
        fi
        zle redisplay
    }
    zle -N _translate_input
    bindkey '^[T' _translate_input

fi

# ── 别名：直接调 command trans，绕过函数，避免重复传语言码 ──────
alias t='trans'                                                       # → 中文
alias tz='command trans -brief -no-ansi -no-autocorrect -engine bing :zh'
alias te='command trans -brief -no-ansi -no-autocorrect -engine bing :en'
