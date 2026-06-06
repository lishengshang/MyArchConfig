" fcitx5 自动切换输入法
" 离开插入模式或进入命令行时自动切换到英文
" 记住插入模式前的输入法状态，回到插入模式时恢复
if executable('fcitx5-remote')
  let s:fcitx5_prev = 0
  augroup fcitx5_switch
    autocmd!
    autocmd InsertLeave * let s:fcitx5_prev = str2nr(system('fcitx5-remote')) | call system('fcitx5-remote -c')
    autocmd CmdlineEnter * let s:fcitx5_prev = str2nr(system('fcitx5-remote')) | call system('fcitx5-remote -c')
    autocmd InsertEnter * if s:fcitx5_prev == 2 | call system('fcitx5-remote -o') | endif
  augroup END
endif
