# =============================================================================
# options.zsh — Zsh options (setopt / unsetopt)
# =============================================================================

# --- Directory navigation ---
setopt AUTO_CD              # Type directory name to cd into it
setopt AUTO_PUSHD           # Push directory onto stack on cd
setopt PUSHD_IGNORE_DUPS    # Don't push duplicates onto stack
setopt PUSHD_MINUS          # Swap + and - for directory stack

# --- Globbing ---
setopt EXTENDED_GLOB        # Enable advanced globbing (#, ~, ^)
unsetopt NOMATCH            # Don't error on unmatched globs (pass through)

# --- History ---
setopt EXTENDED_HISTORY     # Record timestamps
setopt HIST_IGNORE_DUPS     # Don't record duplicate commands
setopt HIST_IGNORE_SPACE    # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks
setopt HIST_VERIFY          # Show expanded command before running
setopt SHARE_HISTORY        # Share history across sessions

# --- Job control ---
setopt NOTIFY               # Report background job status immediately
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
