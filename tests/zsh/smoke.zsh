#!/usr/bin/env zsh
# =============================================================================
# smoke.zsh - functional smoke assertions, runs INSIDE an interactive zsh.
#
# Invoked by smoke.sh via a pty with a 2s idle window so zinit turbo plugins
# (fzf-tab, autosuggestions, fsh, forgit, history-substring-search) get loaded
# by the real zle event loop. Everything here prints SMOKE_PASS / SMOKE_FAIL
# lines and a final SMOKE_SUMMARY.
#
# This file is the REGRESSION CONTRACT: it must stay green for any config
# change. Update it (in the same commit) only when behavior intentionally
# changes.
# =============================================================================

typeset -gi PASS=0 FAIL=0
typeset -ga FAILED_NAMES=()

# check <name> <zsh test expression>  -- passes when the expression succeeds
check() {
    if eval "$2" >/dev/null 2>&1; then
        print -r -- "SMOKE_PASS $1"
        (( PASS++ ))
    else
        print -r -- "SMOKE_FAIL $1"
        (( FAIL++ ))
        FAILED_NAMES+=("$1")
    fi
}

# ---------------------------------------------------------------------------
# B. Core tools present
# ---------------------------------------------------------------------------
check "tool:cd=zoxide"      '(( ${+functions[cd]} ))'
# mise: shims mode (2026-08) - no hook function; PATH must contain shims dir
check "tool:mise"           '(( $+commands[mise] )) && [[ ${PATH-} == *mise/shims* ]]'
check "tool:direnv"         '(( ${+functions[_direnv_hook]} ))'
check "tool:atuin"          '(( ${+widgets[atuin-search]} ))'
check "tool:carapace"       '(( $+commands[carapace] ))'
check "tool:starship"       '(( $+commands[starship] ))'
check "tool:fzf"            '(( $+commands[fzf] ))'
check "tool:eza"            '(( $+commands[eza] ))'
check "tool:bat"            '(( $+commands[bat] ))'
check "tool:rg"             '(( $+commands[rg] ))'
check "tool:fd"             '(( $+commands[fd] ))'
check "tool:forgit"         '(( ${+functions[forgit::add]} ))'

# ---------------------------------------------------------------------------
# C. Completions registered in _comps (carapace bridges opencode/uv/gh)
# ---------------------------------------------------------------------------
check "comps:git"           '(( ${+_comps[git]} ))'
check "comps:systemctl"     '(( ${+_comps[systemctl]} ))'
check "comps:docker"        '(( ${+_comps[docker]} ))'
check "comps:uv"            '(( ${+_comps[uv]} ))'
check "comps:opencode"      '(( ${+_comps[opencode]} ))'
check "comps:gh"            '(( ${+_comps[gh]} ))'

# ---------------------------------------------------------------------------
# D. zsh-abbr store loaded
# ---------------------------------------------------------------------------
check "abbr:count>=50"      '(( ${+functions[abbr]} )) && (( $(abbr list-abbreviations 2>/dev/null | wc -l) >= 50 ))'

# ---------------------------------------------------------------------------
# E. Bindings (turbo widgets must be loaded by now; smoke.sh waits 2s idle)
# NOTE: `bindkeys` assoc-array subscript with quotes is parsed as MATH
# (`'^R'` → "bad math expression"), so use `bindkey` command output instead.
# ---------------------------------------------------------------------------
check "bind:^R=atuin-search"        "[[ \$(bindkey '^R') == *atuin-search* ]]"
check "bind:^I=fzf-tab-complete"    "[[ \$(bindkey '^I') == *fzf-tab-complete* ]]"
check "bind:^P=history-substr-up"   "[[ \$(bindkey '^P') == *history-substring-search-up* ]]"
check "bind:^ =autosuggest-accept"  "[[ \$(bindkey '^ ') == *autosuggest-accept* ]]"
check "bind:↑=history-substr-up"    "[[ \$(bindkey '^[[A') == *history-substring-search-up* ]]"

# ---------------------------------------------------------------------------
# F. Prompt (starship)
# ---------------------------------------------------------------------------
check "prompt:PROMPT-set"   '[[ -n ${PROMPT-} ]]'
check "prompt:starship-hook" '(( ${+functions[prompt_starship_precmd]} ))'
check "prompt:starship-owns" '[[ ${PROMPT-} == *starship* ]]'

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print -r -- "SMOKE_SUMMARY $PASS passed, $FAIL failed"
(( ${#FAILED_NAMES[@]} )) && print -r -- "SMOKE_FAILED ${(j:, :)FAILED_NAMES}"
(( FAIL == 0 ))
