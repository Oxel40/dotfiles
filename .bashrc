#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# If running inside of a container (distrobox), only load common
if [[ "$CONTAINER_ID" != "" ]]; then
	. "$HOME/.config/shell/common"
	return
fi

# Color aliases
## old: alias ls='ls --color=auto'
alias ls="exa -l"
alias lss="command ls"

# Other nice aliases
alias free='free -m'           # show sizes in MB
alias more=less
alias cat='bat'
alias nt='(alacritty --working-directory . &)'
alias fh='history_search'
alias nv='neovide --fork'

# Search in bash history
history_search()
{
	local c=$(history | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' | fzf)
	echo $c
	echo -n $c | xclip -selection c
}

# Exit ranger and cd to last dir with Q
ranger()
{
    local IFS=$'\t\n'
    local tempfile="$(mktemp -t tmp.XXXXXX)"
    local ranger_cmd=(
        command
        ranger
        --cmd="map Q chain shell echo %d > "$tempfile"; quitall"
    )
    
    ${ranger_cmd[@]} "$@"
    if [[ -f "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]]; then
        cd -- "$(cat "$tempfile")" || return
    fi
    command rm -f -- "$tempfile" 2>/dev/null
}


# Add some paths to PATH
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.fly/bin"
export PATH="$PATH:$HOME/.nix-profile/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:/opt/rocm/bin"

# Some exports
export FLYCTL_INSTALL="/home/erik/.fly"
# DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"

# Autocompletion
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
complete -cf doas

# Ufetch
# sh ~/.config/ufetch/ufetch-arch
# Pfetch

conda_init ()
{
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/erik/.miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/erik/.miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/erik/.miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/erik/.miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
# <<< conda initialize <<<
}

source /home/erik/.config/broot/launcher/bash/br

if [ -f "/home/erik/.ghcup/env" ]; then
	source "/home/erik/.ghcup/env" # ghcup-env
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/erik/Downloads/google-cloud-sdk/path.bash.inc' ]; then . '/home/erik/Downloads/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/erik/Downloads/google-cloud-sdk/completion.bash.inc' ]; then . '/home/erik/Downloads/google-cloud-sdk/completion.bash.inc'; fi
export PATH="$HOME/.npm-global/bin:$PATH"

. "$HOME/.config/shell/common"
