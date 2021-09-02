#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Color aliases
## old: alias ls='ls --color=auto'
alias ls="exa -l"
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'

# Other nice aliases
alias cp="cp -i"               # confirm before overwriting something
alias df='df -H'               # human-readable sizes
alias free='free -m'           # show sizes in MB
alias more=less
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias cat="bat"
alias nt='(alacritty --working-directory . &)'

# Add some paths to PATH
PATH=$PATH:$HOME/.cargo/bin:$HOME/.local/bin

# Standard PS1:
# PS1='[\u@\h \W]\$ '
# PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
# Custom PS1:
PS1='\[\033[01;35m\] \W \$\[\033[00m\] '

# Autocompletion
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

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
sh ~/.config/ufetch/ufetch-arch

source ~/.config/broot/launcher/bash/br
