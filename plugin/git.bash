# Git

if ! type git > /dev/null 2>&1; then
	return
fi

alias glog='git log --graph --oneline --all'
