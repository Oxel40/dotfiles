#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Color aliases
## old: alias ls='ls --color=auto'
alias ls="exa -l"
alias lss="command ls"
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'

# Other nice aliases
alias cp="cp -i"               # confirm before overwriting something
alias df='df -H'               # human-readable sizes
alias free='free -m'           # show sizes in MB
alias more=less
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias cat='bat'
alias nt='(alacritty --working-directory . &)'
alias fh='history_search'
alias nv='neovide'

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
PATH="$PATH:$HOME/.cargo/bin"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$HOME/.fly/bin"
PATH="$PATH:$HOME/.nix-profile/bin"
PATH="$PATH:$HOME/go/bin"

# Some exports
FLYCTL_INSTALL="/home/erik/.fly"
DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"

# Standard PS1:
# PS1='[\u@\h \W]\$ '
# PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
# Custom PS1:
exitstatus()
{
	s=$?
    if [[ $s != 0 ]]; then
        echo "$s"
    fi
}
PS1='\[\033[01;31m\]$(exitstatus)\[\033[01;35m\] \W \$\[\033[00m\] '
PS2='\[\033[01;35m\]>\[\033[00m\] '

# Autocompletion
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
complete -cf doas

# Shortcut for file extraction
ex ()
{
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)   tar xjf $1   ;;
			*.tar.gz)    tar xzf $1   ;;
			*.bz2)       bunzip2 $1   ;;
			*.rar)       unrar x $1   ;;
			*.gz)        gunzip $1    ;;
			*.tar)       tar xf $1    ;;
			*.tbz2)      tar xjf $1   ;;
			*.tgz)       tar xzf $1   ;;
			*.zip)       unzip $1     ;;
			*.Z)         uncompress $1;;
			*.7z)        7z x $1      ;;
			*)           echo "'$1' cannot be extracted via ex()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# Ufetch
# sh ~/.config/ufetch/ufetch-arch
# Pfetch
echo ''
PF_INFO='ascii title os kernel uptime pkgs shell de' pfetch

conda_init ()
{
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
# <<< conda initialize <<<
}

source /home/erik/.config/broot/launcher/bash/br

if [ -f "/home/erik/.ghcup/env" ]; then
	source "/home/erik/.ghcup/env" # ghcup-env
fi
