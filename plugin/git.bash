# Git

if ! type git > /dev/null 2>&1; then
	return
fi

alias glog='git log --graph --oneline --all'

# __git_ps1 (branch in the fallback prompt, see prompt.bash) comes from
# git-prompt.sh, which only some systems load by themselves (Git Bash does);
# its location depends on the distribution
if ! declare -F __git_ps1 > /dev/null; then
	for __git_prompt in \
		/usr/lib/git-core/git-sh-prompt \
		/usr/share/git-core/contrib/completion/git-prompt.sh \
		/usr/share/git/completion/git-prompt.sh \
		/mingw64/share/git/completion/git-prompt.sh; do
		if [[ -r $__git_prompt ]]; then
			# shellcheck source=/dev/null
			. "$__git_prompt"
			break
		fi
	done
	unset __git_prompt
fi
