HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

PS1='\[\e[01;32m\]\u\[\e[00m\]@\[\e[01;34m\]bashland\[\e[00m\]:\[\e[01;36m\]\w\[\e[00m\]\$ '

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
fi
