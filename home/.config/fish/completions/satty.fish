complete -c satty -s c -l config -d 'Path to the config file. Otherwise will be read from XDG_CONFIG_DIR/satty/config.toml' -r
complete -c satty -s f -l filename -d 'Path to input image or \'-\' to read from stdin' -r
complete -c satty -l fullscreen -d 'Start Satty in fullscreen mode. Since 0.20.1, takes optional parameter. --fullscreen without parameter is equivalent to --fullscreen current. Mileage may vary depending on compositor' -r -f -a "all\t''
current-screen\t''"
complete -c satty -l resize -d 'Resize to coordinates or use smart mode (0.20.1). --resize without parameter is equivalent to --resize smart [possible values: smart, WxH.]' -r
complete -c satty -s o -l output-filename -d 'Filename to use for saving action or \'-\' to print to stdout. Omit to disable saving to file. Might contain format specifiers: <https://docs.rs/chrono/latest/chrono/format/strftime/index.html>. Since 0.20.0, can contain tilde (~) for home dir' -r
complete -c satty -l early-exit -d 'Exit directly after save action. 0.21.0: changed to accommodate different triggers' -r -f -a "all\t''
copy\t''
save\t''
save-as\t''"
complete -c satty -l corner-roundness -d 'Draw corners of rectangles round if the value is greater than 0 (Defaults to 12) (0 disables rounded corners)' -r
complete -c satty -l initial-tool -l init-tool -d 'Select the tool on startup' -r -f -a "pointer\t''
crop\t''
line\t''
arrow\t''
rectangle\t''
ellipse\t''
text\t''
marker\t''
blur\t''
highlight\t''
brush\t''"
complete -c satty -l copy-command -d 'Configure the command to be called on copy, for example `wl-copy`' -r
complete -c satty -l annotation-size-factor -d 'Increase or decrease the size of the annotations' -r
complete -c satty -l actions-on-enter -d 'Actions to perform when pressing Enter' -r -f -a "save-to-clipboard\t''
save-to-file\t''
save-to-file-as\t''
copy-filepath-to-clipboard\t''
exit\t''"
complete -c satty -l actions-on-escape -d 'Actions to perform when pressing Escape' -r -f -a "save-to-clipboard\t''
save-to-file\t''
save-to-file-as\t''
copy-filepath-to-clipboard\t''
exit\t''"
complete -c satty -l actions-on-right-click -d 'Actions to perform when hitting the copy Button' -r -f -a "save-to-clipboard\t''
save-to-file\t''
save-to-file-as\t''
copy-filepath-to-clipboard\t''
exit\t''"
complete -c satty -l font-family -d 'Font family to use for text annotations' -r
complete -c satty -l font-style -d 'Font style to use for text annotations' -r
complete -c satty -l primary-highlighter -d 'The primary highlighter to use, secondary is accessible with CTRL' -r -f -a "block\t''
freehand\t''"
complete -c satty -l brush-smooth-history-size -d 'Experimental feature: How many points to use for the brush smoothing algorithm. 0 disables smoothing. The default value is 0 (disabled)' -r
complete -c satty -l zoom-factor -d 'Experimental feature (0.20.1): The zoom factor to use for the image. 1.0 means no zoom. defaults to 1.1' -r
complete -c satty -l pan-step-size -d 'Experimental feature (0.20.1): The pan step size to use when panning with arrow keys. defaults to 50.0' -r
complete -c satty -l text-move-length -d 'Experimental feature (0.20.1): The length to move the text when using the arrow keys. defaults to 50.0' -r
complete -c satty -l input-scale -d 'Experimental feature (0.20.1): Scale the default window size to fit different displays. Note that before 0.21.0 this is ignored with explicit resize' -r
complete -c satty -l title -d 'Experimental feature (0.21.0): Set window title' -r
complete -c satty -l app-id -d 'Experimental feature (0.21.0): Set toplevel app_id. Note that this has to match D-Bus well known name format, otherwise GTK does not accept it' -r
complete -c satty -l action-on-enter -d 'Action to perform when pressing Enter. Preferably use the `actions_on_enter` option instead' -r -f -a "save-to-clipboard\t''
save-to-file\t''
save-to-file-as\t''
copy-filepath-to-clipboard\t''
exit\t''"
complete -c satty -l man -d 'Show manpage. Pipe to man -l -'
complete -c satty -l license -d 'Show license'
complete -c satty -l floating-hack -d 'Try to enforce floating (0.20.1). Mileage may vary depending on compositor'
complete -c satty -l save-after-copy -d 'After copying the screenshot, save it to a file as well Preferably use the `action_on_copy` option instead'
complete -c satty -l auto-copy -d 'Automatically copy to clipboard after every annotation change (0.21.0)'
complete -c satty -s d -l default-hide-toolbars -d 'Hide toolbars by default'
complete -c satty -l focus-toggles-toolbars -d 'Experimental (since 0.20.0): Whether to toggle toolbars based on focus. Doesn\'t affect initial state'
complete -c satty -l default-fill-shapes -d 'Experimental feature (since 0.20.0): Fill shapes by default'
complete -c satty -l disable-notifications -d 'Disable notifications'
complete -c satty -l profile-startup -d 'Print profiling'
complete -c satty -l no-window-decoration -d 'Disable the window decoration (title bar, borders, etc.) Please note that the compositor has the final say in this. Requires xdg-decoration-unstable-v1'
complete -c satty -l right-click-copy -d 'Right click to copy. Preferably use the `action_on_right_click` option instead'
complete -c satty -s h -l help -d 'Print help'
complete -c satty -s V -l version -d 'Print version'
